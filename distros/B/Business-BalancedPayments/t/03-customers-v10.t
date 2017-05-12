use Test::Modern;
use t::lib::Common qw(bp_v10 skip_unless_has_secret);

skip_unless_has_secret;

my $bp = bp_v10;

my $cust = $bp->create_customer;
ok ref $cust eq 'HASH', 'Created a customer object';
ok $cust->{id}, 'Created customer has id';

my $get_cust = $bp->get_customer( $cust->{id} );
ok ref $get_cust eq 'HASH', 'Got the customer';
is $get_cust->{id} => $cust->{id}, 'Got correct customer';

done_testing;
