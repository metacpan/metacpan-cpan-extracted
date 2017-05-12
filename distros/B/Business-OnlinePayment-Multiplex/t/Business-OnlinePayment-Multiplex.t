# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-OnlinePayment-Multiplex.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Business::OnlinePayment') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(my $transaction = new Business::OnlinePayment('Multiplex'),
'new Multiplex object');

my $submit = sub {
    my $self = shift;
    my %content = $self->content;
    undef $content{submit};
    my $tx = new Business::OnlinePayment('StoredTransaction');
    $tx->content(
        %content
    );
    my $submit = $tx->submit;
    $self->is_success($tx->is_success);
    $self->authorization($tx->authorization);
    $self->error_message($tx->error_message);
    $self->result_code($tx->result_code);
    return $submit;
};

my $cardnumber = '1234123412341238';
ok($transaction->content(
    submit => $submit,
    type       => 'Visa',
    amount     => '49.95',
    cardnumber => $cardnumber,
    expiration => '0100',
    action     => 'normal authorization',
    name       => 'John Q Doe',
    password   => '-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAOoKKH0CZm6sWHGg4SygikvvAecDS+Lx6ilUZ8mIVJeV2d6YjEJRjy12
TSFdJTC0SiBDbJ4UHz5ayXhLShK0VvaQY+sfZwMX1SNZNYUyO8T7gY7QCzOrcSTS
CcBBrNWzz0CMWUO5oOIIYevKEimtsDvBtlVaYJArJdwJq9KB/RjRAgMA//8=
-----END RSA PUBLIC KEY-----',
),
, 'add some content');

ok($transaction->submit(),'submit content');
ok($transaction->is_success(), 'it should succeed');
my $auth = $transaction->authorization();
ok($auth, 'should have an auth');
diag($auth);


