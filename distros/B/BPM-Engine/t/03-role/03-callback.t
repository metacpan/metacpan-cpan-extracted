use strict;
use warnings;
use Test::More;
use Test::Exception;

{
package WCall;
use Moose;
with 'BPM::Engine::Role::WithCallback';
}

package main;

ok(my $wc = WCall->new(callback => sub { $_[0] ? 'welcome' : 'goodbye' }));

is($wc->call_callback(1), 'welcome');
is($wc->call_callback(0), 'goodbye');

done_testing();
