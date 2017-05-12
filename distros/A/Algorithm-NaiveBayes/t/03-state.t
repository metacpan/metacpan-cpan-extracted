
use strict;
use Test;
BEGIN { plan tests => 6 };
use Algorithm::NaiveBayes;
use File::Spec;
ok(1); # If we made it this far, we're loaded.

my $nb = Algorithm::NaiveBayes->new(purge => 0);
ok $nb;

# Populate
$nb->add_instance( attributes => _hash(qw(sheep very valuable farming)),
		   label => 'farming' );
ok $nb->labels, 1;

# Train
$nb->train;

# Save
my $file = File::Spec->catfile('t', 'model.dat');
$nb->save_state($file);
ok -e $file, 1;

# Restore
$nb = Algorithm::NaiveBayes->restore_state($file);
ok $nb;
ok !!$nb->can('predict');


################################################################
sub _hash { +{ map {$_,1} @_ } }
