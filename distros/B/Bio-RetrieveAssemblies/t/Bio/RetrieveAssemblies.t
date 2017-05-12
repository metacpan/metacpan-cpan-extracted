#!/usr/bin/env perl
use Moose;
use Data::Dumper;
use File::Slurp::Tiny qw(read_file write_file);
use Cwd;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

BEGIN {
    use Test::Most;
    use_ok('Bio::RetrieveAssemblies');
}
my $script_name = 'Bio::RetrieveAssemblies';

my %scripts_and_expected_files = (
    '-q Mycobacterium PRJEB8877'           => 'downloaded_files/CVMX01.1.gbff.gz',
    '-q Mycobacterium -f gff PRJEB8877'    => 'downloaded_files/CVMX01.1.gbff.gz.gff',
    '-q Mycobacterium -a -f gff PRJEB8877' => 'downloaded_files/CVMX01.1.gbff.gz.gff',
    '-q Mycobacterium -f fasta PRJEB8877'  => 'downloaded_files/CVMX01.1.fsa_nt.gz',
    '-q Mycobacterium -o my_dir PRJEB8877' => 'my_dir/CVMX01.1.gbff.gz',
);

mock_execute_script( $script_name, \%scripts_and_expected_files );

done_testing();
