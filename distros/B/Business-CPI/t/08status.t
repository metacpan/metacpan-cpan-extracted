#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Business::CPI::Base::Status;
use Test::Exception;
use Test::More;

my $status;

throws_ok {
    $status = Business::CPI::Base::Status->new();
} qr/missing/i, q{it's missing required attributes};

throws_ok {
    $status = Business::CPI::Base::Status->new(is_success => 0, is_in_progress => 0, is_reverted => 0);
} qr/missing.*gateway_name/i, q{it's missing required gateway_name};

throws_ok {
    $status = Business::CPI::Base::Status->new(is_success => 0, is_in_progress => 0, gateway_name => 'xxx');
} qr/missing.*is_reverted/i, q{it's missing required is_reverted};

throws_ok {
    $status = Business::CPI::Base::Status->new(is_success => 0, is_reverted => 0, gateway_name => 'xxx');
} qr/missing.*is_in_progress/i, q{it's missing required is_in_progress};

throws_ok {
    $status = Business::CPI::Base::Status->new(is_in_progress => 0, is_reverted => 0, gateway_name => 'xxx');
} qr/missing.*is_success/i, q{it's missing required is_success};

lives_ok {
    $status = Business::CPI::Base::Status->new(
        is_success     => 1,
        is_in_progress => 0,
        is_reverted    => 0,
        gateway_name   => 'xxx'
    );
} q{it lives!};

is( $status->is_success,     1,     q{success is 1} );
is( $status->is_in_progress, 0,     q{in_progress is 0} );
is( $status->is_reverted,    0,     q{reverted is 0} );
is( $status->gateway_name,   'xxx', q{gateway_name is xxx} );

done_testing;
