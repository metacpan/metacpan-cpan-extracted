package AnnoCPAN::Dist;

use strict;
use warnings;
use 5.006;
use List::Util qw(first);
use AnnoCPAN::Archive;
use AnnoCPAN::DBI;
use AnnoCPAN::PodParser;
use IO::String;
use Digest::MD5 qw(md5_hex);
use File::stat ();
use base qw(CPAN::DistnameInfo Exporter);
use overload '""' => 'distvname';
use constant {
    DIST_ADDED          => 0,
    DIST_OLD            => 1,
    DIST_NO_ARCHIVE     => 2,
    DIST_UGLY_PACKAGE   => 3,
    DIST_STORE_ERR      => 4,
};

our $VERSION = '0.22';
our @EXPORT_OK = qw(
    DIST_ADDED 
    DIST_OLD 
    DIST_NO_ARCHIVE 
    DIST_UGLY_PACKAGE 
    DIST_STORE_ERR
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


=head1 NAME

AnnoCPAN::Dist - CPAN distribution extracting and munging

=head1 SYNOPSIS

    use AnnoCPAN::Dist;
    my $dist = AnnoCPAN::Dist->new('/path/to/Dist-0.01.tar.gz')
        or die "$@";
    $dist->extract;

=head1 DESCRIPTION

AnnoCPAN has to understand CPAN distribution packages, find all the relevant
documentation they contain, and figure out the versions and the correct
pathname for each document. This is not a trivial task given the inconsistent
ways in which CPAN distributions are packaged; there are several specific cases
to consider. Note that this module does not aim at 100.00% coverage (but at
least 99%, I hope); if a package does not comply with any of the standards
that this package understands, it will be silently excluded. One can only hope
the authors of the excluded package will some day decide to package their
modules in more standard ways.

This module claims to understand the following types of packages:

=over

=item *

Files in the .zip and .tar.gz file formats.

=item *

Packages where all the modules are in the lib/ subdirectory.

=item *

Packages bundled with Module::Install, where the inc/ directory should be
ignored.

=item *

"Old-style" packages, where the modules are in the top directory, with
sub-namespaces in subdirectories.

=back

Files that appear to be PPM packages are ignored.

This class inherits from CPAN::DistnameInfo, and relies on it for parsing
the filename and figuring out things such as the version number.

The version numbers are derived from the package filename only, and are
expected to be floating-point numbers. The $VERSION values inside the module
code are considered irrelevant for the purpose of this project.

=head1 METHODS

=over

=cut

# default files to ignore
my @exclude = (
    qr(/inc/),      # used by Module::Install bundles
    qr(/t/),
    qr(/eg/),
    qr(/blib/),
    qr(/Makefile(.PL)?$),
    qr(/Build.PL$),
    qr(/MANIFEST$)i,
    qr(/README$)i,
    qr(/Changes$)i,
    qr(/ChangeLog$)i,
    qr(/LICENSE$)i,
    qr(/TODO$)i,
    qr(/AUTHORS?$)i,
);

# default files to include
my @include = (
    qr{.(pm|pod|pl)$}i,
    qr{/[^./]+$},       # files with no extension (typically scripts)
);

=item $class->new($fname, %options)

Create a new distribution object from a filename. Returns undef on failure.
Currently the only option is 'verbose'; if true, various diagnostic messages
are printed to STDOUT and STDERR when extracting the file.

=cut

sub new {
    my ($class, $fname, %options) = @_;
    
    return unless $fname =~ m{(authors/id/.*)};
    my $rel_pathname = $1;
    # let CPAN::DistnameInfo do the guessing
    my $self = $class->SUPER::new($fname);
    $self->{verbose}        = $options{verbose};
    $self->{rel_pathname}   = $rel_pathname;

    # XXX should make sure we like the filename...

    $self;
}

=item $obj->archive

Return the AnnoCPAN::Archive object for this distribution.

=cut

sub archive { 
    my ($self) = @_;
    $self->{archive} ||= AnnoCPAN::Archive->new($self->pathname);
}

=item $obj->mtime

Returns the modification time of the package (seconds since epoch).

=cut

sub mtime { shift->stat->mtime }

=item $obj->stat

Returns a L<File::stat> object for the distribution package.

=cut

sub stat {
    my ($self) = @_;
    $self->{stat} ||= File::stat::stat($self->pathname);
}

sub dbi_dist    { shift->{dbi_dist} }
sub dbi_distver { shift->{dbi_distver} }

=item $obj->files

Returns a list of all the filenames in the package.

=cut

sub files       { shift->archive->files }

=item $obj->read_file($fname)

Returns the contents of a file in the package.

=cut

sub read_file   { shift->archive->read_file(@_) }

=item $obj->verbose

Returns true if the verbose option was given when constructing the object.

=cut

sub verbose     { shift->{verbose} }

=item $obj->rel_pathname

Returns the pathname relative to the CPAN root (e.g.,
authors/id/A/AA/AAA/aaa-1.0.tar.gz)

=cut

sub rel_pathname{ shift->{rel_pathname} }

=item $obj->has_lib

Return true if the distribution has a lib/ directory.

=cut

sub has_lib {
    my ($self) = @_;
    defined $self->{has_lib} and return $self->{has_lib};
    $self->{has_lib} = (first { m|^(?:\./)?[^/]+/lib/| } $self->files) ? 1 : 0;
}

=item $obj->namespace_from_path($fname)

Given the path of one of the files in the archive, use heuristics to find out
its path in the perl module hierarchy. For example, given
"Dist-0.01/lib/My/Module.pm", returns "My/Module.pm".

=cut

sub namespace_from_path {
    my ($dist, $name) = @_;
    $name =~ s/^\.\///;
    my $ret;
    if ($dist->has_lib) { # modern style
        if ($name =~ s|.*/lib/||) {
            # usual module in lib directory
            $ret = $name;
        } elsif ($name =~ s|.*/ext/||) {
            # XS modules in perl distribution, which sometimes use the
            # old-fashioned style
            my @path = split '/', $name;
            splice @path, -2, 1 if @path > 1; # get rid of last dir level
            $ret = join '/', @path;
        } elsif ($name =~ s|.*/||) {
            # we'll assume that pods not in the lib directory
            # are in the root namespace. This might include e.g.
            # scripts in bin/, stuff in the top directory, or other
            # stuff like examples, etc.
            $ret = $name;
        } else {
            die "shouldn't be here! namespace_from_path(name='$name')";
        }
    } else { # old style
        my $distname = $dist->dist;
        my $distdir  = $dist->distvname;
        # keep only the "prefix" (up to the last hyphen)
        my ($pref) = $distname =~ /(?:(.*)-)?/;
        $pref =~ s|-|/|g if defined $pref;
        if ($name =~ s|.*/bin/||) {
            # let's assume that bins are in top namespace
            $ret = $name;
        } elsif ($name =~ /^$distdir\/(.+)$/) {
            # add the prefix, if any
            $ret = $pref ? "$pref/$1" : $1;
        } else {
            die "shouldn't be here! namespace_from_path"
                . "(name='$name', distvname='$distdir')";
        }
    }
    $ret =~ s/\.\w+$//;
    $ret =~ s|/|::|g;
    $ret;
}

sub namespace_from_pod {
    my ($self, $name) = @_;
}

sub exclude { @exclude }
sub include { @include }

sub want {
    my ($self, $file) = @_;
    return 0 unless first { $file =~ /$_/ } $self->include; 
    return 0 if     first { $file =~ /$_/ } $self->exclude; 
    return 1;
}

=item $obj->extract

Open the archive, extract the pod, and load it into the database.
Returns true on success, false on failure. 

The same distribution file will not be loaded twice; in that case, 
returns true without doing anything.

=cut

sub extract { 
    my ($self) = @_;
    my $dist = $self;
    my $fname = $self->filename;
    my $rel_fname = $self->rel_pathname;

    # make sure this distver is not there already
    my $distver = AnnoCPAN::DBI::DistVer->retrieve(path => $rel_fname);
    return ($distver, DIST_OLD) if $distver;
    my $status;

    AnnoCPAN::DBI->reset_dbh;
    unless (fork) {
        # child process; extract the distribution

        # open package
        $self->archive or exit DIST_NO_ARCHIVE;
        my @files = $self->archive->files;

        # check if it's packaged nicely
        my ($dir) = $files[0] =~ m|^([^/]+)|;
        unless ($dir) {
            warn "package $fname file[0] ($files[0]) not relative\n" 
                if $self->verbose;
            exit DIST_UGLY_PACKAGE;
        }
        if ($dir =~ /^blib\//) {
            warn "package $fname appears to be a ppm package; skipping\n" 
                if $self->verbose;
            exit DIST_UGLY_PACKAGE;
        }
        my $re = qr/^\Q$dir\E(?:\/|$)/;
        if (first { ! /$re/  } @files) {
            warn "package $fname does not unwrap to a single directory/\n" 
                if $self->verbose;
            exit DIST_UGLY_PACKAGE;
        }
        printf "\t$rel_fname\t%d files\n", scalar @files 
            if $self->verbose;

        # load distver into the database
        $distver = $self->store_distver or exit DIST_STORE_ERR;

        # load individual podvers
        for my $file ($dist->files) {
            # check if we want this file
            next unless $self->want($file);
            my $code = $dist->read_file($file) or next;
            # XXX check if the file appears to have POD
            $code =~ /(?:^|[\r\n])=head/ or next;

            # load it into the database
            $self->store_podver($file, $code);
        }
        exit DIST_ADDED; # end child process
    } else {
        if (wait > 0) { # only run one child at a time
            $status = $?;
        } else {
            warn "Lost a child while processing '$rel_fname'!\n";
        }
    }
    # XXX this is not very efficient, the child already had it
    $distver = AnnoCPAN::DBI::DistVer->retrieve(path => $rel_fname);
    return ($distver, $status);
}


sub filter_pod {
    my ($self, $code, $podver) = @_;
    my $fh_in = IO::String->new($code);
    my $parser =  AnnoCPAN::PodParser->new(
        ac_podver  => $podver,
        ac_pos     => 0,
        ac_verbose => $self->verbose,
    );
    $parser->parse_from_filehandle($fh_in);
}


=item $obj->store_podver($path, $pod)

Store a pod.

=cut

sub store_podver {
    my ($self, $file, $code) = @_;

    print "\t\t$file" if $self->verbose;
    my $path = $file;
    $path =~ s|^.*?/||;

    my $signature = $self->compute_signature($code);

    # create podver
    my $podver = AnnoCPAN::DBI::PodVer->create({
        distver     => $self->dbi_distver,
        path        => $path,
        signature   => $signature,
    });

    # parse pod
    my $fh_in = IO::String->new($code);
    my $parser =  AnnoCPAN::PodParser->new(
        ac_podver  => $podver,
        ac_pos     => 0,
        ac_verbose => $self->verbose,
    );
    $parser->parse_from_filehandle($fh_in);

    # figure out name
    my $path_name = $self->namespace_from_path($file) or next;
    my ($pod_name, $pod_desc) = $parser->ac_metadata;

    my $name = $pod_name || $path_name;
    print "\t$name\n" if $self->verbose;
    warn "Pod name and pathname don't match ($pod_name, $path_name)\n" 
        if $self->verbose && $pod_name && $pod_name ne $path_name;
    
    my ($pod) = AnnoCPAN::DBI::Pod->search_pod_dist($name, $self->dbi_dist);
    unless ($pod) {
        $pod = AnnoCPAN::DBI::Pod->create({name => $name});
        AnnoCPAN::DBI::PodDist->create({pod => $pod, dist => $self->dbi_dist});
    }
    $podver->pod($pod);
    $podver->description($pod_desc);
    $podver->update;

}

sub compute_signature {
    my ($self, $s) = @_;
    return md5_hex($s);
}

=item $obj->store_distver

Add a record to the database (using AnnoCPAN::DBI::Dist). Returns the new
object if it was created successfully.

=cut

sub store_distver {
    my ($self) = @_;

    # get or create dist
    my $dist = $self->{dbi_dist} = 
        AnnoCPAN::DBI::Dist->retrieve(name => $self->dist)
        || AnnoCPAN::DBI::Dist->create({name => $self->dist});

    # create distver
    my $distver = $self->{dbi_distver} = AnnoCPAN::DBI::DistVer->create({
        dist        => $dist,
        pause_id    => $self->cpanid,
        version     => $self->version,
        path        => $self->rel_pathname,
        distver     => $self->distvname,
        mtime       => $self->mtime,
        maturity    => $self->maturity eq 'released' ? 1 : 0,
    });

    unless ($dist->creation_time) {
        $dist->creation_time($self->mtime);
        $dist->update;
    }

    return $distver;
}

=back

=head1 SEE ALSO

L<AnnoCPAN::DBI>, L<AnnoCPAN::Update>, L<CPAN::DistnameInfo>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;


