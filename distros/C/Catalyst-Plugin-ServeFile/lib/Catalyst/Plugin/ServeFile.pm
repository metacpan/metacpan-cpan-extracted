package Catalyst::Plugin::ServeFile;

use Moo::Role;
use Plack::Util ();
use Plack::MIME ();
use HTTP::Date ();
use File::Spec ();
use Cwd ();

our $VERSION = '0.003';

sub serve_file {
  my $c = shift;
  my $options = ref($_[-1]) ? pop @_ : +{};
  my $config = $c->config->{'Plugin::Static::Simple'} || +{};
  my %settings = (%$config, %$options);

  $c->log->abort(1) unless $settings{show_log};

  my $file_proto = File::Spec->catdir(
    File::Spec->no_upwards(
      map { File::Spec->splitdir($_) } @_ ));
  my $full_path = $c->config->{root}->file($file_proto);

  return undef unless -f $full_path;

  $c->log->debug("Serving Static File: $full_path") if $c->debug;

  my $content_type = Plack::MIME->mime_type($full_path) || 'application/octet';

  if(my $allowed_content_types = $settings{allowed_content_types}) {
    return undef unless scalar( grep { lc($content_type) eq lc($_) } @$allowed_content_types);
  }

  if ($content_type =~ m!^text/!) {
    my $encoding =  $settings{encoding} || "utf-8";
    $content_type .= "; charset=$encoding";
  }

  my $fh = $full_path->openr;
  my $stat = $full_path->stat;

  Plack::Util::set_io_path($fh, Cwd::realpath($full_path)); # Support Xsendfile

  my $status = $settings{status} || $settings{code} || 200;
  $c->res->status($status);
  $c->res->headers->header(
    'Content-Type'   => $content_type,
    'Content-Length' => $stat->[7],
    'Last-Modified'  => HTTP::Date::time2str( $stat->[9] ),
    'Cache-control' => 'public');
  $c->res->body($fh);

  return $fh;
}

1;

=head1 NAME

Catalyst::Plugin::ServeFile - A less opinionated, minimal featured way to serve static files.

=head1 SYNOPSIS

    package MyApp;
    use Catalyst 'ServeFile';

    MyApp->setup;

    package MyApp::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    # Serves => https://localhost/license
    sub license :Path(license) Args(0) {
      my ($self, $c) = @_;
      $c->serve_file("license.txt");
    }

    # Servers => https://localhost/static/...
    sub static :Path(static) Args {
      my ($self, $c, @args) = @_;
      $c->serve_file('static',@args) || do {
        $c->res->status(404);
        $c->res->body('Not Found!');
      };
    }

=head1 DESCRIPTION

L<Catalyst::Plugin::Static::Simple> is venerable but I find it has too many default
opinions.  I generally only use it for the simple job of when I have a single static file
or so that lives behind authentication that I want to serve.  For that simple job
L<Catalyst::Plugin::Static::Simple> does provide a method 'serve_static_file', but there's
two problems with it.  First, the plugin out of the box will attempt to serve all files 
requested at the '/static/...' path.  If you don't want that its configuration effort.
Also, it doesn't currently support L<Plack::Middleware::XSendfile> (Although I want to
point out adding such support would be trivial, and I would be happy to help if needed).

Even when I want the automatic serving of files under '/static' I find the old plugin
has some opinions that don't work with my expectations (for example it by default doesn't
serve *.html files).  These assumptions probably made sense in 2006 but I prefer something
with less default opinions.  So this is a plugin that just does a simple one thing.  It
gives you a method 'serve_file' which tries to safely serve a static file located in 
'$c->config->{root}', with support for L<Plack::Middleware::XSendfile>.  It does basic
sanity / safety checking such as not allowing you to have a path with '..' for example.
And that's it.  It does automatically serve up all files under 'static', or anything.  If
you want that, use the old plugin, or write a trivial action that does it (example below).

=head1 METHODS

This plugin adds the following methods to your L<Catalyst> application.

=head2 serve_file (@path_parts, ?\%options?)

Will serve a static file using '$c->config->{root}' as the path prefix.  For example
if you have a file '$c->config->{root}/static/license/html' you can serve it with
$c->serve_file('static','license.html').

This method will return true (the $fh actually) if it is successful in locating and serving
a file.  False otherwise.  It doesn't automatically set any 'not found' response, you need to
handle that yourself.

If the last argument is a HashRef, we will use it as an overlay on any configuration options.

See the L<\SYNOPSIS> for a longer example.

=head1 CONFIGURATION

This plugin supports the following configuration.  You may set configuration globally
via the 'Plugin::ServeFile' configuration key, and you may set/override when making
the request.  For example:

    package MyApp;
    use Catalyst 'ServeFile';

    myApp->config(
      'Plugin::ServeFile' => {
        show_log => 1,
      }
    );
    MyApp->setup;

   package MyApp::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub license :Path(license) Args(0) {
      my ($self, $c) = @_;
      $c->serve_file("license.txt", +{ show_log=>1});
    }

=head2 show_log

By default we supress detailed logging of the request.  This is the same behavior as
L<Catalyst::Plugin::Static::Simple>.  If you want to see those logs, you can enable it
by setting this to true.

=head2 allowed_content_types

By default we allow you to serve any file.  This may be dangerous if you are building
your path arguments dynamically from uncontrolled sources.  In that case you can set
this to an arrayref of allowed mime types ('text/html', 'application/javascript', etc.).

=head2 status

=head2 code

Allows you to control the HTTP status code returned by the response.  Probably more
useful in the controller rather than in config:

    $c->serve_file(@args) || $c->serve_file('not_found', {code=>404});

Both 'status' and 'code' are allowed.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Catalyst>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 
=cut
