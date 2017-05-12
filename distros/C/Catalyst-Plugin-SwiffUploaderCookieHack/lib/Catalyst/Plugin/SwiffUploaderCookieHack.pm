package Catalyst::Plugin::SwiffUploaderCookieHack;
use namespace::autoclean;
use Moose::Role;
use MooseX::Mangle;

use CGI::Simple::Cookie ();

our $VERSION = '0.01';

mangle_return 'prepare' => sub {
  my ($class, $c) = @_;

  my $cookie_name = $c->_session_plugin_config->{cookie_name};

  if ( my $sid = $c->req->params->{$cookie_name} ) {
    $c->log->debug('fixing Swiff.Uploader cookie');
    $c->request->cookies->{$cookie_name} = CGI::Simple::Cookie->new(
      -name  => $cookie_name,
      -value => $sid,
    );
  }

  return $c;
};

1;

=head1 NAME

Catalyst::Plugin::SwiffUploaderCookieHack - Hack to get session restored when
Flash makes a HTTP request to your app.

=head1 DESCRIPTION

There is a major deficiency in the Flash http client. A sane browser plugin
would collect cookies that exist in the context it was loaded from and include
those cookies in the headers of any http requests it makes.

Flash dosen't always do this, and in the situations where it does the
implementation is not optimal.

To work around this, on the client side add your L<Catalyst::Plugin::Session::State::Cookie>'s
session id to the body of the http request keyed to your session's cookie name
and use this plugin to get the session seamlessly restored.

=head1 USAGE

FancyUpload knows about this problem and will put cookies in the http request
for you when it uploads a file if you ask it to. See the appendCookieData
option at L<http://digitarald.de/project/fancyupload/>.

Then load this plugin in to Catalyst like so:

     use Catalyst (
       ...
       'SwiffUploaderCookieHack',
       ...
       'Session',
       'Session::Store::DBIC',
       'Session::State::Cookie',
       ...
     );

Now your session will work seamlessly with Flash.

=head1 CAVEATS

If you try to use the app's L<Catalyst::Plugin::Session> before this plugin
runs, things aren't going to work. Try to reference it in the front of the
C<use Catalyst(...)> argument list so it runs early.

=head1 AUTHOR

Todd Wade <waveright@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Todd Wade

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

