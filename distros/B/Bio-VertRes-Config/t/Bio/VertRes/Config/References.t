#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::References');
}

throws_ok(
    sub {
        Bio::VertRes::Config::References->new( reference_lookup_file => 'file_which_doesnt_exist' )
          ->_reference_names_to_files;
    },
    qr/Validation failed/,
    'Initialise file which doesnt exist'
);

ok( ( my $obj = Bio::VertRes::Config::References->new( reference_lookup_file => 't/data/refs.index' ) ),
    'initialise valid object' );

is( $obj->get_reference_location_on_disk('EFG_v2'), '/path/to/EFG_HIJ_v2.fa', 'return location for given reference' );

is_deeply($obj->available_references, ['ABC','EFG_v2','Some_other_ABC_reference'], 'list available references');

is_deeply($obj->search_for_references('EFG'),['EFG_v2'] , 'search for all matching references, one returned');
is_deeply($obj->search_for_references('ABC'),['ABC','Some_other_ABC_reference'] , 'search for all matching references, two returned');

is($obj->is_reference_name_valid('EFG_v2'), 1, 'valid reference');
is($obj->is_reference_name_valid('Invalid Reference'), 0, 'invalid reference');
is($obj->is_reference_name_valid('A'), 0, 'partial invalid reference');

done_testing();
