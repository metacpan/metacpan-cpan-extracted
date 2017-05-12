package Catalyst::View::Jemplate;

use strict;
our $VERSION = '0.06';

use base qw( Catalyst::View );
use File::Find::Rule;
use Jemplate;
use NEXT;
use Path::Class;

__PACKAGE__->mk_accessors(qw( jemplate_dir jemplate_ext encoding ));

sub new {
    my($class, $c, $arguments) = @_;
    my $self = $class->NEXT::new($c);

    $self->jemplate_dir($arguments->{jemplate_dir});
    $self->jemplate_ext($arguments->{jemplate_ext} || '.tt');
    $self->encoding($arguments->{encoding} || 'utf-8');

    my $dir = $self->jemplate_dir
        or Catalyst::Exception->throw("jemplate_dir needed");

    unless (-e $dir && -d _) {
        Catalyst::Exception->throw("$dir: $!");
    }

    $self;
}

sub process {
    my($self, $c) = @_;

    my $data   = $c->stash->{jemplate};
    my $cache  = $c->can('curry_cache') ? $c->cache("jemplate")
               : $c->can('cache')       ? $c->cache
               :                          undef;
    my $output = '';

    my $cache_key = $data->{key} || $c->req->match;
    if ($cache) {
        $output = $cache->get($cache_key);
        if ($c->log->is_debug) {
            if ($output) {
                $c->log->debug("Catalyst::View::Jemplate cache HIT for $cache_key");
            } else {
                $c->log->debug("Catalyst::View::Jemplate cache MISS for $cache_key");
            }
        }
    }

    if (! $output) {
        # We aren't cached, or we don't have a cache configured for us
        my @files;

        if ($data && $data->{files}) {
            # The user can specify exactly which files we include in this
            # particular dispatch
            @files = 
                map { file($self->jemplate_dir, $_) }
                ref($data->{files}) ? @{ $data->{files} } : ($data->{files})
            ;
        } else {
            # XXX - not a good idea, but leave it as final alternative
            @files = File::Find::Rule->file
                                     ->name( '*' . $self->jemplate_ext )
                                     ->in( $self->jemplate_dir );
        }

        if ($c->log->is_debug) {
            $c->log->debug("Creating Jemplate file from @files");
        }

        # add runtime
        if ($data && $data->{runtime}) {
            $output = Jemplate->runtime_source_code();
        }

        # xxx error handling?
        $output .= Jemplate->compile_template_files(@files);
        if ($cache) {
            $cache->set($cache_key, $output);
        }
    }

    my $encoding = $self->encoding || 'utf-8';
    if (($c->req->user_agent || '') =~ /Opera/) {
        $c->res->content_type("application/x-javascript; charset=$encoding");
    } else {
        $c->res->content_type("text/javascript; charset=$encoding");
    }

    $c->res->output($output || '');
}

1;
__END__

=head1 NAME

Catalyst::View::Jemplate - Jemplate files server

=head1 SYNOPSIS

  package MyApp::View::Jemplate;
  use base qw( Catalyst::View::Jemplate );

  package MyApp;

  MyApp->config(
      'View::Jemplate' => {
          jemplate_dir => MyApp->path_to('root', 'jemplate'),
          jemplate_ext => '.tt',
      },
  );

  sub jemplate : Global {
      my($self, $c) = @_;
      $c->forward('View::Jemplate');
  }

  # To specify which files you want to include
  sub select : Global {
      my($self, $c) = @_;
      $c->stash->{jemplate} = {
          files => [ 'foo.tt', 'bar.tt' ]
      }
  }

  # To serve Jemplate rutime
  sub runtime : Path('Jemplate.js') {
      my($self, $c) = @_;
      $c->stash->{jemplate} = {
          runtime => 1,
          files   => [],  # runtime only
      }
  }

  # To use caching
  use Catalyst qw(
      ...
      Cache
  );

  MyApp->config(
      cache => {
          backends => {
              jemplate => {
                  # Your cache backend of choice
                  store => "FastMmap",
              }
          }
      }
  );

=head1 DESCRIPTION

Catalyst::View::Jemplate is a Catalyst View plugin to automatically
compile TT files into JavaScript, using ingy's Jemplate.

Instead of creating the compiled javascript files by-hand, you can
include the file via Catalyst app like:

  <script src="js/Jemplate.js" type="text/javascript"></script>
  <script src="/jemplate/all.js" type="text/javascript"></script>

When L<Catalyst::Plugin::Cache> is enabled, this plugin make uses of
it to cache the compiled output and serve files.

=head1 TODO

=over 4

=item *

Right now all the template files under C<jemplate_dir> is compiled
into a single JavaScript file and served. Probably we need a path
option to limit the directory.

=cut

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<>

=cut
