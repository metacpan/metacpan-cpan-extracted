#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

{
    my @info;

    lives_ok (sub {
            @info = Crypt::GpgME->get_engine_info;
    }, 'get engine info as class method');

    ok ((grep { $_->{protocol} =~ /OpenPGP/ } @info), 'engine info looks sane');
}

{
    my $ctx = Crypt::GpgME->new;
    isa_ok ($ctx, 'Crypt::GpgME');

    my @info;

    lives_ok (sub {
            @info = $ctx->get_engine_info;
    }, 'get engine info as instance method');

    ok ((grep { $_->{protocol} =~ /OpenPGP/ } @info), 'engine info looks sane');
}
