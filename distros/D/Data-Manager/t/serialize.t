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

my $ser = $dm->freeze({ format => 'JSON' });
ok(defined($ser), 'serialized');

my $thawed = Data::Manager->thaw($ser, { format => 'JSON' });

my $results = $thawed->get_results('name1');
isa_ok($results, 'Data::Verifier::Results');
ok(!$results->success, 'verification did not succeed');

my $stack = $thawed->messages_for_scope('name1');
isa_ok($stack, 'Message::Stack');
cmp_ok($stack->count, '==', 1, '1 message');

done_testing;