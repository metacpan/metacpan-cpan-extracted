#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 3 + 4*4 - 1;

use_ok('Data::Identifier');
use_ok('Data::Identifier::Generate');
use_ok('Math::BigInt');

foreach my $i (-1 .. 2) {
    my $identifier;
    my $icontext;
    my $mbi;

    diag('Testing for: '.$i);

    $identifier = Data::Identifier::Generate->integer($i);
    isa_ok($identifier, 'Data::Identifier');

    $icontext = $identifier->icontext(default => undef, no_defaults => 1);
    unless ($i == 0) {
        # We skip $i == 0, see source of Data::Identifier::Generate for details.
        ok(defined($icontext) && length($icontext) == 1, 'Has valid icontext');
    }


    $mbi = $identifier->as('Math::BigInt');
    isa_ok($mbi, 'Math::BigInt');
    ok($mbi->beq($i), 'Correct value');
}

exit 0;
