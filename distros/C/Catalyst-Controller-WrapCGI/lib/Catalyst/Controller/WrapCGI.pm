use utf8;
package Catalyst::Controller::WrapCGI;
our $AUTHORITY = 'cpan:RKITOVER';
$Catalyst::Controller::WrapCGI::VERSION = '0.038';
use 5.008_001;
use Moose;
use mro 'c3';

extends 'Catalyst::Controller';

use Catalyst::Exception ();
use HTTP::Request::AsCGI ();
use HTTP::Request ();
use URI ();
use URI::Escape;
use HTTP::Request::Common;

use namespace::clean -except => 'meta';

=head1 NAME

Catalyst::Controller::WrapCGI - Run CGIs in Catalyst

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use parent qw/Catalyst::Controller::WrapCGI/;
    use CGI ();

    sub hello : Path('cgi-bin/hello.cgi') {
        my ($self, $c) = @_;

        $self->cgi_to_response($c, sub {
            my $q = CGI->new;
            print $q->header, $q->start_html('Hello'),
                $q->h1('Catalyst Rocks!'),
                $q->end_html;
        });
    }

In your .conf, configure which environment variables to pass:

    <Controller::Foo>
        <CGI>
            username_field username # used for REMOTE_USER env var
            pass_env PERL5LIB
            pass_env PATH
            pass_env /^MYAPP_/
            kill_env MYAPP_BAD
        </CGI>
    </Controller::Foo>

=head1 DESCRIPTION

Allows you to run Perl code in a CGI environment derived from your L<Catalyst>
context.

B<*WARNING*>: do not export L<CGI> functions into a Controller, it will break
with L<Catalyst> 5.8 onward.

If you just want to run CGIs from files, see L<Catalyst::Controller::CGIBin>.

C<REMOTE_USER> will be set to C<< $c->user->obj->$username_field >> if
available, or to C<< $c->req->remote_user >> otherwise.

=head1 CONFIGURATION

=head2 pass_env

C<< $your_controller->{CGI}{pass_env} >> should be an array of environment variables
or regular expressions to pass through to your CGIs. Entries surrounded by C</>
characters are considered regular expressions.

=head2 kill_env

C<< $your_controller->{CGI}{kill_env} >> should be an array of environment
variables or regular expressions to remove from the environment before passing
it to your CGIs.  Entries surrounded by C</> characters are considered regular
expressions.

Default is to pass the whole of C<%ENV>, except for entries listed in
L</FILTERED ENVIRONMENT> below.

=head2 username_field

C<< $your_controller->{CGI}{username_field} >> should be the field for your
user's name, which will be read from C<< $c->user->obj >>. Defaults to
'username'.

See L</SYNOPSIS> for an example.

=cut

# Hack-around because Catalyst::Engine::HTTP goes and changes
# them to be the remote socket, and FCGI.pm does even dumber things.

open my $REAL_STDIN, "<&=".fileno(*STDIN);
open my $REAL_STDOUT, ">>&=".fileno(*STDOUT);

=head1 METHODS

=head2 cgi_to_response

C<< $self->cgi_to_response($c, $coderef) >>

Does the magic of running $coderef in a CGI environment, and populating the
appropriate parts of your Catalyst context with the results.

Calls L</wrap_cgi>.

=cut

sub cgi_to_response {
  my ($self, $c, $script) = @_;

  my $res = $self->wrap_cgi($c, $script);

  # if the CGI doesn't set the response code but sets location they were
  # probably trying to redirect so set 302 for them

  my $location = $res->headers->header('Location');

  if (defined $location && length $location && $res->code == 200) {
    $c->res->status(302);
  } else { 
    $c->res->status($res->code);
  }
  $c->res->body($res->content);
  $c->res->headers($res->headers);
}

=head2 wrap_cgi

C<< $self->wrap_cgi($c, $coderef) >>

Runs C<$coderef> in a CGI environment using L<HTTP::Request::AsCGI>, returns an
L<HTTP::Response>.

The CGI environment is set up based on C<$c>.

