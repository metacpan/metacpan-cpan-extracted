#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Pipeline::Comparison::Generate::VCFWriter');
}

ok( my $obj = Bio::Pipeline::Comparison::Generate::VCFWriter->new( output_filename => 'my_snps.vcf.gz' ),
    'Initialise VCF writer' );
ok( $obj->add_snp( 1234, 'T', 'A' ), 'Add a SNP' );
ok( $obj->add_snp( 1345,  'T', 'C' ), 'Add another SNP' );
ok( $obj->create_file(), 'Write the VCF file' );
ok( ( -e 'my_snps.vcf.gz' ), 'Output file exists' );
ok( ( -e 'my_snps.vcf.gz.tbi' ), 'Indexed output file exists' );
is( 'my_snps', $obj->evolved_name, 'reasonable default name' );

unlink('my_snps.vcf.gz');
unlink('my_snps.vcf.gz.tbi');
done_testing();
