use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

require_ok( 'Data::Processor' );
my $processor = Data::Processor->new();
isa_ok( $processor, 'Data::Processor', '$processor' );

can_ok( $processor, 'new' );
can_ok( $processor, 'validate' );
can_ok( $processor, 'transform_data' );
can_ok( $processor, 'make_data' );
can_ok( $processor, 'pod_write' );




done_testing;
