#!perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use Test::More tests => 22;
use Test::NoWarnings;

use App::SpreadRevolutionaryDate;

@ARGV = ('--test');
my $data_start = tell DATA;
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

isa_ok($spread_revolutionary_date, 'App::SpreadRevolutionaryDate', 'Base class constructor');
isa_ok($spread_revolutionary_date->{config}, 'App::SpreadRevolutionaryDate::Config', 'Config class constructor');

ok($spread_revolutionary_date->{config}->twitter, 'Twitter option set by default');
ok($spread_revolutionary_date->{config}->mastodon, 'Mastodon option set by default');
ok($spread_revolutionary_date->{config}->freenode, 'Freenode option set by default');

is($spread_revolutionary_date->{config}->test, 1, 'Test option set');

is($spread_revolutionary_date->{config}->twitter_consumer_key, 'ConsumerKey', 'Twitter consumer_key value');
is($spread_revolutionary_date->{config}->twitter_consumer_secret, 'ConsumerSecret', 'Twitter consumer_secret value');
is($spread_revolutionary_date->{config}->twitter_access_token, 'AccessToken', 'Twitter access_token value');
is($spread_revolutionary_date->{config}->twitter_access_token_secret, 'AccessTokenSecret', 'Twitter access_token_secret value');

is($spread_revolutionary_date->{config}->mastodon_instance, 'Instance', 'Mastodon instance value');
is($spread_revolutionary_date->{config}->mastodon_client_id, 'ClientId', 'Mastodon client_id value');
is($spread_revolutionary_date->{config}->mastodon_client_secret, 'ClientSecret', 'Mastodon client_secret value');
is($spread_revolutionary_date->{config}->mastodon_access_token, 'AccessToken', 'Mastodon access_token value');

is($spread_revolutionary_date->{config}->freenode_nickname, 'NickName', 'Freenode nickname value');
is($spread_revolutionary_date->{config}->freenode_password, 'Password', 'Freenode password value');
is_deeply($spread_revolutionary_date->{config}->freenode_test_channels, ['#TestChannel1', '#TestChannel2'], 'Freenode test_channels values');
is_deeply($spread_revolutionary_date->{config}->freenode_channels, ['#Channel1', '#Channel2', '#Channel3'], 'Freenode channels values');

push @ARGV, '--twitter';
seek DATA, $data_start, 0;
my $spread_only_to_twitter = App::SpreadRevolutionaryDate->new(\*DATA);
ok($spread_only_to_twitter->{config}->twitter, 'Twitter option explicitely set');
ok(!$spread_only_to_twitter->{config}->mastodon, 'Mastodon option not explicitely set');
ok(!$spread_only_to_twitter->{config}->freenode, 'Freenode option not explicitely set');

__DATA__

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'

[mastodon]
# Get these values from https://<your mastodon instance>/settings/applications
instance        = 'Instance'
client_id       = 'ClientId'
client_secret   = 'ClientSecret'
access_token    = 'AccessToken'

[freenode]
# See https://freenode.net/kb/answer/registration to register
nickname      = 'NickName'
password      = 'Password'
test_channels = '#TestChannel1'
test_channels = '#TestChannel2'
channels      = '#Channel1'
channels      = '#Channel2'
channels      = '#Channel3'
