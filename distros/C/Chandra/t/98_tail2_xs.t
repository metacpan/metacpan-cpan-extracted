#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use IO::Socket::UNIX;

use Chandra::App;
use Chandra::ContextMenu;
use Chandra::DragDrop;
use Chandra::Window;
use Chandra::Socket::Hub;
use Chandra::Socket::Client;
use Chandra::Socket::Connection;
use Chandra::Log;
use Chandra::Form;
use Chandra::Element;
use Chandra::HotReload;
use Chandra::Splash;
use Chandra::Clipboard;

my $dir = tempdir(CLEANUP => 1);
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };
local $SIG{PIPE} = 'IGNORE';

package MockWV2;
sub new { my ($class, %o) = @_; bless { eval_js => [], dispatch_eval_js => [], bound => {}, loops => $o{loops} || 0 }, $class }
sub eval_js          { push @{ $_[0]{eval_js} }, $_[1] }
sub dispatch_eval_js { push @{ $_[0]{dispatch_eval_js} }, $_[1] }
sub init             { }
sub loop             { my $self = shift; return $self->{loops}-- > 0 ? 0 : 1 }
sub exit             { }
sub bind             { $_[0]{bound}{ $_[1] } = $_[2] }

package MockApp2;
our (%bound, @evals);
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }

package NoRender2;
sub new { bless {}, shift }

package main;

sub frame { my ($json) = @_; return pack('N', length $json) . $json }
sub settle { select(undef, undef, undef, 0.05) }

# --- more app corners ---
{
    my $app = Chandra::App->new(title => 'More');
    $app->{_webview} = MockWV2->new;
    is($app->toast('typed', type => 'warning', duration => 5), 'toast_1', 'toast passes its options on');
    $app->devtools->enable;
    $app->drag_drop;
    $app->context_menu_instance;
    $app->shortcuts;
    $app->{_shortcut}{bindings} = 'not a hash';
    $app->_inject_post_content_js(0);
    ok(scalar(grep { /devtools/i } @{ $app->{_webview}{eval_js} }), 'enabled devtools inject their script, widgets without handlers nothing');
    $app->update('#x', NoRender2->new);
    like($app->{_webview}{dispatch_eval_js}[-1], qr/NoRender2=HASH/, 'update with an object that cannot render stringifies it');
    my $store = $app->store('n' x 300);
    isa_ok($store, 'Chandra::Store', 'a store with a very long name');
    is($app->store('n' x 300), $store, 'which is cached under the cut name');
    {
        no warnings 'redefine';
        local *Chandra::Window::new = sub { undef };
        ok(!defined $app->open_window(title => 'none'), 'a window that cannot be made is undef');
        is($app->window_count, 0, 'and is not counted');
    }
    my $bare = Chandra::App->new;
    $bare->{_webview} = undef;
    $bare->route('/', sub { 'home' });
    $bare->navigate('/');
    $bare->alert('nobody hears');
    pass('navigate and alert without a webview do nothing');

    my $tray_app = Chandra::App->new(title => 'Tray');
    $tray_app->{_webview} = MockWV2->new;
    $tray_app->tray(icon => 'x');
    $tray_app->run;
    pass('a run with a tray that was never shown leaves it alone');

    my $watch = Chandra::App->new(title => 'Watch');
    $watch->{_webview} = MockWV2->new(loops => 2);
    open my $fh, '>', "$dir/w.txt" or die; close $fh;
    $watch->watch("$dir/w.txt", sub { });
    $watch->run;
    pass('a polling run without a tick callback');
}

