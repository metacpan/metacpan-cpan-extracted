#!/usr/bin/env perl
#
# Chat Window - Opens a GUI chat window connected to the hub
#
# Usage:
#   perl examples/chat_hub.pl          # start hub first
#   perl examples/chat_window.pl Alice  # open a window
#   perl examples/chat_window.pl Bob    # open another
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $name = $ARGV[0] || 'User-' . int(rand(9999));

my $app = Chandra::App->new(
    title  => "Chat - $name",
    width  => 420,
    height => 550,
    debug  => 0,
);

$app->bind('send_message', sub {
    my ($text) = @_;
    return unless $text && $text =~ /\S/;
    $app->client->send('msg', { text => $text });
    return 1;
});

my $client = $app->client(name => $name, hub => 'chat');

unless ($client->is_connected) {
    warn "Cannot connect to hub. Start chat_hub.pl first.\n";
    exit 1;
}

$client->on('msg', sub {
    my ($data) = @_;
    my $from = _js_escape($data->{from});
    my $text = _js_escape($data->{text});
    $app->dispatch_eval("addMessage('$from', '$text')");
});

$client->on('system', sub {
    my ($data) = @_;
    my $text = _js_escape($data->{text});
    $app->dispatch_eval("addSystem('$text')");
});

$client->on('users', sub {
    my ($data) = @_;
    my $json = join ',', map { "'" . _js_escape($_) . "'" } @{$data->{list}};
    $app->dispatch_eval("updateUsers([$json])");
});

$client->on('__shutdown', sub {
    $app->dispatch_eval("addSystem('Hub shut down')");
});

sub _js_escape {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r//g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}

$app->set_content(<<"HTML");
<!DOCTYPE html>
<html>
<head>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background: #1a1a2e;
        color: #eee;
        display: flex;
        flex-direction: column;
        height: 100vh;
    }
    #header {
        background: #16213e;
        padding: 10px 16px;
        font-size: 14px;
        border-bottom: 1px solid #0f3460;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    #header .name { color: #e94560; font-weight: 600; }
    #users { color: #888; font-size: 12px; }
    #messages {
        flex: 1;
        overflow-y: auto;
        padding: 12px 16px;
        display: flex;
        flex-direction: column;
        gap: 6px;
    }
    .msg { line-height: 1.4; }
    .msg .author { color: #e94560; font-weight: 600; }
    .msg .author.me { color: #53d8fb; }
    .msg .text { color: #ddd; }
    .system { color: #666; font-size: 12px; font-style: italic; padding: 2px 0; }
    #input-bar {
        display: flex;
        padding: 10px;
        gap: 8px;
        background: #16213e;
        border-top: 1px solid #0f3460;
    }
    #input {
        flex: 1;
        padding: 8px 12px;
        border-radius: 20px;
        border: 1px solid #0f3460;
        background: #1a1a2e;
        color: #eee;
        font-size: 14px;
        outline: none;
    }
    #input:focus { border-color: #e94560; }
    #send-btn {
        padding: 8px 20px;
        border-radius: 20px;
        border: none;
        background: #e94560;
        color: #fff;
        font-size: 14px;
        cursor: pointer;
    }
    #send-btn:hover { background: #c83b54; }
</style>
</head>
<body>
    <div id="header">
        <span>Chat &mdash; <span class="name">$name</span></span>
        <span id="users"></span>
    </div>
    <div id="messages"></div>
    <div id="input-bar">
        <input id="input" type="text" placeholder="Type a message..." autocomplete="off" />
        <button id="send-btn">Send</button>
    </div>
<script>
    var myName = '$name';
    var messagesEl = document.getElementById('messages');
    var inputEl = document.getElementById('input');

    function addMessage(from, text) {
        var div = document.createElement('div');
        div.className = 'msg';
        var authorClass = (from === myName) ? 'author me' : 'author';
        div.innerHTML = '<span class=\"' + authorClass + '\">' + from + ':</span> <span class=\"text\">' + text + '</span>';
        messagesEl.appendChild(div);
        messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    function addSystem(text) {
        var div = document.createElement('div');
        div.className = 'system';
        div.textContent = text;
        messagesEl.appendChild(div);
        messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    function updateUsers(list) {
        document.getElementById('users').textContent = list.length + ' online';
    }

    function doSend() {
        var text = inputEl.value.trim();
        if (!text) return;
        inputEl.value = '';
        window.chandra.invoke('send_message', [text]);
    }

    document.getElementById('send-btn').addEventListener('click', doSend);
    inputEl.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') doSend();
    });

    inputEl.focus();
</script>
</body>
</html>
HTML

$app->run;
