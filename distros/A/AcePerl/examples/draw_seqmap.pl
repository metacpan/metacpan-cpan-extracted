#!/usr/bin/perl

use strict;
use lib '.';
use Ace::Graphics::Panel;
use Ace::Graphics::Fk;

unshift @ARGV,'exons.txt' unless @ARGV;

my (%features,@all_features);
while (<>) {
  chomp;
  next if /^\#/;
  chomp;
  my ($glyph,$id,$segments) = split(/\s+/,$_,3);
  my @segments;
  while ($segments =~ /(\d+)\s+(\d+)/g) {
    push @segments,[$1,$2];
  }
  next unless @segments;
  my $feature = Ace::Graphics::Fk->new(-segments => \@segments,
				       -name     => $id,
				       -strand   => $segments[-1][1] <=> $segments[0][0]);
  push @{$features{$glyph}},$feature;
  push @all_features,$feature;
}

# find range of features
my $start = (sort {$a->start<=>$b->start} @all_features)[0]->start;
my $stop  = (sort {$a->stop<=>$b->stop}   @all_features)[-1]->stop;
my $fudge = int(($stop - $start) * 0.01);
my $ruler = Ace::Graphics::Fk->new(-start=>$start-$fudge,-stop=>$stop+$fudge);

my $panel = Ace::Graphics::Panel->new(
				      -segment => $ruler,
				      -width  => 880,
				     );

$panel->add_track($ruler,'arrow',-bump => 0,-tick=>2);

for my $glyph (keys %features) {
  my @features = @{$features{$glyph}};

  $panel->add_track(\@features =>  $glyph,
		    -fillcolor =>  'green',
		    -fgcolor   =>  'black',
		    -bump      =>  +1,
		    -height    => 10,
		    -connect   => 1,
		    -label     => 1,
		   );
}
print $panel->png;


