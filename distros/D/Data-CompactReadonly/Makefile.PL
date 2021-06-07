#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

# 32 bit ints aren't supported (that's 0xffffffffffffffff)
die("OS unsupported\n") if(~0 < 18446744073709551615);
use 5.8.9;

WriteMakefile(
  NAME         => 'Data::CompactReadonly',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Data-CompactReadonly',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Data-CompactReadonly/issues'
        }
    },
  VERSION_FROM => 'lib/Data/CompactReadonly.pm',
  PREREQ_PM    => {
    'Data::IEEE754'                 => 0, # cant use pack's d> because that uses *native* format
    'Devel::StackTrace'             => 0,
    'File::Temp'                    => 0,
    'Scalar::Type'                  => '0.1.1',
    'Scalar::Util'                  => 0,
    'String::Binary::Interpolation' => 0,
    'Test::Differences'             => 0,
    'Test::Exception'               => 0,
    'Test::More'                    => '0.96', # done_testing and subtests
  },
);