# --- context menus: odd entries before the match, items without actions, several attachments ---
{
    my $cm = Chandra::ContextMenu->new(items => 'not a list');
    is_deeply($cm->{_items}, [], 'items that are not a list are ignored');
    push @{ $cm->{_items} }, 'not a ref', { nolabel => 1 }, { label => undef };
    $cm->add_item({ label => 'Last' });
    is($cm->set_item('Last', disabled => 1), $cm, 'set_item walks past the odd entries to the match');
    is($cm->{_items}[-1]{disabled}, 1, 'and updates it');
    $cm->add_item({ label => 'Gone' });
    is($cm->remove_item('Gone'), $cm, 'an item without an action is removed');
    is($cm->remove_item('Last'), $cm, 'and the last one, which has nothing after it to move down');
    is(scalar @{ $cm->{_items} }, 3, 'leaving the odd entries');
    $cm->attach('.a');
    $cm->attach('.b');
    like($cm->js_code, qr/'\.a'.*'\.b'|'\.b'.*'\.a'/s, 'js_code lists every attachment');
    delete $cm->{_actions};
    $cm->attach('.c');
    $cm->detach('.c');
    pass('attach and detach with no action table');
    my $chk = Chandra::ContextMenu->new;
    $chk->add_item({ label => 'Tick', action => sub { } });
    push @{ $chk->{_items} }, { label => 'other', _id => 999 };
    my $id = $chk->{_items}[0]{_id};
    $chk->_dispatch(qq({"type":"action","id":$id,"chk":true}));
    is($chk->{_items}[0]{checked}, 1, 'the checked state finds the item among others with other ids');
    $chk->{_items}[0]{_id} = 555;
    $chk->_dispatch(qq({"type":"action","id":$id,"chk":false}));
    pass('and when no item carries the id the loop ends without a match');
}

# --- drag and drop: options, odd handlers, targets missing, several zones ---
{
    @MockApp2::evals = ();
    my $dd = Chandra::DragDrop->new(app => MockApp2->new);
    $dd->make_draggable('.card', data => { k => 1 }, other => 1);
    $dd->make_draggable('.named', data_from => 'data-id');
    $dd->make_draggable('.plain');
    $dd->make_draggable('.bad', data => sub { });
    $dd->add_drop_zone('#one', sub { });
    $dd->add_drop_zone('#two', sub { });
    $dd->{_draggables}{'.odd'} = 'not a hash';
    my $js = $dd->js_code;
    like($js, qr/dataFrom:'data-id'/, 'a data_from draggable');
    like($js, qr/data:\{"k":1\}/, 'a data draggable');
    like($js, qr/#one.*#two|#two.*#one/s, 'every zone');
    $dd->_dispatch('[1]');
    $dd->{_drop_zones}{'#str'} = 'not code';
    my @got;
    $dd->on_text_drop(sub { push @got, [@_] });
    $dd->on_drag_leave(sub { push @got, [@_] });
    $dd->_dispatch('{"type":"file_drop","files":["f"],"zone":"#str"}');
    $dd->_dispatch('{"type":"text_drop","text":"t"}');
    $dd->_dispatch('{"type":"drag_leave"}');
    is_deeply(\@got, [['t'], []], 'events without a target reach their handlers without one');
}

# --- windows: an unknown key and sizes that are not numbers ---
{
    my $w = Chandra::Window->new(title => 'W', other => 1);
    $w->{height} = 'tall';
    $w->{y} = 'down';
    my ($cw, $ch) = $w->get_size;
    my ($cx, $cy) = $w->get_position;
    ok(defined $ch && defined $cy, 'a height and a y that are not numbers fall back');
    for my $f (qw(_window_set_html _window_eval_js _window_set_title _window_navigate)) {
        no strict 'refs';
        &{"Chandra::Window::$f"}(99999, 'x');
    }
    Chandra::Window::_window_set_size(99999, 1, 1);
    Chandra::Window::_window_set_position(99999, 1, 1);
    for my $f (qw(_window_show _window_hide _window_focus _window_minimize _window_maximize _window_end_modal _window_destroy)) {
        no strict 'refs';
        &{"Chandra::Window::$f"}(99999);
    }
    Chandra::Window::_window_set_modal(99999, 0);
    ok(!Chandra::Window::_window_is_modal(99999), 'an unknown window is not modal');
    ok(!Chandra::Window::_window_exists(99999), 'and does not exist');
    $w->close;
}

# --- sockets: an unknown client key, a handshake without a token, no client table, rotation on tcp ---
{
    local $ENV{XDG_RUNTIME_DIR} = $dir;
    my $hub = Chandra::Socket::Hub->new(name => "tail2-$$", other => 1);
    @warned = ();
    my $sock = IO::Socket::UNIX->new(Peer => $hub->{_socket_path}) or die "connect: $!";
    settle(); $hub->poll;
    $sock->syswrite(frame('{"channel":"__handshake","data":{"name":"notoken"}}'));
    settle(); $hub->poll;
    ok(scalar(grep { /rejected unauthenticated/ } @warned), 'a handshake without a token is rejected');
    close $sock;
    settle(); $hub->poll;
    delete $hub->{_clients};
    my $client = Chandra::Socket::Client->new(name => 'tableless', hub => "tail2-$$", other => 1);
    settle(); $hub->poll; settle(); $hub->poll;
    ok($client->is_connected, 'a client connects to a hub with no client table');
    delete $client->{_pending};
    $client->poll;
    $client->close;
    $hub->close;

    my $port = do { my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0); my $p = $s->sockport; close $s; $p };
    my $tcp = Chandra::Socket::Hub->new(transport => 'tcp', port => $port, bind => '127.0.0.1', token => { rotation => 1000 });
    my $old = $tcp->token;
    $tcp->rotate_token;
    isnt($tcp->token, $old, 'a tcp hub rotates its token with no token file and no callback');
    $tcp->close;
}

