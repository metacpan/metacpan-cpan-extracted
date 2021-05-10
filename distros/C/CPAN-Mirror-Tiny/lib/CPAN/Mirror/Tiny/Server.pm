package CPAN::Mirror::Tiny::Server;
use 5.008001;
use strict;
use warnings;

use CPAN::Mirror::Tiny;
use File::Copy ();
use File::Spec;
use Plack::App::Directory;
use Plack::Builder;
use Plack::Request;
use Plack::Runner;

sub uploader {
    my ($class, %args) = @_;
    my $base = $args{base} or die;
    my $tempdir = $args{tempdir} || File::Temp::tempdir(CLEANUP => 1);
    my $compress_index = 1;
    $compress_index = $args{compress_index} if exists $args{compress_index};

    my $cpan = CPAN::Mirror::Tiny->new(base => $base, tempdir => $tempdir);
    return sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        return [404, [], ['NOT FOUND']] if $req->path_info !~ m!\A/?\z!ms;

        if ($req->method eq 'POST') {
            eval {
                my ($module, $author);

                my $tempdir = $cpan->tempdir;
                if (my $upload = $req->upload('pause99_add_uri_httpupload')) {
                    # request from CPAN::Uploader
                    $module = File::Spec->catfile($tempdir->as_string, $upload->filename);
                    File::Copy::move $upload->tempname, $module;
                    $author = $req->param('HIDDENNAME');
                } else {
                    $module = $req->param('module'); # can be a git repo.
                    $author = $req->param('author') || 'VENDOR';
                }

                return [404, [], ['NOT FOUND']] if !$module && !$author;
                $author = uc $author;

                $cpan->inject($module, {author => $author});
                $cpan->write_index(compress => $compress_index);
            }; if (my $err = $@) {
                warn $err . '';
                return [500, [], [$err.'']];
            }
        } else {
            return [405, [], ['Method Not Allowed']];
        }

        return [200, [], ['OK']];
    }
}

sub start {
    my ($class, @argv) = @_;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@argv);
    if ($runner->{help}) {
        require Pod::Usage;
        Pod::Usage::pod2usage(0);
    }
    if ($runner->{version}) {
        my $c = "CPAN::Mirror::Tiny";
        printf "%s %s\n", $c, $c->VERSION;
        exit;
    }
    my $base = shift @{ $runner->{argv} || []} or die "Missing base directory\n";
    my $app = builder {
        mount "/upload" => $class->uploader(base => $base);
        mount "/" => Plack::App::Directory->new(root => $base)->to_app;
    };
    $runner->run($app);
}

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Mirror::Tiny::Server - HTTP Server for CPAN::Mirror::Tiny

=head1 SYNOPSIS

  $ cpan-mirror-tiny server

  # upload git managed module
  $ curl --data-urlencode 'module=git@github.com:Songmu/p5-App-RunCron.git' \
    --data-urlencode 'author=SONGMU' http://localhost:5000/upload
  $ curl --data-urlencode 'module=ssh://git@mygit/home/git/repos/MyModule.git' \
    --data-urlencode 'author=SONGMU' http://localhost:5000/upload

  # install by cpm
  $ cpm install --resolver 02packages,http://localhost:5000 --resolver metadb Your::Module

  # install by cpanm
  $ cpanm --mirror http://localhost:5000 --mirror http://www.cpan.org Your::Module

  # install by carton install
  PERL_CARTON_MIRROR=http://localhost:5000 carton install

=head1 DESCRIPTION

CPAN::Mirror::Tiny::Server is L<OrePAN2::Server> for CPAN::Mirror::Tiny.

=head1 LICENSE

Most of code is copied from L<OrePAN2::Server>. Its license is:

  Copyright (C) Hiroyuki Akabane.

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.

=cut

