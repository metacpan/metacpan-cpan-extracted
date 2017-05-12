use strict;
use Test::More tests => 6;
use Test::Exception;

use Bot::ChatBots::Auth;

my $auth;
lives_ok { $auth = Bot::ChatBots::Auth->new() } 'constructor lives';

lives_ok { $auth->channels({blacklist => {x => 1}}) } 'channels live';
lives_ok { $auth->users({blacklist => {y => 1}}) } 'users live';

my @retval;

subtest missing => sub {
   @retval = $auth->process({});
   ok !scalar(@retval), 'neither sender nor channel id';

   @retval = $auth->process({sender => {id => 'a'}});
   ok !scalar(@retval), 'no channel id';

   @retval = $auth->process({channel => {id => 'b'}});
   ok !scalar(@retval), 'no sender id';
};

subtest blacklist => sub {
   @retval = $auth->process({sender => {id => 'y'}});
   ok !scalar(@retval), 'user y is blocked (blacklist)';

   @retval =
     $auth->process({sender => {id => 'z'}, channel => {id => 'x'}});
   ok !scalar(@retval), 'user z channel x is blocked (channel blacklist)';

   @retval =
     $auth->process({sender => {id => 'z'}, channel => {id => 'z'}});
   ok scalar(@retval), 'user z channel z goes';
};

subtest whitelist => sub {
   $auth->users({whitelist => {z => 1}});
   $auth->channels({whitelist => {z => 1}});
   @retval = $auth->process({sender => {id => 'y'}});
   ok !scalar(@retval), 'user y is blocked (blacklist)';

   @retval =
     $auth->process({sender => {id => 'z'}, channel => {id => 'x'}});
   ok !scalar(@retval), 'user z channel x is blocked (channel blacklist)';

   @retval =
     $auth->process({sender => {id => 'z'}, channel => {id => 'z'}});
   ok scalar(@retval), 'user z channel z goes';
};

done_testing();
