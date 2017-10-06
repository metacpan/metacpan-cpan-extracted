use strict;
use warnings;
use Data::Dumper qw( Dumper );
use Path::Tiny qw( path );

my $patch_filename = shift @ARGV;
die "need filename" unless defined $patch_filename;

my($pl_filename) = $patch_filename =~ /^(.*)\.diff$/;
die "unable to determine pl name" unless defined $pl_filename;
$pl_filename .= '.pl';

my @lines = path($patch_filename)->lines;

my $filename;
my %p;

while(@lines)
{
  my $line = shift @lines;
  if($line =~ /^diff --git a\/(.*?)\s/)
  {
    $filename = $1;
    shift @lines for (1..3);
  }
  else
  {
    $p{$filename} .= $line;
  }
}

path($pl_filename)->spew(
  "__DATA__\n my ",
  Dumper(\%p),
);

