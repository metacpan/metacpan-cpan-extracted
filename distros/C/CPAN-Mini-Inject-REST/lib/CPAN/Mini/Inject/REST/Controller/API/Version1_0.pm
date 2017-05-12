package CPAN::Mini::Inject::REST::Controller::API::Version1_0;

use 5.010;
use Moose;
use Archive::Extract;
use File::Basename qw/basename/;
use File::Copy;
use File::Find::Rule;
use File::Spec::Functions qw/catdir catfile splitpath/;
use File::Temp;
use List::MoreUtils qw/uniq/;
use Parse::CPAN::Meta;
use Try::Tiny;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    namespace => 'api/1.0',
    default   => 'application/json',
);

=head1 NAME

CPAN::Mini::Inject::REST::Controller::API::Version1_0

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 repository

/api/1.0/repository/File-Name-1.00.tar.gz

=cut

sub repository :Local :Args(1) :ActionClass('REST') {}

=head3 GET

Downloads a file from the repository. Returns status 404 if the file could
not be found.

=cut

sub repository_GET {
    my ($self, $c, $file) = @_;
    
    my $path = catfile($c->model('CMI')->config->get('repository'), 'authors/id/L/LO/LOCAL', $file);
    if (-e $path) {
        $c->serve_static_file($path);
    } else {
        $self->status_not_found(
            $c,
            message => "Cannot find $file in repository"
        );
    }
}

=head3 POST

Adds a file to the repository and injects it into the mirror. If the file can be
added, status 201 (Created) is returned with details of which modules the file
provides.

    {
        "provides": [
            {
                "version": "0.04",
                "module": "hello"
            }
        ],
        "file": "hello-0.04.tar.gz"
    }

If the file cannot be added to the repository, status 400 is returned with an
appropriate error message:

    {
        "error": "File hello-0.03.tar.gz is already in the repository"
    }

Note that if a file already exists in the repository, it cannot be added again.

=cut

