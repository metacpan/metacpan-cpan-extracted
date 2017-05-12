use strict;
use warnings;
use inc::Module::Install;

name 'Acme-Perl-VM';
all_from 'lib/Acme/Perl/VM.pm';

requires 'B';
requires 'Exporter' => 5.57;
requires 'Mouse'    => 0.21;

requires 'MRO::Compat' => 0.09 if $] < 5.010;

test_requires 'Test::More' => 0.62;

tests 't/*.t';
author_tests 'xt';

auto_set_repository;

clean_files q(
    Acme-Perl-VM-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll check_nmake => 0;

