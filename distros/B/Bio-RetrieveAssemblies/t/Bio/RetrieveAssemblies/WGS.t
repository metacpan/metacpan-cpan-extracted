#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Slurp::Tiny qw(read_file write_file);

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::RetrieveAssemblies::WGS');
    use Bio::RetrieveAssemblies::RefWeak;
}
my $refweak_accessions = Bio::RetrieveAssemblies::RefWeak->new( url => 't/data/small_refweak.tsv' )->accessions;

ok(
    my $obj = Bio::RetrieveAssemblies::WGS->new(
        url                 => 't/data/small_wgs.tsv',
        search_term         => 'Salmonella',
        _refweak_accessions => $refweak_accessions
    ),
    'initialise object'
);

is( 1, $obj->_filter_out_line( [ 'AAA', 'INV', 'BBB', 'CCC', 'DDD', 'EEE', 'FFF', 'GGG' ] ), 'line thats not a bacteria filtered out' );
is( 0, $obj->_filter_out_line( [ 'AAA', 'BCT', 'BBB', 'CCC', 'Salmonella', 'EEE', 'FFF', 'GGG' ] ), 'line with search term included' );
is(
    0,
    $obj->_filter_out_line( [ 'AAA', 'BCT', 'BBB', 'CCC', 'SALMONELLA TYPHI', 'EEE', 'FFF', 'GGG' ] ),
    'line with search term in upper case and with extra string included'
);

is_deeply( $obj->accessions, { CVCD01 => 1, CFDG01 => 1, CVCH01 => 1 }, 'got the accessions' );

done_testing();
