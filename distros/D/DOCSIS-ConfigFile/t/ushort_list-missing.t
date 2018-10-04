use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw(decode_docsis encode_docsis);

plan skip_all => 'cannot find tos.bin' unless -e 't/data/ushort_list-missing.bin';

my $decoded = eval { decode_docsis \'t/data/ushort_list-missing.bin' };
ok !$@, 'ushort_list() is present in DOCSIS::ConfigFile::Decode' or diag $@;
is_deeply $decoded->{SubMgmtFilters}, [(0) x 10], 'SubMgmtFilters after decode_docsis';

my $bytes = eval { encode_docsis $decoded };
ok !$@, 'ushort_list() is present in DOCSIS::ConfigFile::Encode' or diag $@;

$decoded = eval { decode_docsis $bytes };
ok !$@, 'roundtrip decode_docsis/encode_docsis/decode_docsis';
is_deeply $decoded->{SubMgmtFilters}, [(0) x 10], 'SubMgmtFilters after roundtrip';

done_testing;
