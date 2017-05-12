use strict;
use warnings;
use File::Copy qw( move );
use File::Spec;
use File::Basename qw( basename );

# very basic and probably incomplete implementation of
# UNIX mv written in perl to be used on MSWin32 if it
# can't be found in the path.

my $interactive = 0;

while($ARGV[0] && $ARGV[0] =~ /^-/)
{
  my $arg = shift @ARGV;
  last if $arg eq '--';
  if($arg =~ /^--/)
  {
    print STDERR "unknown switch: $arg\n";
    exit 1;
  }
  my @switches = split //, $arg;
  shift @switches;
  foreach my $switch (@switches)
  {
    if($switch eq 'i')
    { $interactive = 1 }
    elsif($switch eq 'f')
    { $interactive = 0 }
    else
    {
      print STDERR "unknown switch: -$switch\n";
    }
  }
}

my $dest = pop @ARGV;
my @src  = @ARGV;

unless(defined $dest && @src > 0)
{
  print STDERR "usage: $0 [-i] [-f] source1 [ source2 [ ... ] ] dest\n";
  exit 1;
}

if(@src > 1 && ! -d $dest)
{
  print STDERR "if multiple source arguments are given then the destination must be a directory\n";
  exit 1;
}

foreach my $src (@src)
{
  my $fn_dest = $dest;
  $fn_dest = File::Spec->catfile($dest, basename $src) if -d $dest;
  if($interactive && -e $fn_dest)
  {
    print "mv: Overwrite '$fn_dest'? ";
    my $answer = <STDIN>;
    next unless $answer =~ /^y/i;
  }
  move($src, $fn_dest) or die "move failed: $!";
}
