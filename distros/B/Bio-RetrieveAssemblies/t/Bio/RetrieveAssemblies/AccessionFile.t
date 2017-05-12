#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Slurp::Tiny qw(read_file write_file);
use File::Path qw( remove_tree);

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::RetrieveAssemblies::AccessionFile');
}

ok(
    my $obj = Bio::RetrieveAssemblies::AccessionFile->new(
        _base_url => 't/data/',
        accession => 'CVCD01',
        file_type => 'fasta'
    ),
    'initialise object for fasta'
);
is( $obj->output_filename, 'downloaded_files/CVCD01.1.fsa_nt.gz', 'correct output filename for fasta' );
ok( ! -e 'downloaded_files/CVCD01.1.fsa_nt.gz', 'fasta file doesnt exist' );
ok($obj->download_file, 'download the file');
ok( -e 'downloaded_files/CVCD01.1.fsa_nt.gz', 'fasta file exists' );

ok(
    $obj = Bio::RetrieveAssemblies::AccessionFile->new(
        _base_url => 't/data/',
        accession => 'CVCD01',
        file_type => 'genbank'
    ),
    'initialise object for genbank'
);
is( $obj->output_filename, 'downloaded_files/CVCD01.1.gbff.gz', 'correct output filename for gb' );
ok( ! -e 'downloaded_files/CVCD01.1.gbff.gz', 'genbank file doesnt exist' );
ok($obj->download_file, 'download the file');
ok( -e 'downloaded_files/CVCD01.1.gbff.gz', 'genbank file exists' );

ok(
    $obj = Bio::RetrieveAssemblies::AccessionFile->new(
        _base_url => 't/data/',
        accession => 'CVCD01',
        file_type => 'gff'
    ),
    'initialise object for gff'
);
is( $obj->output_filename, 'downloaded_files/CVCD01.1.gbff.gz.gff', 'correct output filename for gff' );
ok(!  -e 'downloaded_files/CVCD01.1.gbff.gz.gff', 'gff file doesnt exist' );
ok($obj->download_file, 'download the file');
ok( -e 'downloaded_files/CVCD01.1.gbff.gz.gff', 'gff file exists' );
is_deeply( read_file('downloaded_files/CVCD01.1.gbff.gz.gff'), read_file('t/data/expected_CVCD01.1.gbff.gz.gff'), 'gff files match' );

remove_tree('downloaded_files');
done_testing();
