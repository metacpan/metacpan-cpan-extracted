#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Crypt::Age');
    use_ok('Crypt::Age::Keys');
    use_ok('Crypt::Age::Primitives');
    use_ok('Crypt::Age::Header');
    use_ok('Crypt::Age::Stanza::X25519');
}

diag("Testing Crypt::Age $Crypt::Age::VERSION");
