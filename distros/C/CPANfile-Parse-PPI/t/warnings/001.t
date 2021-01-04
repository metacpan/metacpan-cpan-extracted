#!/usr/bin/perl

use CPANfile::Parse::PPI;
use Test::More;
use Test::Warn;

my $required = do { local $/; <DATA> };

warning_like 
    { CPANfile::Parse::PPI->new( \$required ) }
    qr/Cannot handle dynamic code/
;

done_testing();

__DATA__
for my $module (qw/
    IO::All
    Zydeco::Lite::App
/) {
    requires $module, '0';
}

