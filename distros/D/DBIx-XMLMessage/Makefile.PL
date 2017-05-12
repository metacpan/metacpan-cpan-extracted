#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'DBIx::XMLMessage',
    'VERSION_FROM'  => 'XMLMessage.pm', # finds $VERSION
    'PREREQ_PM'     => { 'DBI' => "1.00", 'XML::Parser' => "2.23" },
    'dist'          => {'COMPRESS' => 'gzip', suffix => 'gz' },
);