sub repository_POST {
    my ($self, $c, $file) = @_;
    
    # Check to see if the file already exists in the repository
    unless (-e catfile($c->model('CMI')->config->get('repository'), 'authors/id/L/LO/LOCAL', $file)) {
        if ($c->req->upload('file')->filename =~ /([^\/]*)-([0-9._]+)\.tar\.gz$/) {
            my $module = $1;
            my $version = $2;
            $module =~ s/-/::/g;
            
            my $ftmp    = File::Temp->new();
            my $tmpdir  = $ftmp->newdir();
            my $newfile = $tmpdir. "/" . $c->req->upload('file')->filename;
            copy($c->req->upload('file')->tempname, $newfile);

            $c->model('CMI')->readlist;            
            $c->model('CMI')->add(
                module   => $module,
                version  => $version,
                authorid => 'LOCAL',
                file     => $newfile,
            );
            
            my @provides;
            push @provides, {module => $module, version => $version};
            
            # Add all modules listed in META.json / META.yml
            if (my $meta = _load_meta($newfile)) {
                while (my ($module, $details) = each %{$meta->{provides}}) {
                    $c->model('CMI')->add(
                        module   => $module,
                        version  => $details->{version} // 'undef',
                        authorid => 'LOCAL',
                        file     => $newfile,
                    );
                    push @provides, {module => $module, version => $details->{version} // 'undef'};
                }
            }
            
            $c->model('CMI')->writelist;
            $c->model('CMI')->inject;
            
            $self->status_created(
                $c,
                location => $c->uri_for($self->action_for('mirror'), $file),
                entity   => {
                    file     => $c->req->upload('file')->filename,
                    provides => \@provides,
                }
            );
        }
    } else {
        $self->status_bad_request(
            $c,
            message => "File $file is already in the repository",
        );
    }
}


=head2 mirror

/api/1.0/mirror/File-Name-1.0.tar.gz

=cut

sub mirror :Local :Args(1) :ActionClass('REST') {}

=head3 GET

Returns a list of modules provided by the file, and the CPAN-style path to
download the file from the mirror (e.g. F<L/LO/LOCAL/File-Name-1.0.tar.gz>).

    {
        "provides": {
            "CPAN::Mini::Inject::Config": {
                "version":"0.28"
            },
            "CPAN::Mini::Inject": {
                "version":"0.28"
            }
        },
        "file": "CPAN-Mini-Inject-0.28.tar.gz",
        "path": "L/LO/LOCAL/CPAN-Mini-Inject-0.28.tar.gz"
    }

If the file has not been added to the mirror, status 404 is returned with an
appropriate error message:

    {
        "error": "File My-Module-1.04.tar.gz does not exist"
    }

=cut

sub mirror_GET {
    my ($self, $c, $file) = @_;
    
    $c->model('CMI')->readlist;
    if ($c->model('CMI')->{modulelist} && (my @modules = grep {m!L/LO/LOCAL/$file!} @{$c->model('CMI')->{modulelist}})) {
        my %response = (
            file => $file,
            path => "L/LO/LOCAL/$file",
        );
        
        foreach (@modules) {
            my ($name, $version, $file) = split;
            $response{provides}{$name}{version} = $version;
        }
        
        $self->status_ok(
            $c,
            entity => \%response
        );
    } else {
        $self->status_not_found(
            $c,
            message => "File $file does not exist",
        );
    }
}


=head2 all_files

=cut

sub all_files :Local :Args(0) :ActionClass('REST') {}

=head3 GET

Returns a list of all files that have been added to the mirror.

    {
        "files": [
            "CPAN-Mini-Inject-0.28.tar.gz",
            "My-Private-Module-0.02.tar.gz"
        ]
    }

If no files have been added, status 204 (No Content) is returned.

=cut

sub all_files_GET {
    my ($self, $c) = @_;
    
    try {
        $c->model('CMI')->readlist;
    } catch {
        $c->log->debug("Could not read the modulelist: $_");
        $self->status_no_content;
        $c->detach;
    };
    
    if ($c->model('CMI')->{modulelist}) {
        $c->log->debug('Got it');
        my @files = map {m!L/LO/LOCAL/(.*)! && $1}
                    grep {m!L/LO/LOCAL/!} @{$c->model('CMI')->{modulelist}};
        @files = uniq @files;
        @files = sort @files;
        
        $self->status_ok(
            $c,
            entity => {
                files => \@files
            }
        );
    } else {
        $c->log->debug('No modulelist there');
        $self->status_no_content($c);
    }
}


=head2 dist

/api/1.0/dist/Distribution-Name

=cut

sub dist :Local :Args(1) :ActionClass('REST') {}

=head3 GET

Returns a list of files, from both the repository and the mirror, which match
the specified distibution name.

    {
        "repository": [
            "hello-0.01.tar.gz",
            "hello-0.02.tar.gz",
            "hello-0.03.tar.gz"
        ],
        "mirror": [
            "hello-0.02.tar.gz"
        ]
    }

If the distribution cannot be found, status 404 is returned with an appropriate
error message:

    {
        "error": "Cannot find dist My-Private-Module"
    }

=cut

sub dist_GET {
    my ($self, $c, $dist) = @_;

    $c->model('CMI')->readlist;
    if ($c->model('CMI')->{modulelist}) {
        if (my @mirror_files = map {m!L/LO/LOCAL/(.*)! && $1}
                        grep {m!L/LO/LOCAL/$dist-[0-9._]+(\.tar|tar\.gz|tgz|zip)!} @{$c->model('CMI')->{modulelist}}) {
            @mirror_files = uniq @mirror_files;
            @mirror_files = sort @mirror_files;
            
            my $repository_dir   = catdir($c->model('CMI')->config->get('repository'), 'authors/id/L/LO/LOCAL');
            my @repository_files = map {basename($_)} File::Find::Rule->file->name(qr/$dist-[0-9._]+(\.tar|tar\.gz|tgz|zip)/)->in($repository_dir);
            
            $self->status_ok(
                $c,
                entity => {
                    repository => \@repository_files,
                    mirror     => \@mirror_files
                }
            );
            
            $c->detach;
        }
    }
    
    $self->status_not_found(
        $c,
        message => "Cannot find dist $dist"
    );
}


=head2 all_dists

/api/1.0/all_dists

=cut

sub all_dists :Local :Args(0) :ActionClass('REST') {}

=head3 GET

Returns a list of all distributions that have been added to the mirror.

    {
        "dists": [
            "CPAN-Mini-Inject",
            "My-Private-Module"
        ]
    }

If no distributions have been added, status 204 (No Content) is returned.

=cut

sub all_dists_GET {
    my ($self, $c) = @_;
    
    try {
        $c->model('CMI')->readlist;
    } catch {
        $c->log->debug("Could not read the modulelist: $_");
        $self->status_no_content;
        $c->detach;
    };
    
    if ($c->model('CMI')->{modulelist}) {
        my @dists = map {m!L/LO/LOCAL/(.*)-[0-9._]+\.tar|tar\.gz|tgz|zip! && $1}
                    grep {m!L/LO/LOCAL/!} @{$c->model('CMI')->{modulelist}};
        @dists = uniq @dists;
        @dists = sort @dists;
        
        $self->status_ok(
            $c,
            entity => {
                dists => \@dists
            }
        );
    } else {
        $c->log->debug('Nothing in the modulelist');
        $self->status_no_content($c);
    }
}


#-------------------------------------------------------------------------------

sub _load_meta {
    my $filename = shift;
    my ($vol, $dir, $file) = splitpath($filename);
    my $archive = Archive::Extract->new(archive => $filename);
    $archive->extract(to => "$vol/$dir");
    
    if (my @meta = File::Find::Rule->file->name('META.json')->in("$vol/$dir")) {
        return Parse::CPAN::Meta->load_file(shift @meta);
    }

    if (my @meta = File::Find::Rule->file->name('META.yml')->in("$vol/$dir")) {
        return Parse::CPAN::Meta->load_file(shift @meta);
    }
}


#-------------------------------------------------------------------------------

=head1 AUTHOR

Jon Allen (JJ) <jj@jonallen.info>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