The environment variables to pass on are taken from the configuration for your
Controller, see L</SYNOPSIS> for an example. If you don't supply a list of
environment variables to pass, the whole of %ENV is used (with exceptions listed
in L</FILTERED ENVIRONMENT>.

Used by L</cgi_to_response>, which is probably what you want to use as well.

=cut

sub wrap_cgi {
  my ($self, $c, $call) = @_;
  my $req = HTTP::Request->new(
    map { $c->req->$_ } qw/method uri headers/
  );
  my $body = $c->req->body;
  my $body_content = '';

  $req->content_type($c->req->content_type); # set this now so we can override

  if ($body) { # Slurp from body filehandle
    seek $body, 0, 0;
    local $/; $body_content = <$body>;
    seek $body, 0, 0; # reset for anyone else down the chain
  } else {
    my $body_params = $c->req->body_parameters || {};

    if (my %uploads = %{ $c->req->uploads }) {
      my $post = POST 'http://localhost/',
        Content_Type => 'form-data',
        Content => [
          %$body_params,
          map {
            my $upl = $uploads{$_};
            $_ => [
              undef,
              $upl->filename,
              Content => $upl->slurp,
              map {
                my $header = $_;
                map { $header => $_ } $upl->headers->header($header)
              } $upl->headers->header_field_names
            ]
          } keys %uploads
        ];
      $body_content = $post->content;
      $req->content_type($post->header('Content-Type'));
    } elsif (%$body_params) {
      my $encoder = URI->new;
      $encoder->query_form(%$body_params);
      $body_content = $encoder->query;
      $req->content_type('application/x-www-form-urlencoded');
    }
  }

  $req->content($body_content);
  $req->content_length(length($body_content));

  my $username_field = $self->{CGI}{username_field} || 'username';

  my $username = (($c->can('user_exists') && $c->user_exists)
               ? eval { $c->user->obj->$username_field }
                : '');

  $username ||= $c->req->remote_user if $c->req->can('remote_user');

  my $path_info = '/'.join '/' => map {
    utf8::is_utf8($_) ? uri_escape_utf8($_) : uri_escape($_)
  } @{ $c->req->args };

  my $env = HTTP::Request::AsCGI->new(
              $req,
              ($username ? (REMOTE_USER => $username) : ()),
              PATH_INFO => $path_info,
# eww, this is likely broken:
              FILEPATH_INFO => '/'.$c->action.$path_info,
              SCRIPT_NAME => $c->uri_for($c->action, $c->req->captures)->path
            );

  {
    local *STDIN = $REAL_STDIN;   # restore the real ones so the filenos
    local *STDOUT = $REAL_STDOUT; # are 0 and 1 for the env setup

    my $old = select($REAL_STDOUT); # in case somebody just calls 'print'

    my $saved_error;

    local %ENV = %{ $self->_filtered_env(\%ENV) };

    $env->setup;
    eval { $call->() };
    $saved_error = $@;
    $env->restore;

    select($old);

    if( $saved_error ) {
        die $saved_error if ref $saved_error;
        Catalyst::Exception->throw(
            message => "CGI invocation failed: $saved_error"
           );
    }
  }

  return $env->response;
}

=head1 FILTERED ENVIRONMENT

If you don't use the L</pass_env> option to restrict which environment variables
are passed in, the default is to pass the whole of C<%ENV> except the variables
listed below.

  MOD_PERL
  SERVER_SOFTWARE
  SERVER_NAME
  GATEWAY_INTERFACE
  SERVER_PROTOCOL
  SERVER_PORT
  REQUEST_METHOD
  PATH_INFO
  PATH_TRANSLATED
  SCRIPT_NAME
  QUERY_STRING
  REMOTE_HOST
  REMOTE_ADDR
  AUTH_TYPE
  REMOTE_USER
  REMOTE_IDENT
  CONTENT_TYPE
  CONTENT_LENGTH
  HTTP_ACCEPT
  HTTP_USER_AGENT

C<%ENV> can be further trimmed using L</kill_env>.

=cut

my $DEFAULT_KILL_ENV = [qw/
  MOD_PERL SERVER_SOFTWARE SERVER_NAME GATEWAY_INTERFACE SERVER_PROTOCOL
  SERVER_PORT REQUEST_METHOD PATH_INFO PATH_TRANSLATED SCRIPT_NAME QUERY_STRING
  REMOTE_HOST REMOTE_ADDR AUTH_TYPE REMOTE_USER REMOTE_IDENT CONTENT_TYPE
  CONTENT_LENGTH HTTP_ACCEPT HTTP_USER_AGENT
/];

sub _filtered_env {
  my ($self, $env) = @_;
  my @ok;

  my $pass_env = $self->{CGI}{pass_env};
  $pass_env = []            if not defined $pass_env;
  $pass_env = [ $pass_env ] unless ref $pass_env;

  my $kill_env = $self->{CGI}{kill_env};
  $kill_env = $DEFAULT_KILL_ENV unless defined $kill_env;
  $kill_env = [ $kill_env ]  unless ref $kill_env;

  if (@$pass_env) {
    for (@$pass_env) {
      if (m!^/(.*)/\z!) {
        my $re = qr/$1/;
        push @ok, grep /$re/, keys %$env;
      } else {
        push @ok, $_;
      }
    }
  } else {
    @ok = keys %$env;
  }

  for my $k (@$kill_env) {
    if ($k =~ m!^/(.*)/\z!) {
      my $re = qr/$1/;
      @ok = grep { ! /$re/ } @ok;
    } else {
      @ok = grep { $_ ne $k } @ok;
    }
  }
  return { map {; $_ => $env->{$_} } @ok };
}

__PACKAGE__->meta->make_immutable;

=head1 DIRECT SOCKET/NPH SCRIPTS

This currently won't work:

    #!/usr/bin/perl

    use CGI ':standard';

    $| = 1;

    print header;

    for (0..1000) {
        print $_, br, "\n";
        sleep 1;
    }

because the coderef is executed synchronously with C<STDOUT> pointing to a temp
file.

=head1 ACKNOWLEDGEMENTS

Original development sponsored by L<http://www.altinity.com/>

=head1 SEE ALSO

L<Catalyst::Controller::CGIBin>, L<CatalystX::GlobalContext>,
L<Catalyst::Controller>, L<CGI>, L<Catalyst>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-controller-wrapcgi
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Controller-WrapCGI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Matt S. Trout C<< <mst at shadowcat.co.uk> >>

=head1 CONTRIBUTORS

Caelum: Rafael Kitover <rkitover@cpan.org>

confound: Hans Dieter Pearcey <hdp@cpan.org>

rbuels: Robert Buels <rbuels@gmail.com>

Some code stolen from Tatsuhiko Miyagawa's L<CGI::Compile>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2015 L<Catalyst::Controller::WrapCGI/AUTHOR> and
L<Catalyst::Controller::WrapCGI/CONTRIBUTORS>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__; # End of Catalyst::Controller::WrapCGI

# vim: expandtab shiftwidth=2 ts=2 tw=80:
