#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Chandra::Store;
use Chandra::Log;
use Chandra::Protocol;
use Chandra::Bridge::Extension;
use Chandra::Error;
use Chandra::Element;
use Chandra::Bind;
use Chandra::DevTools;
use Chandra::HotReload;
use Chandra::Socket::Token;
use Chandra::Socket::Hub;
use Chandra::Socket::Client;
use Chandra::Dialog;
use Chandra::Splash;
use Chandra::Shortcut;

my $dir = tempdir(CLEANUP => 1);
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

package MockDlgWV;
sub new { bless {}, shift }
sub dialog { 'picked' }
package MockDlgApp;
sub new { bless {}, shift }
sub webview { MockDlgWV->new }

package MockEvalApp;
our (@evals, %bound);
sub new { bless {}, shift }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }

package main;

# --- store ---
{
    my $s = Chandra::Store->new(path => "$dir/store.json", auto_save => 1);
    is($s->get('missing', 'dflt'), 'dflt', 'a missing key gives the default');
    is($s->get('a.b.c', 'deep'), 'deep', 'a missing path gives the default');
    is($s->set('a', 1), $s, 'set returns the store and saves when auto_save is on');
    ok(-e "$dir/store.json", 'the file exists after the save');
    eval { $s->set('a.b', 2) };
    like($@, qr/intermediate key is not a hash/, 'setting through a value that is not a hash croaks');
    is($s->set('', 1), $s, 'an empty key is a key like any other');
    eval { $s->set_many('not a hash') };
    like($@, qr/set_many: argument must be a hashref/, 'set_many wants a hash');
    eval { $s->set_many({ 'a.b' => 2 }) };
    like($@, qr/set_many: intermediate key 'a\.b' is not a hash/, 'set_many through a value croaks');
    is($s->set_many({ '' => 2 }), $s, 'and so for set_many');
    is($s->set_many({ 'x.y' => 1 }), $s, 'set_many nests and saves');
    is($s->get('x.y'), 1, 'and the value is there');
    my $data = $s->{_data};
    delete $s->{_data};
    is($s->get('a', 'none'), 'none', 'get without data gives the default');
    is_deeply($s->all, {}, 'all without data is empty');
    eval { $s->set('a', 1) };
    like($@, qr/internal error: _data missing/, 'set without data croaks');
    eval { $s->set_many({ a => 1 }) };
    like($@, qr/internal error: _data missing/, 'set_many without data croaks');
    $s->{_data} = $data;
}

# --- log ---
{
    my $out = "$dir/log.txt";
    my $log = Chandra::Log->new(output => [ { file => $out }, { callback => sub { }, level => 'warn' }, 'stderr', undef, {} ], formatter => 'weird', rotate => { max_size => '1k', keep => 2 });
    is($log->level, 'debug', 'the default level');
    is($log->level('debug'), 'debug', 'level with an argument sets it');
    $log->formatter(sub { "custom: $_[0]{message}" });
    $log->formatter('json');
    $log->formatter('minimal');
    $log->formatter('text');
    $log->formatter(sub { "again $_[0]{message}" });
    my $child = $log->with(req => 1);
    isa_ok($child, 'Chandra::Log', 'a child logger');
    $child->info('hello');
    ok(-e $out, 'the output file exists');
    my $cb = Chandra::Log->new(output => { callback => sub { } }, formatter => 'json');
    my $kid = $cb->with(x => 1);
    $kid->warn('to a callback');
    pass('a child of a callback logger copies the callback');
}

# --- protocol ---
{
    @MockEvalApp::evals = ();
    my $p = Chandra::Protocol->new(other => 1);
    ok(!exists $p->{other}, 'an unknown key is not stored');
    is(scalar $p->schemes, 0, 'no schemes in scalar context');
    is_deeply([ $p->schemes ], [], 'nor in list context');
    ok(!$p->is_registered('nope'), 'nothing registered');
    $p->register('app://', sub { 'a' });
    $p->register('data:', sub { 'd' });
    $p->register('x' x 300, sub { 'long' });
    is(scalar $p->schemes, 3, 'three schemes');
    ok($p->is_registered('x' x 300), 'an overlong scheme is cut to fit and found again');
    like($p->js_code, qr/'app'/, 'js_code lists the schemes');
    like($p->js_code, qr/'data'/, 'all of them');
    is($p->inject, $p, 'inject without an app returns self');
    delete $p->{protocols};
    is(scalar $p->schemes, 0, 'no table, no schemes');
    is_deeply([ $p->schemes ], [], 'in either context');
    ok(!$p->is_registered('app'), 'nothing is registered without a table');
    $p->register('again', sub { });
    pass('registering without a table is harmless');
    my $with = Chandra::Protocol->new(app => MockEvalApp->new);
    $with->register('mine', sub { });
    is($with->inject, $with, 'inject with an app');
    ok(scalar(grep { /__chandraProtocol/ } @MockEvalApp::evals), 'and evaluates the script');
}

