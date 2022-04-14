package Test::AnyEventFTPServer;

use strict;
use warnings;
use 5.010;
use Moo;
use URI;
use AnyEvent;
use Test2::API qw( context );
use Path::Class qw( tempdir );

extends 'AnyEvent::FTP::Server';

# ABSTRACT: Test (non-blocking) ftp clients against a real FTP server
our $VERSION = '0.19'; # VERSION


has test_uri => (
  is       => 'ro',
  required => 1,
);


has res => (
  is => 'rw',
);


has content => (
  is      => 'rw',
  default => '',
);


has auto_login => (
  is      => 'rw',
  default => sub { 1 },
);

has _client => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    require AnyEvent::FTP::Client;
    my $client = AnyEvent::FTP::Client->new;
    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(
      after => 5,
      cb    => sub { $cv->croak("timeout connecting with ftp client") },
    );
    if($self->auto_login)
    {
      $client->connect($self->test_uri)
             ->cb(sub { $cv->send });
    }
    else
    {
      $client->connect($self->test_uri->host, $self->test_uri->port)
             ->cb(sub { $cv->send });
    }
    $cv->recv;
    $client;
  },
);


sub create_ftpserver_ok (;$$)
{
  my($context, $message) = @_;

  my $ctx = context();

  my $uri = URI->new("ftp://127.0.0.1");

  $context //= 'Memory';
  $context = "AnyEvent::FTP::Server::Context::$context"
    unless $context =~ /::/;
  my $name = (split /::/, $context)[-1];

  my $user = join '', map { chr(ord('a') + int rand(26)) } (1..10);
  my $pass = join '', map { chr(ord('a') + int rand(26)) } (1..10);
  $uri->userinfo(join(':', $user, $pass));

  my $server;
  eval {
    $server = Test::AnyEventFTPServer->new(
      default_context => $context,
      hostname        => '127.0.0.1',
      port            => undef,
      test_uri        => $uri,
    );

    if($ENV{AEF_DEBUG})
    {
      $server->on_connect(sub {
        my $con = shift;
        $ctx->note("CONNECT");

        $con->on_request(sub {
          my $raw = shift;
          $ctx->note("CLIENT: $raw");
        });

        $con->on_response(sub {
          my $raw = shift;
          $ctx->note("SERVER: $raw");
        });

        $con->on_close(sub {
          $ctx->note("DISCONNECT");
        });
      });
    }

    $server->on_connect(sub {
      shift->context->authenticator(sub {
        return $_[0] eq $user && $_[1] eq $pass;
      });
    });

    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(
      after => 5,
      cb    => sub { $cv->croak("timeout creating ftp server") },
    );
    $server->on_bind(sub {
      $uri->port(shift);
      $cv->send;
    });
    $server->start;
    $cv->recv;
  };
  my $error = $@;

  $message //= "created FTP ($name) server at $uri";

  $ctx->ok($error eq '', $message);
  $ctx->diag($error) if $error;
  $ctx->release;

  $server;
}


sub connect_ftpclient_ok
{
  my($self, $message) = @_;
  my $client;
  eval {
    require AnyEvent::FTP::Client;
    $client = AnyEvent::FTP::Client->new;
    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(
      after => 5,
      cb    => sub { $cv->croak("timeout connecting with ftp client") },
    );
    if($self->auto_login)
    {
      $client->connect($self->test_uri)
             ->cb(sub { $cv->send });
    }
    else
    {
      $client->connect($self->tesT_uri->host, $self->test_uri->port)
             ->cb(sub { $cv->send });
    }
    $cv->recv;
  };
  my $error = $@;

  $message //= "connected to FTP server at " . $self->test_uri;

  my $ctx = context();
  $ctx->ok($error eq '', $message);
  $ctx->diag($error) if $error;
  $ctx->release;

  $client;
}


