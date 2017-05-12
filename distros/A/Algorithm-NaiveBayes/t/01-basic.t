
use strict;
use Test;
BEGIN { plan tests => 13 };
use Algorithm::NaiveBayes;
ok(1); # If we made it this far, we're loaded.

my $nb = Algorithm::NaiveBayes->new(purge => 0);
ok $nb;

# Populate
$nb->add_instance( attributes => _hash(qw(sheep very valuable farming)),
		   label => 'farming' );
ok $nb->labels, 1;

$nb->add_instance( attributes => _hash(qw(farming requires many kinds animals)),
		   label => ['farming'] );
ok $nb->labels, 1;

$nb->add_instance( attributes => _hash(qw(vampires drink blood vampires may staked)),
		   label => ['vampire'] );
ok $nb->labels, 2;

$nb->add_instance( attributes => _hash(qw(vampires cannot see their images mirrors)),
		   label => ['vampire'] );
ok $nb->labels, 2;

# Train
$nb->train;

ok $nb->purge, 0;

# Predict
my $h = $nb->predict( attributes => _hash(qw(i would like to begin farming sheep)) );
ok $h;
ok $h->{farming} > 0.5;
ok $h->{vampire} < 0.5;

$h = $nb->predict( attributes => _hash(qw(i see that many vampires may have eaten my beautiful daughter's blood)) );
ok $h;
ok $h->{farming} < 0.5;
ok $h->{vampire} > 0.5;

################################################################
sub _hash { +{ map {$_,1} @_ } }
