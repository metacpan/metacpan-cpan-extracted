
use strict;
use vars qw($TODO);
use Test::More tests => 4;
BEGIN { use_ok('Algorithm::SVMLight') };

use File::Spec;

#########################

my $s = new Algorithm::SVMLight(type => 3);
$s->add_instance_i( 1, "My Document", [3,9], [2.7, 1234]);
$s->add_instance_i(-1, "My Document2", [3,5,7], [0.7, -1234, 3.5]);
$s->add_instance_i( 1, "My Document3", [3,5,9], [0.2, -1234, 3.5]);

# Try a fake ranking callback
my $i = 0;
$s->ranking_callback( sub {$i++} );

$s->train;
ok $s->is_trained, "Train model";
is $i, 3, "\$i should be updated during training";

# Try a fake ranking callback
$i = 0;
$s->ranking_callback( sub {my($r1, $r2) = @_; $_= abs($r1-$r2); $i += $_; $_} );
$s->train;
is $i, 4;
