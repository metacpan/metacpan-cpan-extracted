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
    
my $remote = shift;

unless(defined $remote)
{
  say STDERR "usage: perl fget.pl [ -d | -p ] [ -a ] remote";
  say STDERR "  where remote is a URL for a file on an FTP server";
  say STDERR "  and local is a local filename (optional) where to transfer it to";
  say STDERR "  -d (optional) prints FTP commands and responses";
  say STDERR "  -p (optional) displays a progress bar as the file uploads";
  say STDERR "  -a (optional) use active mode transfer";
  exit 2;
}

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
  my $from = $remote->clone;
  $from->password(undef);
  
  say "SRC: ", $from;
};

my @path = split /\//, $remote->path;
my $fn = pop @path;
if(-e $fn)
{
  say STDERR "local file already exists";
  exit 2;
}

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

$ftp->cwd(join '/', '', @path)->recv;

my $remote_size;

if($progress)
{
  my $listing = $ftp->list($fn)->recv;
  foreach my $class (qw( File::Listing File::Listing::Ftpcopy ))
  {
    my $parsed_listing = eval qq{ use $class; ${class}::parse_dir(\$listing->[0]) };
    next if $@;
    my ($name, $type, $size, $mtime, $mode) = @{ $parsed_listing->[0] };
    $remote_size = $size;
    last;
  }
  
  if(defined $remote_size)
  {
  }
  else
  {
    say STDERR "could not determine size of remote file, cannot provide progress bar";
    $progress = 0;
  }
}

open my $fh, '>', $fn;

my $xfer = $ftp->retr($fn);
my $pb;
my $count = 0;

$xfer->on_open(sub {
  my $handle = shift;
  $pb = Term::ProgressBar->new({ count => $remote_size })
    if $progress;
  $handle->on_read(sub {
    $handle->push_read(sub {
      print $fh $_[0]{rbuf};
      $pb->update($count += length($_[0]{rbuf})) if $pb;
      $_[0]{rbuf} = '';
    });
  });
});

$xfer->recv;

close $fh;

$ftp->quit->recv;
