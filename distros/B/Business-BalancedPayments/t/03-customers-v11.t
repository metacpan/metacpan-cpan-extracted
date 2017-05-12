use Test::Modern;
use t::lib::Common qw(bp_v11 skip_unless_has_secret);

skip_unless_has_secret;

my $bp = bp_v11;

my $cust = $bp->create_customer;
ok ref $cust eq 'HASH', 'created a customer with no params';
$cust = $bp->create_customer({ email => 'foo@bar.com' });
is $cust->{email} => 'foo@bar.com';
ok my $cust_id = $cust->{id};

$cust->{email} = 'poo@bar.com';
$cust = $bp->update_customer($cust);
is $cust->{email} => 'poo@bar.com';
is $cust->{id} => $cust_id;

$cust = $bp->get_customer($cust_id);
is $cust->{email} => 'poo@bar.com';

done_testing;
