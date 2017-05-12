use strict;
use warnings;
use 5.010;
use Path::Class qw( file );

my $corpus  = file(__FILE__)->parent->absolute;

#say "% @ARGV";

while(defined $ARGV[0] && $ARGV[0] =~ /^-/)
{
  if($ARGV[0] eq '-o')
  {
    # ignore -o
    shift @ARGV;
    shift @ARGV;
  }
  elsif($ARGV[0] eq '-l')
  {
    shift @ARGV;
    $ENV{USER} = shift @ARGV;
  }
  elsif($ARGV[0] eq '-T')
  {
    shift @ARGV;
  }
  else
  {
    die "unknown option $ARGV[0]";
  }
}

while(defined $ARGV[0] && $ARGV[0] eq '-o')
{
  shift @ARGV;
  shift @ARGV;
}

$ENV{CLAD_HOST} = shift @ARGV;
exec @ARGV;
