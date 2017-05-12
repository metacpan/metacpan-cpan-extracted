use strict;
use warnings;
use Acme::CPANAuthors;

my $authors  = Acme::CPANAuthors->new('POE');

my $number   = $authors->count;
my @ids      = $authors->id;
my @distros  = $authors->distributions("BINGOS");
my $url      = $authors->avatar_url("BINGOS");
my $kwalitee = $authors->kwalitee("BINGOS");
my $name     = $authors->name("BINGOS");
