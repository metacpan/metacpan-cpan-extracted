#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
}

use Test::More tests => 32;
use Test::NoWarnings;
use Test::Trap;

use App::SpreadRevolutionaryDate;
use FindBin;

my $conf_file = $FindBin::Bin . '/../etc/sample-spread-revolutionary-date.conf';

@ARGV = ('--locale', 'fr', '-c', $conf_file);
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new();

is($spread_revolutionary_date->config->conf, $conf_file, 'Conf option value');
is($spread_revolutionary_date->config->test, 1, 'Test option set');
is($spread_revolutionary_date->config->locale, 'fr', 'Locale option value');

is_deeply($spread_revolutionary_date->config->targets, ['bluesky', 'twitter', 'mastodon', 'freenode', 'liberachat'], 'Default targets options set by default');

ok($spread_revolutionary_date->config->twitter, 'Twitter option set by default');
ok($spread_revolutionary_date->config->mastodon, 'Mastodon option set by default');
ok($spread_revolutionary_date->config->freenode, 'Freenode option set by default');
ok($spread_revolutionary_date->config->liberachat, 'Liberachat option set by default');

is($spread_revolutionary_date->config->twitter_consumer_key, 'ConsumerKey', 'Twitter consumer_key value');
is($spread_revolutionary_date->config->twitter_consumer_secret, 'ConsumerSecret', 'Twitter consumer_secret value');
is($spread_revolutionary_date->config->twitter_access_token, 'AccessToken', 'Twitter access_token value');
is($spread_revolutionary_date->config->twitter_access_token_secret, 'AccessTokenSecret', 'Twitter access_token_secret value');

is($spread_revolutionary_date->config->mastodon_instance, 'Instance', 'Mastodon instance value');
is($spread_revolutionary_date->config->mastodon_client_id, 'ClientId', 'Mastodon client_id value');
is($spread_revolutionary_date->config->mastodon_client_secret, 'ClientSecret', 'Mastodon client_secret value');
is($spread_revolutionary_date->config->mastodon_access_token, 'AccessToken', 'Mastodon access_token value');

is($spread_revolutionary_date->config->freenode_nickname, 'NickName', 'Freenode nickname value');
is($spread_revolutionary_date->config->freenode_password, 'Password', 'Freenode password value');
is_deeply($spread_revolutionary_date->config->freenode_test_channels, ['#TestChannel1', '#TestChannel2'], 'Freenode test_channels values');
is_deeply($spread_revolutionary_date->config->freenode_channels, ['#Channel1', '#Channel2', '#Channel3'], 'Freenode channels values');

is($spread_revolutionary_date->config->liberachat_nickname, 'NickName', 'Liberachat nickname value');
is($spread_revolutionary_date->config->liberachat_password, 'Password', 'Liberachat password value');
is_deeply($spread_revolutionary_date->config->liberachat_test_channels, ['#TestChannel1', '#TestChannel2'], 'Liberachat test_channels values');
is_deeply($spread_revolutionary_date->config->liberachat_channels, ['#Channel1', '#Channel2', '#Channel3'], 'Liberachat channels values');

is($spread_revolutionary_date->config->msgmaker, 'RevolutionaryDate', 'MsgMaker option default value');
is($spread_revolutionary_date->config->locale, 'fr', 'MsgMaker locale option value');
ok(!$spread_revolutionary_date->config->acab, 'MsgMaker acab option value');

@ARGV = ('--version', '--test');
trap { App::SpreadRevolutionaryDate->new };
is($trap->exit, 0, 'Version exit code' );
is($trap->stdout, $App::SpreadRevolutionaryDate::VERSION . "\n", 'Version value' );

@ARGV = ('-?', '-n');
trap { App::SpreadRevolutionaryDate->new };
is($trap->exit, 0, 'Help exit code' );
like($trap->stdout, qr{^Usage:.+<OPTIONS>\n}, 'Help value' );
