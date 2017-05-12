#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Validate::UUID qw( is_uuid );

use Readonly;
Readonly my $VALID_UUID   => '91AE3596-95FA-11E4-AB6C-6CFF01D6B4DB';
Readonly my $INVALID_UUID => 'INVALID UUID';

subtest 'Check Valid UUID' => sub {
    ok( is_uuid( $VALID_UUID ), 'Correctly identifies Valid UUID' );
};

subtest 'Check Invalid UUID' => sub {
    ok( !is_uuid( $INVALID_UUID ), 'Correctly identifies Invalid UUID' );
};

done_testing;
