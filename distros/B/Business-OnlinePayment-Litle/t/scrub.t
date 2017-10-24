#!/usr/bin/perl -w
#
use strict;
use warnings;

use Test::More qw(no_plan);
use Log::Scrubber qw(scrubber);

## grab info from the ENV
my @opts = ('default_Origin' => 'RECURRING' );

use_ok 'Business::OnlinePayment';
use_ok 'Business::OnlinePayment::Litle';

my $scrubber_good = sub {
    my $cc = shift;
    $cc =~ /^(.*?)(.{4})$/;
    return ('X'x(length($1))) . $2;
};

my $card = '1234567891234567';
my $expect_default = '123456XXXXXX4567';
my $expect_custom  = 'XXXXXXXXXXXX4567';


is( Business::OnlinePayment::Litle::_default_scrubber($card), $expect_default, 'default scrubber - bare' );
is( &{$scrubber_good}($card), $expect_custom, 'custom scrubber - bare' );

my $tx = Business::OnlinePayment->new("Litle", @opts);
is( &{$tx->{_scrubber}}($card), $expect_default, 'default scrubber - installed' );

$tx = Business::OnlinePayment->new("Litle", default_Scrubber => undef);
is( &{$tx->{_scrubber}}($card), $expect_default, 'default scrubber - bad install attempt' );

$tx = Business::OnlinePayment->new("Litle", default_Scrubber => $scrubber_good );
is( &{$tx->{_scrubber}}($card), $expect_custom, 'custom scrubber - installed' );

$tx = Business::OnlinePayment->new("Litle", @opts);
$tx->_litle_scrubber_add_card($card);
is( scrubber($card), &{$tx->{_scrubber}}($card), 'scrubber is used properly' );
