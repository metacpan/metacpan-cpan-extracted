#! perl

use v5.20;
use strict;
use experimental 'signatures';

use Ref::Util 'is_hashref', 'is_arrayref';
use CXC::Data::Visitor 'visit', 'RESULT_CONTINUE';
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
        render_element( \%struct, $kydx, $vref, $context, $meta );
        return RESULT_CONTINUE;
    },
    context => \%context,
);

render_table( $context{rows} );
