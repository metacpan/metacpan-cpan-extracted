#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Data::Dataset::ChordProgressions', qw(as_file as_list as_hash transpose);

my $file = as_file();
ok -e $file, 'as_file';

my @data = as_list();
ok @data, 'as_list has data';
is_deeply $data[0], ['blues','major','12 bar form','C7-C7-C7-C7','I-I-I-I'], 'as_list';

my %data = as_hash();
ok keys(%data), 'as_hash has data';
is_deeply $data{blues}{major}{'12 bar form'}[0], ['C7-C7-C7-C7','I-I-I-I'], 'as_hash';

my $named = transpose('A', 'major', 'C-F-Am-F');
is $named, 'A-D-F#m-D', 'transpose';

done_testing();
