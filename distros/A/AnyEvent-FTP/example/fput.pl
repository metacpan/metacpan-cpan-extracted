#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use 5.010;
use AnyEvent::FTP::Client;
use URI;
use URI::file;
use Term::ProgressBar;
use Term::Prompt qw( prompt );
use Getopt::Long qw( GetOptions );
use Path::Class qw( file );

my $debug = 0;
my $progress = 0;
my $active = 0;

GetOptions(
  'd' => \$debug,
  'p' => \$progress,
  'a' => \$active,
);

my $local = shift;
my $remote = shift;

unless(defined $local && defined $remote)
{
  say STDERR "usage: perl fput.pl [ -d | -p ] [ -a ] local remote";
  say STDERR "  where local is a local file";
  say STDERR "  and remote is a URL for a FTP server";
  say STDERR "  -d (optional) prints FTP commands and responses";
  say STDERR "  -p (optional) displays a progress bar as the file uploads";
  say STDERR "  -a (optional) use an active transfer instead of passive";
  exit 2;
}

$local  = file($local);
$remote = URI->new($remote);

unless($remote->scheme eq 'ftp')
{
  say STDERR "only FTP URLs are supported";
  exit 2;
}

unless(defined $remote->password)
{
  $remote->password(prompt('p', 'Password: ', '', ''));
  say '';
}

do {
  my $from = URI::file->new_abs($local);
  my $to = $remote->clone;
  $to->password(undef);

  say "SRC: ", $from;
  say "DST: ", $to;
};

my $ftp = AnyEvent::FTP::Client->new( passive => $active ? 0 : 1 );

$ftp->on_send(sub {
  my($cmd, $arguments) = @_;
  $arguments //= '';
  $arguments = 'XXXX' if $cmd eq 'PASS';
  say "CLIENT: $cmd $arguments"
    if $debug;
});

$ftp->on_each_response(sub {
  my $res = shift;
  if($debug)
  {
    say sprintf "SERVER: [ %d ] %s", $res->code, $_ for @{ $res->message };
  }
});


$ftp->connect($remote->host, $remote->port)->recv;
$ftp->login($remote->user, $remote->password)->recv;
$ftp->type('I')->recv;

if(defined $remote->path)
{
  $ftp->cwd($remote->path)->recv;
}

open my $fh, '<', $local;
binmode $fh;

my $buffer;
my $count;

my $pb;

my $xfer = $ftp->stor($local->basename);

$xfer->on_open(sub {
  my $whandle = shift;
  $pb = Term::ProgressBar->new({ count => -s $fh })
    if $progress;
  $whandle->on_drain(sub {
    $pb->update($count) if $pb;
    my $ret = read $fh, $buffer, 1024 * 512;
    $count += $ret;
    if($ret > 0)
    {
      $whandle->push_write($buffer);
    }
    else
    {
      $pb->update($count) if $pb;
      $whandle->push_shutdown;
      close $fh;
    }
  });
});

$xfer->recv;

$ftp->quit->recv;
