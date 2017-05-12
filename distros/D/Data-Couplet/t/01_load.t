
use strict;
use warnings;

use Test::More;
use Test::Moose;

my $t = 0;

require Data::Couplet;

++$t;
meta_ok('Data::Couplet');

++$t;
can_ok( 'Data::Couplet', qw( value value_at values keys key_at key_object set unset move_up move_down ) );

++$t;
isa_ok( 'Data::Couplet', 'Data::Couplet::Private' );

done_testing($t);
