#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use IO::Socket::UNIX;
use Socket qw( SOCK_STREAM );
use API::Docker;
use API::Docker::Error::HTTP;

# A daemon that answers and closes before it has read the request body
# (karr k114). The request used to be one unchecked `print`: once the body no
# longer fit the socket buffer the kernel raised SIGPIPE on the next write
# and the whole process died with status 141, with no exception at all.
# Offline: a forked AF_UNIX listener stands in for dockerd.

my $dir  = tempdir( CLEANUP => 1 );
my $path = $dir.'/d.sock';

# Serve one connection: read a little, answer, close without draining.
sub serve_once {
  my ( $reply ) = @_;
  unlink $path;
  my $srv = IO::Socket::UNIX->new(
    Local => $path, Listen => 1, Type => SOCK_STREAM,
  ) or plan skip_all => 'cannot listen: '.$!;
  my $pid = fork;
  plan skip_all => 'fork unavailable' unless defined $pid;
  if ( !$pid ) {
    my $c = $srv->accept;
    my $buf;
    sysread $c, $buf, 100;
    syswrite $c, $reply if defined $reply;
    close $c;
    exit 0;
  }
  close $srv;
  return $pid;
}

my $json  = '{"message":"no such container"}';
my $reply = "HTTP/1.1 413 Request Entity Too Large\r\n"
  .'Content-Type: application/json'."\r\n"
  .'Content-Length: '.length($json)."\r\n"
  ."Connection: close\r\n\r\n".$json;

my $docker = API::Docker->new(
  host => 'unix://'.$path, api_version => '1.41',
);

# Run the call in a child, so a SIGPIPE shows up as a wait status instead of
# ending the test run, and report what happened.
sub attempt {
  my ( $r ) = @_;
  my $srv_pid = serve_once($r);
  pipe my $rd, my $wr or die $!;
  my $pid = fork;
  if ( !$pid ) {
    close $rd;
    my $ok = eval {
      $docker->post( '/build', undef, raw_body => 'x' x 20_000_000 ); 1 };
    my $e   = $@;
    my $cls = ref $e ? ref $e : 'string';
    $e = "$e";
    $e =~ s/\s+/ /g;
    print $wr $ok ? "ok\n" : $cls."\n".$e."\n";
    close $wr;
    exit 0;
  }
  close $wr;
  my @out = <$rd>;
  waitpid $pid, 0;
  my $status = $?;
  kill 'TERM', $srv_pid;
  waitpid $srv_pid, 0;
  chomp @out;
  return ( $status, @out );
}

{
  my ( $status, $cls, $msg ) = attempt($reply);
  is $status, 0, 'the process survives a daemon that closes early'
    or diag 'wait status '.$status;
  is $cls // '', 'API::Docker::Error::HTTP',
    'the 413 reaches the caller as an HTTP error';
  like $msg // '', qr/413/, 'and names the status';
}

{
  my ( $status, $cls, $msg ) = attempt(undef);
  is $status, 0, 'no answer at all: still no signal';
  isnt $cls // '', 'ok', 'it croaks';
  like $msg // '', qr{/build}, 'the transport error names the endpoint';
}

done_testing;
