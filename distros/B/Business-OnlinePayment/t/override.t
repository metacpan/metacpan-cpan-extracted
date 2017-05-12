#!/usr/bin/perl -w

use Test::More tests => 2;

{    # fake test driver (with submit method)

    package Business::OnlinePayment::MOCK;
    use strict;
    use warnings;
    use base qw(Business::OnlinePayment);
    sub test_transaction {
        my $self = shift;
        return $self->SUPER::test_transaction(@_);
    }
}

$INC{"Business/OnlinePayment/MOCK.pm"} = "testing";

my $tx = Business::OnlinePayment->new("MOCK");
is eval {
    $tx->test_transaction(1);
    $tx->test_transaction;
}, 1;
is $@, '';
