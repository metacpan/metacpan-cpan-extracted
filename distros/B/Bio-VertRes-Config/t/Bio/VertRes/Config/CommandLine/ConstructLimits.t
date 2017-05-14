#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::CommandLine::ConstructLimits');
}

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'study',
        input_id   => "study name",
        species    => undef
      )->limits_hash,
    { project => ['study name'] },
    'Study with name and no species'
);

## This runs over a live database so probably best to remove it
#is_deeply(
#    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
#        input_type => 'study',
#        input_id   => "8",
#        species    => undef
#      )->limits_hash,
#    { project => ['Test BAC'] },
#    'Study with ssid and no species'
#);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'sample',
        input_id   => "sample name",
        species    => undef
      )->limits_hash,
    { sample => ['sample name'] },
    'Sample with name and no species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'library',
        input_id   => "library name",
        species    => undef
      )->limits_hash,
    { library => ['library name'] },
    'Library with name and no species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'lane',
        input_id   => '1234_5#6',
        species    => undef
      )->limits_hash,
    { lane => ['1234_5#6'] },
    'Lane with name (tag) and no species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'lane',
        input_id   => '1234_5',
        species    => undef
      )->limits_hash,
    { lane => ['1234_5(#.+)?'] },
    'Lane with name (no tag) and no species'
);


is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'lane',
        input_id   => 'a_strange_lane_name',
        species    => undef
      )->limits_hash,
    { lane => ['a_strange_lane_name'] },
    'Lane with non standard name and no species'
);




is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'study',
        input_id   => "study name",
        species    => 'a species'
      )->limits_hash,
    { project => ['study name'], species => ['a species'] },
    'Study with name and species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'sample',
        input_id   => "sample name",
        species    => 'a species'
      )->limits_hash,
    { sample => ['sample name'], species => ['a species'] },
    'Sample with name and species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'library',
        input_id   => "library name",
        species    => 'a species'
      )->limits_hash,
    { library => ['library name'], species => ['a species'] },
    'Library with name and species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'lane',
        input_id   => '1234_5#6',
        species    => 'a species'
      )->limits_hash,
    { lane => ['1234_5#6'], species => ['a species'] },
    'Lane with name and species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'lane',
        input_id   => 'a_strange_lane_name',
        species    => 'a species'
      )->limits_hash,
    { lane => ['a_strange_lane_name'], species => ['a species'] },
    'Lane with non standard name and species'
);

is_deeply(
    Bio::VertRes::Config::CommandLine::ConstructLimits->new(
        input_type => 'file',
        input_id   => 't/data/constructlimits_lanes',
      )->limits_hash,
    { lane => ['123_4#5', '678_9(#.+)?'] },
    'Lanes from file'
);

throws_ok(
    sub {
        Bio::VertRes::Config::CommandLine::ConstructLimits->new(
            input_type => 'invalid type',
            input_id   => 'something',
            species    => undef
          )->limits_hash;
    },
    qr/Invalid type/,
    'Invalid type throws an error'
);

done_testing();

