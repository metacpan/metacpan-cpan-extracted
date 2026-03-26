#! perl

use v5.20;
use strict;
use experimental 'signatures';

use Ref::Util 'is_hashref', 'is_arrayref';
use CXC::Data::Visitor 'visit', -results;

use builtin::compat 'load_module';
use lib::relative q{.};
load_module 'utils';

my %struct = (
    fruit => {
        berry  => 'purple',
        apples => [ 'fuji', 'macoun' ],
    } );

my %context = (
    rows       => [],
    struct_map => {},
);

visit(
    \%struct,
    sub ( $kydx, $vref, $context, $meta ) {
        my $path = render_element( \%struct, $kydx, $vref, $context, $meta );
        return $path eq '{fruit}{apples}'
          ? RESULT_STOP_DESCENT
          : RESULT_CONTINUE;
    },
    context => \%context,
);

render_table( $context{rows} );
