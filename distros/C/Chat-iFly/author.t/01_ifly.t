use strict;
use Test::More;
use lib '../lib';
use 5.010;

ok($ENV{IFLY_API_KEY}, 'set "IFLY_API_KEY" environment variable');
use_ok('Chat::iFly');

my $chat = Chat::iFly->new(
    api_key                 => $ENV{IFLY_API_KEY},
    static_asset_base_uri   => 'http://www.example.com/path/to/files',
    ajax_uri                => '/path/to/ajax/method',
);

isa_ok($chat, 'Chat::iFly');

is $chat->init()->{drupalchat}{exurl}, '/path/to/ajax/method', 'generate settings';

ok($chat->render_html =~ m{"exurl":"/path/to/ajax/method"}, 'generate html to embed in page');

ok($chat->fetch_anonymous_name, 'fetch anonymous name');

my $anonymous_user = $chat->generate_anonymous_user;
ok($anonymous_user->{id} =~ m/^0-\d+$/, '0-00000 to represent anonymous ids');
ok($anonymous_user->{name} =~ m/^Guest\s\w+$/, 'Guest Name to represent anonymous names');

my $user_id = $anonymous_user->{id};
ok($chat->render_ajax($anonymous_user) =~ m/$user_id/, 'generate ajax response');

my $key = $chat->get_key($anonymous_user);
ok(exists $key->{key}, 'fetch a key');

$key = $chat->get_key({id => 'xxx', name => 'Admin', is_admin => 1});
ok(exists $key->{key}, 'fetch a key');


done_testing();