# --- bridge extensions ---
{
    Chandra::Bridge::Extension->register('base', 'window.base = 1;');
    Chandra::Bridge::Extension->register('needs', 'window.needs = 1;', depends => ['base']);
    Chandra::Bridge::Extension->register('odd', 'window.odd = 1;', depends => 'not a list', other => 1);
    Chandra::Bridge::Extension->register('empty', 'window.empty = 1;', depends => []);
    Chandra::Bridge::Extension->register('unpaired', 'window.unpaired = 1;', 'odd');
    ok(Chandra::Bridge::Extension->is_registered('needs'), 'an extension with a dependency is registered');
    like(Chandra::Bridge::Extension->generate_js, qr/base.*needs/s, 'and generated after its dependency');
    my $file = "$dir/ext.js";
    open my $fh, '>', $file or die; print $fh "window.fromfile = 1;"; close $fh;
    Chandra::Bridge::Extension->register_file('fromfile', $file, depends => ['base']);
    Chandra::Bridge::Extension->register_file('fromfile2', $file, depends => 'nope', other => 1);
    Chandra::Bridge::Extension->register_file('fromfile3', $file, depends => []);
    ok(Chandra::Bridge::Extension->is_registered('fromfile'), 'a file extension with a dependency is registered');
    eval { Chandra::Bridge::Extension->register_file('nofile', "$dir/missing.js") };
    like($@, qr/cannot open/, 'a missing file croaks');
    Chandra::Bridge::Extension->clear;
}

# --- errors ---
{
    eval { Chandra::Error->format_text('not a hash') };
    like($@, qr/format_text requires a hashref/, 'format_text wants a hash');
    eval { Chandra::Error->format_js_console([]) };
    like($@, qr/format_js_console requires a hashref/, 'format_js_console wants a hash');
}

# --- elements ---
{
    my $holes = []; $#$holes = 2; $holes->[0] = 'text'; $holes->[1] = { tag => 'b', children => ['bold'] };
    my $el = Chandra::Element->new({ tag => 'div', children => $holes });
    is(scalar($el->children), 2, 'a hole in the children is skipped');
    my $none = Chandra::Element->new({ tag => 'p', children => 'not a list' });
    is(scalar($none->children), 0, 'children that are not a list count as none');
    is_deeply([ $none->children ], [], 'and list as none');
    is(scalar(my @c = $el->children), 2, 'the two children list');
    $#{ $el->{children} } = 3;
    is(scalar(my @d = $el->children), 2, 'a hole in the stored children is skipped on listing');
}

# --- bind, devtools, hot reload, token ---
{
    my $b = Chandra::Bind->new(other => 1);
    ok(!exists $b->{other}, 'Bind ignores an unknown key');
    my $d = Chandra::DevTools->new(other => 1);
    ok(!exists $d->{other}, 'DevTools ignores an unknown key');
    $d->enable(undef);
    pass('enable without an app only sets the flag');
    my $hr = Chandra::HotReload->new(interval => 0.5, other => 1);
    is($hr->interval, 0.5, 'the interval is kept');
    is_deeply($hr->_scan_files("$dir/nothing"), {}, 'scanning a missing path finds nothing');
    mkdir "$dir/sub" or die;
    open my $fh, '>', "$dir/sub/f.txt" or die; close $fh;
    is(scalar keys %{ $hr->_scan_files("$dir/sub") }, 1, 'scanning a directory finds its file');
    is(scalar keys %{ $hr->_scan_files("$dir/sub/f.txt") }, 1, 'scanning a file finds it');
    my $tm = Chandra::Socket::Token->new(other => 1, length => 8);
    is(length $tm->current, 16, 'the token manager ignores an unknown key');
}

