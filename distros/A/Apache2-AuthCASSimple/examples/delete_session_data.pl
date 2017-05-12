#!/usr/bin/perl

use strict;
use Fcntl ':flock';

sub clean ($)
{
  my $file = shift;

  print "deleting $file\n";

  open(FH, ">>$file") || return -1;
  flock(FH, LOCK_EX) || return -1;
  unlink($file) || return -1;
  flock(FH, LOCK_UN);
  close(FH);

  return 0;
}

my $now = time();
my $time = (3600+60);

my $dir = '/tmp';
my $cnt=0;
my $lnt=0;
my $current=0;

print "\nCleaning session in " . $dir . " (timeout = " . $time . ")\n\n";

opendir(DIR, $dir);
my @files = readdir(DIR);

foreach my $file (@files)
{
  if ($file =~ /^[a-z0-9]{32}$/ )
  {
    if ($now - (stat($dir.'/'.$file))[8] >= $time)
    {
      clean($dir.'/'.$file);
      clean($dir.'/Apache-Session-'.$file.'.lock');
      $cnt++;
      $lnt++;
    }
    else
    {
      $current++;
    }
  }
  if ($file =~ /^Apache-Session-([a-z0-9]{32})\.lock$/ && ! -f $dir.'/'.$1 )
  {
    $lnt++;
    clean($dir.'/'.$file);
  }
}

close DIR;

print "$cnt sessions deleted\n";
print "$lnt lock sessions deleted\n";
print "$current sessions in used\n";