sub help_coverage_ok
{
  my($self, $class, $message) = @_;

  $class //= $self->default_context;

  my @missing;

  my $client = eval { $self->_client };
  my $error = $@;

  my $count = 0;
  unless($error)
  {
    foreach my $cmd (map { uc $_ } grep s/^cmd_//,  eval qq{ use $class; keys \%${class}::;})
    {
      if((eval { $client->help($cmd)->recv } || $@)->code != 214)
      { push @missing, $cmd }
      $count++;
    }
  }

  $message //= "help coverage for $class";

  my $ctx = context();
  $ctx->ok($error eq '' && @missing == 0, $message);
  $ctx->diag($error) if $error;
  $ctx->diag("commands missing help: @missing") if @missing;
  $ctx->diag("didn't find ANY commands for class: $class")
    if $count == 0;
  $ctx->release;

  $self;
}


sub command_ok
{
  my($self, $command, $args, $message) = @_;

  my $client = eval { $self->_client };
  my $error = $@;

  unless($error)
  {
    my $res = (eval { $client->push_command([$command, $args])->recv } || $@);
    if(eval { $res->isa('AnyEvent::FTP::Client::Response') })
    { $self->res($res) }
    else
    { $error = $res; $self->res(undef) }
  }

  $message //= "command: $command";

  my $ctx = context();
  $ctx->ok($error eq '', $message);
  $ctx->diag($error) if $error;
  $ctx->release;

  $self;
}


sub code_is
{
  my($self, $code, $message) = @_;

  $message //= "response code is $code";

  my $ctx = context();
  my $actual = eval { $self->res->code } // 'undefined';
  $ctx->ok($actual == $code, $message);
  $ctx->diag("actual code returned is $actual")
    unless $actual == $code;
  $ctx->release;

  $self;
}


sub code_like
{
  my($self, $regex, $message) = @_;

  $message //= "response code matches";

  my $ctx = context();
  my $actual = eval { $self->res->code } // 'undefined';
  $ctx->ok($actual =~ $regex, $message);
  $ctx->diag("code $actual does not match $regex")
    unless $actual =~ $regex;
  $ctx->release;

  $self;
}


sub message_like
{
  my($self, $regex, $message) = @_;

  $message //= "response message matches";

  my $ok = 0;

  my @message = @{ (eval { $self->res->message }) // [] };
  foreach my $line (@message)
  {
    $ok = 1 if $line =~ $regex;
  }

  my $ctx = context();
  $ctx->ok($ok, $message);
  unless($ok)
  {
    $ctx->diag("message: ");
    $ctx->diag("  $_") for @message;
    $ctx->diag("does not match $regex");
  }
  $ctx->release;

  $self;
}


sub message_is
{
  my($self, $string, $message) = @_;

  $message //= "response message matches";

  my $ok = 0;

  my @message = @{ (eval { $self->res->message }) // [] };

  foreach my $line (@message)
  {
    $ok = 1 if $line eq $string;
  }

  my $ctx = context();
  $ctx->ok($ok, $message);
  unless($ok)
  {
    $ctx->diag("message: ");
    $ctx->diag("  $_") for @message;
    $ctx->diag("does not match $string");
  }
  $ctx->release;

  $self;
}


sub list_ok
{
  my($self, $location, $message) = @_;

  $message //= defined $location ? "list: $location" : 'list';

  my $client = eval { $self->_client };
  my $error = $@;

  $self->content('');

  unless($error)
  {
    my $list = eval { $client->list($location)->recv };
    $error = $@;
    $self->content(join "\n", @$list, '') unless $error;
  }

  my $ctx = context();
  $ctx->ok($error eq '', $message);
  $ctx->diag($error) if $error;
  $ctx->release;

  $self;
}


sub nlst_ok
{
  my($self, $location, $message) = @_;

  $message //= defined $location ? "nlst: $location" : 'nlst';

  my $client = eval { $self->_client };
  my $error = $@;

  $self->content('');

  unless($error)
  {
    my $list = eval { $client->nlst($location)->recv };
    $error = $@;
    $self->content(join "\n", @$list, '') unless $error;
  }

  my $ctx = context();
  $ctx->ok($error eq '', $message);
  $ctx->diag($error) if $error;
  $ctx->release;

  $self;
}


sub _display_content
{
  state $temp;
  state $counter = 0;
  my $method = 'diag';
  #$method = 'note' if $tb->todo;

  unless(defined $temp)
  {
    $temp = tempdir(CLEANUP => 1);
  }

  my $file = $temp->file(sprintf("data.%d", $counter++));
  $file->spew($_[0]);

  my $ctx = context();

  if(-T $file)
  {
    $ctx->$method("  $_") for split /\n/, $_[0];
  }
  else
  {
    if(eval { require Data::HexDump })
    {
      $ctx->$method("  $_") for grep !/^$/, split /\n/, Data::HexDump::HexDump($_[0]);
    }
    else
    {
      $ctx->$method("  binary content");
    }
  }

  $ctx->release;

  $file->remove;
}

sub content_is
{
  my($self, $string, $message) = @_;

  $message ||= 'content matches';

  my $ok = $self->content eq $string;

  my $ctx = context();
  $ctx->ok($ok, $message);
  unless($ok)
  {
    $ctx->diag("content:");
    _display_content($self->content);
    $ctx->diag("expected:");
    _display_content($string);
  }

  $ctx->release;

  $self;
}


sub global_timeout_ok (;$$)
{
  my($timeout, $message) = @_;

  $timeout //= 120;
  $message //= "global timeout of $timeout seconds";

  my $ctx = context();

  state $timers = [];

  eval {
    push @$timers, AnyEvent->timer(
      after => $timeout,
      cb    => sub { $ctx->diag("GLOBAL TIMEOUT"); exit },
    );
  };
  my $error = $@;

  my $ok = $error eq '';

  $ctx->ok($ok, $message);
  $ctx->diag($error) if $error;

  $ctx->release;

  $ok;
}

sub import
{
  my $caller = caller;
  no strict 'refs';
  *{join '::', $caller, 'create_ftpserver_ok'} = \&create_ftpserver_ok;
  *{join '::', $caller, 'global_timeout_ok'} = \&global_timeout_ok;
}

BEGIN { eval 'use EV' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::AnyEventFTPServer - Test (non-blocking) ftp clients against a real FTP server

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 use Test2:V0;
 use Test::AnyEventFTPServer;
 
 # exit this script after 30s to avoid hung test
 global_timeout_ok;
 
 # $test_server isa AnyEvent::FTP::Server
 # and          isa Test::AnyEventFTPServer
 my $test_server = create_ftpserver_ok;
 
 $test_server->command_ok('HELP')
             ->code_is(214)
             ->message_like(qr{the following commands are recognize});
 
 # $res isa AnyEvent::FTP::Client::Response
 # from that last HELP command
 my $res = $test_server->res;
 
 # $client isa AnyEvent::FTP::Client
 my $client = $test_server->connect_ftpclient_ok;
 
 # check to make sure that all FTP commands have help
 $test_server->help_coverage_ok;
 
 done_testing;

=head1 DESCRIPTION

This module makes it easy to test ftp clients against a real
L<AnyEvent::FTP> FTP server.  The FTP server is non-blocking in
and does not C<fork>, so if you are testing a FTP client that
blocks then you will need to do it in a separate process.
L<AnyEvent::FTP::Client> is a client that doesn't block and so
is safe to use in testing against the server.

=head1 ATTRIBUTES

=head2 test_uri

 my $uri = $test_server->test_uri

The full URL (including host, port, username and password) of the
test ftp server.  This is returned as L<URI>.

=head2 res

 my $res = $test_server->res

The last L<AnyEvent::FTP::Client::Response> object returned from the
server after calling the C<command_ok> method.

=head2 content

 my $content = $test_server->content

The last content retrieved from a C<list_ok>, C<nlst_ok> or C<transfer_ok>
test.

=head2 auto_login

 my $bool = $test_server->auto_login

If true (the default) automatically login using the correct credentials.
Normally if you are testing file transfers you want to keep this to the
default value, if you are testing the authentication of a server context
then you want to set this to false.

=head1 METHODS

=head2 create_ftpserver_ok

 my $test_server = create_ftpserver_ok;
 my $test_server = create_ftpserver_ok($default_context);
 my $test_server = create_ftpserver_ok($default_context, $test_name);

Create the FTP server with a random username and password
for logging in.  You can get the username/password from the
C<test_uri> attribute, or connect to the server using
L<AnyEvent::FTP::Client> automatically with the C<connect_ftpclient_ok>
method below.

=head2 connect_ftpclient_ok

 my $client = $test_server->connect_ftpclient_ok;
 my $client = $test_server->connect_ftpclient_ok($test_name);

Connect to the FTP server, return the L<AnyEvent::FTP::Client>
object which can be used for testing.

=head2 help_coverage_ok

 $test_server->help_coverage_ok;
 $test_server->help_coverage_ok($context_class);
 $test_server->help_coverage_ok($context_class, $test_name);

Test that there is a C<help_*> method for each C<cmd_*> method in the
given context class (the server's default context class is used if
it isn't provided).  This can also be used to test help coverage of
context roles.

=head2 command_ok

 $test_command->command_ok( $command, $arguments );
 $test_command->command_ok( $command, $arguments, $test_name );

Execute the given command with the given arguments on the
remote server.  Fails only if a valid FTP response is not
returned from the server (even error responses are okay).

The response is stored in the C<res> attribute.

This method returns the test server object, so you can
chain this command:

 $server->command_ok('HELP', 'HELP') # get help on the help command
        ->code_is(214)               # returns status code 214
        ->message_like(qr{HELP});    # the help command mentions the help command

=head2 code_is

 $test_server->code_is($code);
 $test_server->code_is($code, $test_name);

Verifies that the status code of the last command executed matches
the given code exactly.

=head2 code_like

 $test_server->code_like($regex);
 $test_server->code_like($regex, $test_name);

Verifies that the status code of the last command executed matches
the given regular expression..

=head2 message_like

 $test_server->message_like($regex);
 $test_server->message_like($regex, $test_name);

Verifies that the message portion of the response of the last command executed matches
the given regular expression.

=head2 message_is

 $test_server->message_is($string);
 $test_server->message_is($string, $test_name);

Verifies that the message portion of the response of the last command executed matches
the given string.

If the response message has multiple lines, then only one of the lines needs to match
the given string.

=head2 list_ok

 $test_server->list_ok;
 $test_server->list_ok($location);
 $test_server->list_ok($location, $test_name)

Execute a the C<LIST> command on the given C<$location>
and wait for the results.  You can see the result using
the C<content> attribute or test it with the C<content_is>
method.

=head2 nlst_ok

 $test_server->nlst_ok;
 $test_server->nlst_ok( $location );
 $test_server->nlst_ok( $location, $test_name );

Execute a the C<NLST> command on the given C<$location>
and wait for the results.  You can see the result using
the C<content> attribute or test it with the C<content_is>
method.

=head2 content_is

 $test_server->content_is($string);
 $test_server->content_is($string, $test_name);

Test that the given C<$string> matches the content
returned by the last C<list_ok> or C<nlst_ok> method.

=head2 global_timeout_ok

 global_timeout_ok;
 global_timeout_ok($timeout);
 global_timeout_ok($timeout, $test_name)

Set a global timeout on the entire test script.  If the timeout
is exceeded the test will exit.  Handy if you have test automation
and your test automation doesn't handle hung tests.

The default timeout is 120 seconds.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
