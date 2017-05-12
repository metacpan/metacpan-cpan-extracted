use strict;

use Test::More;

use Data::Manager;
use Data::Verifier;

my $dm = Data::Manager->new;

my $verifier = Data::Verifier->new(
    profile => {
        name_first => {
            required => 1,
            type => 'Str'
        },
        name_last => {
            required => 1,
            type => 'Str'
        }
    }
);

$dm->set_verifier('name1', $verifier);
ok(defined($dm->get_verifier('name1')), 'get_verifier');

$dm->verify('name1', { name_first => 'Cory' });

my $results = $dm->get_results('name1');
isa_ok($results, 'Data::Verifier::Results');
ok(!$results->success, 'verification did not succeed');

my $stack = $dm->messages_for_scope('name1');
isa_ok($stack, 'Message::Stack');
cmp_ok($stack->count, '==', 1, '1 message');

ok(!$dm->success, 'verification did not succeed');

{
    my $dm2 = Data::Manager->new;
    $dm2->set_verifier('name1', $verifier);
    $dm2->verify('name1', { name_first => 'Cory', name_last => 'Watson' });
    ok($dm2->success, 'successful');

    $dm2->set_verifier('name2', $verifier);
    $dm2->verify('name2', { name_first => 'Cory' });
    ok(!$dm2->success, 'not successful');
}

done_testing;