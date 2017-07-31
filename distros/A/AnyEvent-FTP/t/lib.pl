package main;

use strict;
use warnings;
use 5.010;
use FindBin ();
use Path::Class qw( dir file );
use Path::Class ();
use File::Spec;
use Test::More;
use File::Glob qw( bsd_glob );
use Cwd ();

$ENV{LC_ALL} = 'C';

our $config;
our $detect;
our $lock;

*my_abs_path = $^O eq 'MSWin32' ? sub ($) { $_[0] } : \&Cwd::abs_path ;

$config->{dir} //= dir( -l file(__FILE__) ? file(readlink file(__FILE__))->parent : $FindBin::Bin )->parent->stringify;

do {
  my $file = file( __FILE__ )->parent->file("config.yml")->stringify;
  $ENV{AEF_CONFIG} = $file if -r $file;
};

if(defined $ENV{AEF_PORT} && ! defined $ENV{AEF_CONFIG})
{
  $ENV{AEF_CONFIG} //= file( bsd_glob '~/etc/localhost.yml' )->stringify;
}

if(defined $ENV{AEF_CONFIG})
{
  my $save = $config->{dir};
  require YAML;
  $config = YAML::LoadFile($ENV{AEF_CONFIG});
  $config->{dir} = $save if defined $save;
  $config->{dir} = Path::Class::Dir->new($config->{dir})->resolve;
  $config->{port} //= $ENV{AEF_PORT} if defined $ENV{AEF_PORT};
  $config->{host} //= $ENV{AEF_HOST} // 'localhost';
  $config->{port} = getservbyname($config->{port}, "tcp")
    if defined $config->{port} && $config->{port} !~ /^\d+$/;
  if(defined $config->{remote})
  {
    $ENV{AEF_REMOTE} = $config->{remote};
    # remote server tests may not be parallel safe
    require NX::Lock;
    $lock = NX::Lock->new($ENV{AEF_CONFIG}, block => 1);
  }
}
else
{
  require AnyEvent::FTP::Server;
  my $server = AnyEvent::FTP::Server->new(
    host => 'localhost',
    port => 0,
    default_context => 'AnyEvent::FTP::Server::Context::FSRW',
  );
  
  $config->{host} = 'localhost';
  $config->{user} = join '', map { chr(ord('a') + int rand(26)) } (1..10);
  $config->{pass} = join '', map { chr(ord('a') + int rand(26)) } (1..10);
  note "using fake credentials ", join ':', $config->{user}, $config->{pass};
  
  $server->on_bind(sub {
    my $port = shift;
    $config->{port} = $port;
    note "binding aeftpd localhost:$port";
  });
  
  $server->on_connect(sub {
    my $con = shift;
    $con->context->authenticator(sub {
      my($user, $pass) = @_;
      $user eq $config->{user} && $pass eq $config->{pass} ? 1 : 0;
    });
    $con->context->bad_authentication_delay(0);
  });
  
  $server->start;
  
  $detect->{ae} = 1;
}

our $anyevent_test_timeout = AnyEvent->timer( after => ($detect->{ae} ? 5 : 15), cb => sub { diag "TIMEOUT: giving up"; exit } );

sub prep_client
{
  my($client) = @_;

  if($ENV{AEF_DEBUG})
  {
    $client->on_send(sub {
      my($cmd, $arguments) = @_;
      $arguments //= '';
      $arguments = 'XXXX' if $cmd eq 'PASS';
      note "CLIENT: $cmd $arguments";
    });

    $client->on_each_response(sub {
      my $res = shift;
      note sprintf "SERVER: [ %d ] %s\n", $res->code, $_ for @{ $res->message };
    });
  }

  $client->on_greeting(sub {
    my $res = shift;
    $detect->{wu} = 1 if $res->message->[0] =~ /FTP server \(Version wu/;
    $detect->{pu} = 1 if $res->message->[0] =~ /Welcome to Pure-FTPd/;
    $detect->{vs} = 1 if $res->message->[0] =~ /\(vsFTPd /;
    $detect->{pl} = 1 if $res->message->[0] =~ /FTP server \(Net::FTPServer/;
    $detect->{pr} = 1 if $res->message->[0] =~ /ProFTPD/;
    $detect->{ms} = 1 if $res->message->[0] =~ /Microsoft FTP Service/;
    $detect->{nc} = 1 if $res->message->[0] =~ /NcFTPd Server/;
    $detect->{xb} = 1 if $res->message->[0] =~ /^bftpd /;
  });

}

sub translate_dir
{
  my $dir = shift;
  if($^O eq 'cygwin' && $detect->{ms})
  {
    $dir =~ s{^/cygdrive/(.)/}{$1:};
    $dir =~ s{^/tmp/}{/cygwin/tmp};
    $dir =~ s{/}{\\}g;
    return $dir;
  }
  else
  {
    return $dir;
  }
}

sub net_pwd
{
  my($pwd) = @_;
  
  if($^O eq 'MSWin32')
  {
    (undef,$pwd) = File::Spec->splitpath($pwd,1);
    $pwd =~ s{\\}{/}g;
  }
  
  my_abs_path($pwd);
}

1;
