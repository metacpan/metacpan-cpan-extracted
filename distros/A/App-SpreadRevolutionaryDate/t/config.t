#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2026 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use utf8;

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
}
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 42;
use Test::NoWarnings;

use App::SpreadRevolutionaryDate;

@ARGV = ('--test');
my $data_start = tell DATA;
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

isa_ok($spread_revolutionary_date, 'App::SpreadRevolutionaryDate', 'Base class constructor');
isa_ok($spread_revolutionary_date->config, 'App::SpreadRevolutionaryDate::Config', 'Config class constructor');

is($spread_revolutionary_date->config->test, 1, 'Test option set');
is($spread_revolutionary_date->config->locale, 'fr', 'Locale option value');

is_deeply($spread_revolutionary_date->config->targets, ['bluesky', 'twitter', 'mastodon', 'freenode', 'liberachat'], 'Default targets options set by default');

ok($spread_revolutionary_date->config->bluesky, 'Bluesky option set by default');
ok($spread_revolutionary_date->config->twitter, 'Twitter option set by default');
ok($spread_revolutionary_date->config->mastodon, 'Mastodon option set by default');
ok($spread_revolutionary_date->config->freenode, 'Freenode option set by default');

is($spread_revolutionary_date->config->bluesky_identifier, 'Identifier', 'Bluesky identifier value');
is($spread_revolutionary_date->config->bluesky_password, 'Password', 'Bluesky password value');

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

is($spread_revolutionary_date->config->msgmaker, 'RevolutionaryDate', 'MsgMaker option default value');
is($spread_revolutionary_date->config->locale, 'fr', 'MsgMaker locale option value');
ok(!$spread_revolutionary_date->config->acab, 'MsgMaker acab option value');

@ARGV = ('--twitter', '--test');
seek DATA, $data_start, 0;
my $spread_only_to_twitter = App::SpreadRevolutionaryDate->new(\*DATA);
is_deeply($spread_only_to_twitter->config->targets, ['twitter'], 'Targets options set');
ok($spread_only_to_twitter->config->twitter, 'Twitter option explicitely set');
ok(!$spread_only_to_twitter->config->mastodon, 'Mastodon option not explicitely set');
ok(!$spread_only_to_twitter->config->freenode, 'Freenode option not explicitely set');

@ARGV  = ('--targets=freenode', '--test', '-ftc', '#TestOnlyMe');
seek DATA, $data_start, 0;
my $spread_freenode = App::SpreadRevolutionaryDate->new(\*DATA);
is_deeply($spread_freenode->config->freenode_test_channels, ['#TestOnlyMe'], 'Freenode multivalued test_channels option overridden by command line argument');


@ARGV  = ('--msgmaker=Gemini', '--test');
seek DATA, $data_start, 0;
eval { my $spread_gemini_no_process = App::SpreadRevolutionaryDate->new(\*DATA); };
chomp $@;
like($@, qr/Attribute \(process\) does not pass the type constraint because: Validation failed for 'Str' with value undef at constructor App::SpreadRevolutionaryDate::MsgMaker::Gemini::new/, 'Gemini without process option');

@ARGV  = ('--msgmaker=Gemini', '--test', '--gemini_process=NoPrompt');
seek DATA, $data_start, 0;
eval { my $spread_gemini_no_prompt = App::SpreadRevolutionaryDate->new(\*DATA); };
chomp $@;
like($@, qr/Process NoPrompt has no prompt/, 'Gemini without process option');

@ARGV  = ('--msgmaker=Gemini', '--test', '--gemini_process=AnniversairePeople');
seek DATA, $data_start, 0;
my $spread_gemini = App::SpreadRevolutionaryDate->new(\*DATA);
is($spread_gemini->config->gemini_process, 'AnniversairePeople', 'Gemini process option value');
my @gemini_prompt_keys = sort keys %{$spread_gemini->config->gemini_prompt};
is_deeply(\@gemini_prompt_keys, ['AnniversairePeople', 'MacronJokeColuche'], 'Gemini prompt option keys');
like($spread_gemini->config->gemini_prompt->{AnniversairePeople}, qr/^Quelles sont les personalit.s ayant leurs anniversaire le /, 'Gemini promt option value');
ok($spread_gemini->config->gemini_search->{MacronJokeColuche}, 'Gemini search set');
ok(!$spread_gemini->config->gemini_search->{AnniversairePeople}, 'Gemini search unset');
is($spread_gemini->config->gemini_img_path->{MacronJokeColuche}, '~/Images/coluche_macron.png', 'Gemini img path');
is($spread_gemini->config->gemini_img_url->{MacronJokeColuche}, 'https://upload.wikimedia.org/wikipedia/commons/3/38/Emmanuel_Macron_-_Caricature_%2840366024295%29.jpg', 'Gemini img url');
is($spread_gemini->config->gemini_img_alt->{MacronJokeColuche}, 'Caricature de Coluche disant : « C’est l’histoire d’un mec… » avec une caricature de macron', 'Gemini img alt');
__DATA__

[bluesky]
# Get these values from https://bsky.app/
identifier = 'Identifier'
password   = 'Password'

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

[liberachat]
# See https://libera.chat/guides/registration to register
nickname      = 'NickName'
password      = 'Password'
test_channels = '#TestChannel1'
test_channels = '#TestChannel2'
channels      = '#Channel1'
channels      = '#Channel2'
channels      = '#Channel3'

[Gemini]
api_key                    = APIKEY
prompt AnniversairePeople  = "Quelles sont les personalités ayant leurs anniversaire le $day $month ? Donne une liste d'au maximum 6 personnes, puis après la liste donne l'URL sans formattage de la fiche wikipédia d'une seule d'entre elles, ne commente pas et pas besoin d'introduction."
prompt MacronJokeColuche   = "Je veux envoyer chaque jour une blague différente sur les réseaux sociaux Mastodon et Bluesky. La blague doit être chaque fois suffisamment différente, toujours dans le style de Coluche et toujours sur Emmanuel Macron. Invente moi une et une seule blague pour cette fois. Pas besoin de dire \"D'accord, voici une blague ou Bien sûr, voici une blague dans le style de Coluche sur Emmanuel Macron\" avant la blague."
search MacronJokeColuche   = 1
img_path MacronJokeColuche = '~/Images/coluche_macron.png'
img_url MacronJokeColuche  = 'https://upload.wikimedia.org/wikipedia/commons/3/38/Emmanuel_Macron_-_Caricature_%2840366024295%29.jpg'
img_alt MacronJokeColuche  = 'Caricature de Coluche disant : « C’est l’histoire d’un mec… » avec une caricature de macron'
