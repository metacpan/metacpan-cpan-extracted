#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Data::Dataset::ChordProgressions';

my $file = Data::Dataset::ChordProgressions::as_file();
ok -e $file, 'as_file';

my @data = Data::Dataset::ChordProgressions::as_list();
ok @data, 'as_list has data';
is_deeply $data[0], ['blues','major','12 bar form','C7-C7-C7-C7','I-I-I-I'], 'as_list';

my %data = Data::Dataset::ChordProgressions::as_hash();
ok keys(%data), 'as_hash has data';
is_deeply $data{blues}{major}{'12 bar form'}[0], ['C7-C7-C7-C7','I-I-I-I'], 'as_hash';

done_testing();
