#! perl

use v5.20;
use strict;
use experimental 'signatures', 'declared_refs';


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

        my $result = RESULT_CONTINUE;

        if ( $path eq '{fruit}{apples}[0]' ) {
            $result |= RESULT_REVISIT_CONTENTS
              if $meta->{visit} == 1;
        }
        return $result;
    },
    context => \%context,
);

render_table( $context{rows} );