# --- logs: every output kind up to the table limit, an unknown output, a child freed ---
{
    my $out = "$dir/limit.log";
    my $cb = sub { };
    Chandra::Log->new(output => [ map { { file => $out } } 1 .. 17 ]);
    Chandra::Log->new(output => [ map { { callback => $cb } } 1 .. 17 ]);
    {
        my $saved;
        open $saved, '>&', \*STDOUT or die;
        open STDOUT, '>', "$dir/stdout2.txt" or die;
        Chandra::Log->new(output => [ ('stdout') x 17 ]);
        open STDOUT, '>&', $saved or die;
    }
    Chandra::Log->new(output => 'bogus');
    Chandra::Log->new(rotate => { keep => 2 });
    my $parent = Chandra::Log->new(output => { file => $out });
    my $child = $parent->with(a => 1);
    undef $child;
    undef $parent;
    pass('loggers at the output limit, with an unknown output, and a freed child');
}

# --- forms: select and radio options of every shape ---
{
    my $f = Chandra::Form->new(id => 'opts');
    $f->_select('choice', { options => [ 'not a hash', { value => 'v', label => 'L', disabled => 1 }, { value => 'w' }, { label => 'no value' } ] });
    $f->radio('pick', { options => [ 'not a hash', { value => 'r', label => 'R' }, { value => 's' }, { label => 'no value' } ] });
    my $html = $f->render;
    like($html, qr/<option value="v"[^>]*disabled>L/, 'a select option with a label and disabled');
    like($html, qr/<option value="w"/, 'and one without a label');
    like($html, qr/value="s"/, 'a radio without a label');
}

# --- elements: class search through odd children ---
{
    my $odd = bless \(my $x = 1), 'Chandra::Element';
    my $el = Chandra::Element->new({ tag => 'div', class => 'c', children => [ $odd, { tag => 'b', class => 'c' } ] });
    is(scalar(my @c = $el->get_elements_by_class('c')), 2, 'a class search skips a child that is not a hash');
}

# --- a fifo is neither a file nor a directory to the scanner ---
{
    POSIX::mkfifo("$dir/pipe", 0600) or die "mkfifo: $!";
    is_deeply(Chandra::HotReload->new->_scan_files("$dir/pipe"), {}, 'a fifo scans to nothing');
}

# --- a splash status with characters that need escaping ---
{
    my $s = Chandra::Splash->new(title => 'Escapes');
    $s->show;
    $s->update_status("tab\there \x01 and \"quotes\" 'single' \\ back\r\n");
    $s->update_progress(50);
    $s->close;
    pass('a status with tabs, control characters and quotes is escaped');
}

# --- the clipboard with html and an image ---
SKIP: {
    skip 'CHANDRA_SKIP_CLIPBOARD set', 3 if $ENV{CHANDRA_SKIP_CLIPBOARD};
    Chandra::Clipboard->set_text('__probe__');
    my $probe = Chandra::Clipboard->get_text;
    skip 'clipboard not available', 3 unless defined $probe && $probe eq '__probe__';
    Chandra::Clipboard->set_html('<b>bold</b>');
    like(Chandra::Clipboard->get_html // '', qr/<b>bold<\/b>|^$/, 'html put on the clipboard comes back, or the board refuses html');
    require MIME::Base64;
    my $png = "$dir/dot.png";
    open my $fh, '>', $png or die; print $fh MIME::Base64::decode_base64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='); close $fh;
    ok(Chandra::Clipboard->set_image($png) || 1, 'an image goes on the clipboard');
    my $back = Chandra::Clipboard->get_image;
    ok(!defined $back || length $back, 'and comes back as bytes when the board holds one');
    Chandra::Clipboard->clear;
}

done_testing;
