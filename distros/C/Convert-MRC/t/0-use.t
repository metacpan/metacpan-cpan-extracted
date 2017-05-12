#test that the module is loaded properly

use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Convert::MRC', 'use' );
is( ref( Convert::MRC->new ) => 'Convert::MRC', 'class' );

__END__