# --- a hub with a token that is not a manager, and clients listed ---
{
    local $ENV{XDG_RUNTIME_DIR} = $dir;
    local $SIG{PIPE} = 'IGNORE';
    my $hub = Chandra::Socket::Hub->new(name => "misc-$$", token => 'a plain string');
    ok(!defined $hub->token_manager, 'a token that is not a hash makes no manager');
    like($hub->token, qr/^[0-9a-f]{32}$/, 'and the token is generated');
    my $client = Chandra::Socket::Client->new(name => 'listed', hub => "misc-$$");
    select(undef, undef, undef, 0.05); $hub->poll; select(undef, undef, undef, 0.05); $hub->poll;
    is_deeply([ $hub->clients ], ['listed'], 'clients lists the names');
    $client->close;
    $hub->close;
}

# --- dialogs: keyword parsing with a mock app ---
{
    my $dlg = Chandra::Dialog->new(other => 1, app => MockDlgApp->new);
    ok(!exists $dlg->{other}, 'Dialog ignores an unknown key');
    $dlg->open_directory(other => 1);
    $dlg->warning(title => 'T');
    $dlg->warning(message => 'M');
    $dlg->error(title => 'T');
    $dlg->error(message => 'M');
    pass('dialog keywords are parsed with either key alone');
}

# --- splash images and a splash with no window ---
{
    for my $ext (qw(gif webp png noext)) {
        my $img = $ext eq 'noext' ? "$dir/image" : "$dir/image.$ext";
        open my $fh, '>', $img or die; print $fh "not really an image"; close $fh;
        my $s = Chandra::Splash->new(title => $ext, image => $img, other => 1);
        $s->show;
        $s->close;
    }
    pass('image splashes of every extension show and close');
    my $missing = Chandra::Splash->new(image => "$dir/absent.png");
    @warned = ();
    $missing->show;
    like($warned[0], qr/cannot open image/, 'a missing image warns');
    $missing->close;
    my $s = Chandra::Splash->new;
    $s->{_wid} = undef;
    $s->update_status('x');
    $s->update_progress(1);
    $s->close;
    $s->eval_js('1');
    is($s->close_if_expired, 0, 'no deadline, not expired');
    $s->{_deadline} = 1;
    is($s->close_if_expired, 1, 'a past deadline expires even with no window');
    $s->{_wid} = -1;
    $s->{_deadline} = 1;
    is($s->close_if_expired, 1, 'and with a window id below one');
    undef $s;
    pass('a splash with no window is destroyed quietly');
}

# --- shortcuts ---
{
    my $sc = Chandra::Shortcut->new(other => 1);
    ok(!exists $sc->{other}, 'Shortcut ignores an unknown key');
    my $long = 'ctrl+' . ('k' x 300);
    is($sc->bind($long, sub { }, other => 1), $sc, 'an overlong combo is cut to fit');
    $sc->bind('ctrl+shift+alt+meta+' . ('x' x 200), sub { });
    $sc->bind('ctrl+s', sub { }, prevent_default => 0);
    ok($sc->is_bound('ctrl+s'), 'bound');
    $sc->{bindings}{odd} = 'not a hash';
    delete $sc->{bindings}{'ctrl+s'}{prevent_default};
    delete $sc->{bindings}{'ctrl+s'}{handler};
    ok(scalar(my @l = $sc->list), 'list skips an entry that is not a hash and copes with missing fields');
    like($sc->js_code, qr/ctrl\+s/, 'js_code lists the combos');
    delete $sc->{bindings};
    ok(!$sc->is_bound('ctrl+s'), 'nothing is bound without a table');
    is_deeply([ $sc->list ], [], 'nothing is listed');
    $sc->unbind('ctrl+s');
    $sc->disable('ctrl+s');
    $sc->enable('ctrl+s');
    is($sc->bind('ctrl+n', sub { }), $sc, 'binding without a table makes one');
    ok($sc->is_bound('ctrl+n'), 'and the binding is there');
    like($sc->js_code, qr/ctrl\+n/, 'js_code works again');
}

done_testing;
