#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Cwd;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::InterProScanWrapper::External::ParallelInterProScan');
}

my $cwd = getcwd();

ok(my $obj = Bio::InterProScanWrapper::External::ParallelInterProScan->new(
     input_files_path => $cwd.'/t/data/interpro*.seq',
     exec             => $cwd.'/t/bin/dummy_interproscan',
     cpus             => 2,
 ), 'initalise object'
);

is($obj->_cmd, 'nice parallel  -j 2 '.$cwd.'/t/bin/dummy_interproscan -f gff3 --goterms --iprlookup --pathways -i {} --outfile {}.out ::: '.$cwd.'/t/data/interpro*.seq', 'Command constructed as expected');
ok($obj->run, 'run the command to see if the mock is working as expected');

unlink($cwd."/t/data/interpro.seq.out");
unlink($cwd."/t/data/interpro2.seq.out");
unlink($cwd."/t/data/interpro3.seq.out");
unlink($cwd."/t/data/interpro4.seq.out");

done_testing();
