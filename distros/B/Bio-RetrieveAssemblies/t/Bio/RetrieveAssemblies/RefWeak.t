#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Slurp::Tiny qw(read_file write_file);

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::RetrieveAssemblies::RefWeak');
}

ok(my $obj = Bio::RetrieveAssemblies::RefWeak->new(url => 't/data/small_refweak.tsv'), 'initialise object');
is_deeply($obj->accessions, {CFAX01 => 1, CFEQ01 => 1}, 'got the accessions');


done_testing();