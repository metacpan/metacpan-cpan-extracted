#! /usr/bin/perl -w
use strict;

use File::Spec::Functions qw/:DEFAULT devnull/;
use File::Find;

my @to_compile;
BEGIN {
    @to_compile = qw(bin/chk-iban);

    find sub {
        -f or return;
        /\.pm$/ or return;
        push @to_compile, $File::Find::name;
    }, catdir('lib', 'Business');
}

use Test::Simple tests => scalar @to_compile;

my $out = '2>&1';
if (!$ENV{TEST_VERBOSE}) { 
    $out = sprintf "> %s 2>&1", devnull();
}

foreach my $src ( @to_compile ) {
    ok( system( qq{$^X  "-Ilib" "-c" "$src" $out} ) == 0,
        "perl -c '$src'" );
}
