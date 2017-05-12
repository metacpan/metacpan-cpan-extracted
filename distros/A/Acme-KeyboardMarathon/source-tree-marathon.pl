#!/usr/bin/perl -Ilib

use Acme::KeyboardMarathon;
use Cwd 'abs_path';
use DB_File;
use File::Find;
use File::Slurp;
use Math::BigInt lib => 'GMP';
use strict;
use warnings;

=head1 source-tree-marathon.pl

This script is designed to recursively crawl a directory of source files 
to generate a Keyboard-Marathon report for your whole project.

In does it's best to skip binary files. It will not uncompact compressed 
files.

To conserve ram, it will create a local berkley DB (called 
"marathon.db") in the current working directory. If you want to run this 
script on a regular basis this will vastly accelerate calculations as 
only new and changed files will be processed. (Deleted files will 
automatically be pruned from the DB and from calculations.)

The report will include the grand total distance, as well as a breakdown by
file type.

Processing status is presented on STDERR. The report is output on STDOUT. So
it is very easy to redirect the output to a file:

  %> ./source-tree-marathon.pl /my/source/directory > report.txt

This script requires the following perl modules: File::Find, 
File::Slurp, Math::BigInt and Acme::KeyboardMarathon

=cut

### Conf

my $dbfile = 'marathon.db';

my $base_dir;

if ( $ARGV[0] and -d $ARGV[0] ) {
  $base_dir = abs_path($ARGV[0]);
}

unless ( $base_dir ) {
  print STDERR "Usage: ./source-tree-marathon.pl /source/directory/to/crawl > report.txt\n";
  exit 1;
}

### Constants

my $skip_file_extension_regex = qr{\.(binmode|bmp|docx|exe|gif|gz|ico|jar|jpe?g|o|obj|pdf|png|pptx|pyc|so|tar(\.xz)?|tiff?|tgz|ttf|vsd|zip)$};
my $skip_dirs_regex = qr/^(\.git|tpc|debian|linux-kernel)/;

### Bootstrap


my %data;

if ( -f $dbfile ) {
  print STDERR "Reusing file: $dbfile\n";
} else {
  print STDERR "Creating file: $dbfile\n";
}

my $ref = tie %data, 'DB_File', $dbfile;

my $akm = new Acme::KeyboardMarathon;
 
### Main

# Remove file stats for missing files
for my $file ( keys %data ) {
  next if -f $file;
  print STDERR "DEL: $file\n";
  delete $data{$file}
}

### Store stats

$| = 1; # autoflush

my $skip  = 0;
my $add   = 0;
my $cache = 0;

find( \&check_stats, $base_dir );

print STDERR "\nDB Stats:\nADD: $add\nCACHE: $cache\nSKIP: $skip\n";


if ( $add ) {
  print STDERR "\nSyncing...\n";
  $ref->sync();
}

### Process stats

my %filecounts;
my %filedists;

my $grand_total = Math::BigInt->new();

for my $file ( keys %data ) {
  next unless $file =~ /\.([^\.\/]+)$/;

  my $type = $1;
  $filecounts{$type}++;

  my ($mtime,$size,$dist) = split ':', $data{$file}, 3;

  $filedists{$type} = Math::BigInt->new() unless defined $filedists{$type};
  $filedists{$type} += $dist;
  $grand_total += $dist;
}

print "Generated on " . scalar(localtime) . "\n\n";

print "\nGrand total: ", display($grand_total), "\n\nTop 10 distance:\n\n";

my $i = 1;
for my $type ( sort { $filedists{$b} <=> $filedists{$a}  } keys %filedists ) {
  printf "%20s : %4s files : %s\n", $type, $filecounts{$type}, display($filedists{$type});
  last if $i++ > 10;
}

print "\nDistances by file count:\n\n";

for my $type ( sort { $filecounts{$b} <=> $filecounts{$a} } keys %filecounts ) {
  printf "%20s : %4s files : %s\n", $type, $filecounts{$type}, display($filedists{$type});
}

### Subroutines

sub check_stats {
  if ( -d $_ ) {
    my $localdir = $File::Find::name;
    $localdir = $1 if $localdir =~ /^$base_dir\/(.+)$/;
    print STDERR "DIR: $localdir\n";
    return;
  }
  $skip++ and print STDERR "SKIP: $_ (regex)\n" and return if $_ =~ /$skip_file_extension_regex/i;

  my $localdir = $File::Find::dir;
  $localdir = $1 if $localdir =~ /^$base_dir\/(.+)$/;
  $skip++ and print STDERR "SKIP: $localdir (directory)\n" and return if $localdir =~ /$skip_dirs_regex/;

  $skip++ and print STDERR "SKIP: $_ (symlink)\n" and return if -l $File::Find::name;
  $skip++ and print STDERR "SKIP: $_ (zero size)\n" and return if -z $File::Find::name;
  $skip++ and print STDERR "SKIP: $_ (binary)\n" and return if -B $File::Find::name;

  my @stat = stat($File::Find::name);
  my $mtime = $stat[9];
  my $size  = $stat[7];

  if ( defined $data{$File::Find::name} and $data{$File::Find::name} =~ /^$mtime\:$size\:/ ) {
    $cache++ and print STDERR "CACHE: $_\n";
    return;
  }

  $add++ and print STDERR "ADD: $_ ";

  my $text = read_file($File::Find::name);
  my $dist = $akm->distance($text);

  $data{$File::Find::name} = "$mtime:$size:$dist";

  print STDERR "(".display($dist).")\n";

  unless ( $add % 250 ) {
    print STDERR "syncing...\n";
    $ref->sync();
  }
}

sub display {
  my $total = "$_[0]"; # Convert to 
  if ( $total > 100000 ) {
    $total /= 100000;
    return sprintf('%0.2f',$total) . ' km';
  } elsif ( $total > 100 ) {
    $total /= 100;
    return sprintf('%0.2f',$total) . ' m';
  } else {
    return $total . ' cm';
  }
}
