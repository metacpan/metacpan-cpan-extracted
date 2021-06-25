#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test2::V0;
use Test2::Tools::Exception;

use Crypt::OpenToken;

###############################################################################
# TEST: invalid cipher
invalid_cipher: {
    my $password = 'dummy password';
    my $data     = { 'foo' => 'bar' };
    my $factory = Crypt::OpenToken->new(password => $password);
    like dies { $factory->create(9999, $data) }, qr/unsupported OTK cipher; '9999'/;
}

###############################################################################
done_testing();
