package Catalyst::Plugin::EnableMiddleware;

use Moose::Role;
use namespace::autoclean;
use Plack::Util;
use Scalar::Util;
use Catalyst::Utils;
use Text::SimpleTable;

our $VERSION = '0.006';

around 'psgi_app', sub {
  my ($orig, $self, @args) = @_;
  my $psgi_app = $self->$orig(@args);

  return $psgi_app
    unless $self->config->{'Plugin::EnableMiddleware'};

  my $column_width = Catalyst::Utils::term_width() - 6;
  my $t = Text::SimpleTable->new($column_width);

  my @mw = reverse @{$self->config->{'Plugin::EnableMiddleware'}||[]};
  while(my $next = shift(@mw)) {
    if(Scalar::Util::blessed $next && $next->can('wrap')) {
      $t->row(ref $next);
      $psgi_app = $next->wrap($psgi_app);
    } elsif(my $type = ref $next) {
      if($type eq 'CODE') {
      $t->row('CodeRef');
        $psgi_app = $next->($psgi_app);
      } elsif($type eq 'HASH') {
        my $module = Plack::Util::load_class(shift @mw, 'Plack::Middleware');
       $t->row($module);
        $psgi_app = $module->wrap($psgi_app, %$next);
      }
    } else {
      my $normalized_next = Plack::Util::load_class($next, 'Plack::Middleware');
      $t->row($normalized_next);
      if($mw[0] and ref($mw[0]) and(ref $mw[0] eq 'HASH')) {
        my $args = shift @mw;
        $psgi_app = $normalized_next->wrap($psgi_app, %$args);
      } else {
        $psgi_app = $normalized_next->wrap($psgi_app);
      }
    }
  }
  if ($self->debug) {
    $self->log->debug( "Loaded Plack Middleware:\n" . $t->draw . "\n" );
  }
  return $psgi_app;
};

1;

=head1 NAME

Catalyst::Plugin::EnableMiddleware - Enable Plack Middleware via Configuration

=head1 SYNOPSIS

    package MyApp::Web;

    our $VERSION = '0.01';

    use Moose;
    use Catalyst qw/EnableMiddleware/;
    use Plack::Middleware::StackTrace;

    extends 'Catalyst';

    my $stacktrace_middleware = Plack::Middleware::StackTrace->new;

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', [
        'Debug',
        '+MyApp::Custom',
        $stacktrace_middleware,
        'Session' => {store => 'File'},
        sub {
          my $app = shift;
          return sub {
            my $env = shift;
            $env->{myapp.customkey} = 'helloworld';
            $app->($env);
          },
        },
      ],
    );

    __PACKAGE__->setup;
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Modern versions of L<Catalyst> use L<Plack> as the underlying engine to
connect your application to an http server.  This means that you can take
advantage of the full L<Plack> software ecosystem to grow your application
and to better componentize and re-use your code.

Middleware is a large part of this ecosystem.  L<Plack::Middleware> wraps your
PSGI application with additional functionality, such as adding Sessions ( as in
L<Plack::Middleware::Session>), Debugging (as in L<Plack::Middleware::Debug>)
and logging (as in L<Plack::Middleware::LogDispatch> or
L<Plack::Middleware::Log4Perl>).

Generally you can enable middleware in your C<psgi> file, as in the following
example

    #!/usr/bin/env plackup

    use strict;
    use warnings;

    use MyApp::Web;  ## Your subclass of 'Catalyst'
    use Plack::Builder;

    builder {

      enable 'Debug';
      enable 'Session', store => 'File';

      mount '/' => MyApp::Web->psgi_app;

    };

Here we are using our C<psgi> file and tools that come with L<Plack> in order
to enable L<Plack::Middleware::Debug> and L<Plack::Middleware::Session>.  This
is a nice, clean approach that cleanly separates your L<Catalyst> application
from enabled middleware.

However there may be cases when you'd rather enable middleware via you L<Catalyst>
application, rather in a stand alone file.  For example, you may wish to let your
L<Catalyst> application have control over the middleware configuration.

This plugin lets you enable L<Plack> middleware via configuration. For example,
the above mapping could be re-written as follows:

    package MyApp::Web;
    our $VERSION = '0.01';

    use Moose;
    use Catalyst qw/EnableMiddleware/;

    extends 'Catalyst';

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', [
        'Debug',
        'Session' => {store => 'File'},
      ]);

    __PACKAGE__->setup;
    __PACKAGE__->meta->make_immutable;

Then your C<myapp_web.psgi> would simply become:

    #!/usr/bin/env plackup

    use strict;
    use warnings;

    use MyApp::Web;  ## Your subclass of 'Catalyst'
    MyApp::Web->psgi_app;

You can of course use a configuration file and format (like Config::General)
instead of hard coding your configuration into the main application class.
This would allow you the ability to configure things differently in different
environments (one of the key reasons to take this approach).

The approach isn't 'either/or' and merits to each are apparent.  Choosing one
doesn't preclude the other.

=head1 CONFIGURATION

Configuration for this plugin should be a ArrayRef under the top level key
C<Plugin::EnableMiddleware>, as in the following:

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', \@middleware);

Where C<@middleware> is one or more of the following, applied in the REVERSE of
the order listed (to make it function similarly to L<Plack::Builder>:

=over4

=item Middleware Object

An already initialized object that conforms to the L<Plack::Middleware>
specification:

    my $stacktrace_middleware = Plack::Middleware::StackTrace->new;

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', [
        $stacktrace_middleware,
      ]);


=item coderef

A coderef that is an inlined middleware:

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', [
        sub {
          my $app = shift;
          return sub {
            my $env = shift;
            if($env->{PATH_INFO} =~m/forced/) {
              Plack::App::File
                ->new(file=>TestApp->path_to(qw/share static forced.txt/))
                ->call($env);
            } else {
              return $app->($env);
            }
         },
      },
    ]);



=item a scalar

We assume the scalar refers to a namespace after normalizing it in the same way
that L<Plack::Builder> does (it assumes we want something under the
'Plack::Middleware' unless prefixed with a C<+>).

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', [
        'Debug',  ## 'Plack::Middleware::Debug->wrap(...)'
        '+MyApp::Custom',  ## 'MyApp::Custom->wrap(...)'
      ],
    );

=item a scalar followed by a hashref

Just like the previous, except the following C<HashRef> is used as arguments
to initialize the middleware object.

    __PACKAGE__->config(
      'Plugin::EnableMiddleware', [
         'Session' => {store => 'File'},
    ]);

=cut

=head1 VERSION NOTES

Versions prior to C<0.006> applied middleware in the order lists.  This led to
unexpected problems when porting over middleware from L<Plack::Builder> since
that applies middleware in reverse order.  This change makes this plugin behave
as you might expect.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>, L<Catalyst>

=head1 COPYRIGHT & LICENSE

Copyright 2012, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

