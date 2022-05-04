
use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 5;

use_ok 'MyApp2';

# testing start mode is properly set on sub class
for(1..2){
my $app2 = MyApp2->new;
my $out = $app2->run;
like $out, qr/sub/, "matched $_";
}

# same for error mode
for(1..2) {
    my $app2 = MyApp2->new;
    $app2->mode_param( sub{"arrest"} );
    my $out = $app2->run;
    like $out, qr/oops in MyApp2/;
}

