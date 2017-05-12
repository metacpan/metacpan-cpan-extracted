use strict;
use warnings;
use Test::More;
use Business::OnlinePayment;

my $client1 = new_ok( 'Business::OnlinePayment' => [ 'PaperlessTrans' ] );

isa_ok $client1, 'Business::OnlinePayment::PaperlessTrans';
can_ok $client1, 'submit';
can_ok $client1, 'content';

done_testing;
