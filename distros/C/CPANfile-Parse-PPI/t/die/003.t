#!/usr/bin/perl

use CPANfile::Parse::PPI -strict;
use Test::More;
use Test::Exception;

my $required = do { local $/; <DATA> };

throws_ok 
    { CPANfile::Parse::PPI->new( \$required ) }
    qr/Cannot handle dynamic code/
;

done_testing();

__DATA__
for my $module (qw/
    IO::All
    Zydeco::Lite::App
/) {
    requires "$module", '0';
}

