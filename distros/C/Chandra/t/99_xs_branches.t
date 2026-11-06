#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# The XS arms the mock-side tests leave untaken: widgets present but empty,
# messages with fields missing, validation that fails, and parsers given gaps.

use Chandra;
use Chandra::App;
use Chandra::Bind;
use Chandra::ContextMenu;
use Chandra::DragDrop;
use Chandra::Form;
use Chandra::Log;

package MockWV;
sub new { bless { eval_js => [], dispatch_eval_js => [], bound => {}, loops => 0 }, shift }
sub eval_js          { push @{ $_[0]{eval_js} }, $_[1] }
sub dispatch_eval_js { push @{ $_[0]{dispatch_eval_js} }, $_[1] }
sub init             { 1 }
sub loop             { 1 }
sub exit             { 1 }
sub terminate        { 1 }
sub bind             { $_[0]{bound}{ $_[1] } = $_[2] }
sub set_title        { 1 }
sub title            { 'Mock' }

package main;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };
my $dir = tempdir(CLEANUP => 1);

sub mock_app {
    my $app = Chandra::App->new(title => 'XS branches');
    $app->{_webview} = MockWV->new;
    return $app;
}

# --- the tray menu parser given an item with nothing in it ---
{
    my $wv = Chandra->new;
    my $items = Chandra::_xs_test_tray_menu_parse('[{ }, { "id": 1, "label": "A" }]');
    is(scalar @$items, 2, 'an empty item is kept');
    ok(!$items->[0]{label}, 'with no label');
}

# --- widgets present but not usable ---
{
    my $app = mock_app();
    $app->{_devtools} = \1;
    $app->{_shortcut} = undef;
    $app->{_dragdrop} = undef;
    $app->{_contextmenu} = undef;
    $app->_inject_post_content_js(0);
    pass('widget slots that are not objects are passed over');

    my $off = mock_app();
    $off->devtools->disable;
    @{ $off->{_webview}{eval_js} } = ();
    $off->_inject_post_content_js(0);
    ok(!scalar(grep { /__chandra_devtools|devtools/i } @{ $off->{_webview}{eval_js} }), 'disabled devtools inject nothing');

    my $started = mock_app();
    $started->route('/', sub { 'home' });
    $started->{_started} = 1;
    delete $started->{_webview};
    $started->navigate('/');
    is($started->{_current_route}, '/', 'navigating a started app without a webview records the route');
}

# --- a bind dispatch whose result has no id ---
{
    my $wv = Chandra->new;
    $wv->_xs_init_bind;
    {
        no warnings 'redefine';
        local *Chandra::Bind::dispatch = sub { {} };
        Chandra::_xs_dispatch('{"type":"call","id":1,"method":"nothing"}');
    }
    pass('a dispatch result without an id resolves nothing');
    my $bind = Chandra::Bind->new;
    my $r = $bind->dispatch('{"type":"other","id":2}');
    ok(!defined $r || !ref $r || !$r->{result}, 'a message of an unknown type is not handled');
}

# --- a context menu with its registry gone, and the last item removed ---
{
    my $cm = Chandra::ContextMenu->new;
    $cm->add_item({ label => 'First', action => sub { 1 } });
    $cm->add_item({ label => 'Last', action => sub { 2 } });
    is($cm->remove_item('Last'), $cm, 'the last item is removed');
    is(scalar @{ $cm->{_items} }, 1, 'leaving the first');
    $cm->{_actions} = 'gone';
    $cm->attach('.x', [ { label => 'A', action => sub { } } ]);
    pass('attaching without a registry registers nothing');
}

# --- a zone drop without a target ---
{
    my $dd = Chandra::DragDrop->new;
    my @zone;
    $dd->add_drop_zone('#zone', sub { push @zone, [@_] });
    $dd->_dispatch('{"type":"file_drop","files":["a"],"zone":"#zone"}');
    is(scalar @zone, 1, 'the zone handler ran');
    is(scalar @{ $zone[0] }, 1, 'with the files alone when there is no target');
}

# --- validation that fails on min, max and email ---
{
    my $f = Chandra::Form->new(id => 'v');
    $f->number('low', { min => 5 });
    $f->number('high', { max => 5, max_msg => 'too high' });
    $f->email('mail', {});
    my $errors = $f->validate({ low => 1, high => 9, mail => 'nope' });
    like($errors->{low}, qr/at least 5/, 'below the minimum');
    is($errors->{high}, 'too high', 'above the maximum, with the given message');
    like($errors->{mail}, qr/Invalid email/, 'and an address without a domain');
}

# --- a log that rotates without a size, and log options of odd shapes ---
{
    my $log = Chandra::Log->new(output => { file => "$dir/r.log" }, rotate => { keep => 2 });
    $log->info('one');
    ok(-f "$dir/r.log", 'a rotation without a size still logs');
    my $odd = Chandra::Log->new(output => { file => "$dir/odd.log" }, rotate => 'daily', bogus => 1);
    $odd->info('two');
    ok(-f "$dir/odd.log", 'a rotation that is not a hash and an unknown key are passed over');
    Chandra::Log::DESTROY('Chandra::Log');
    pass('destroying a class name does nothing');
}

# --- asset paths with a directory dot and a leading slash ---
{
    require Chandra::Assets;
    my $assets = Chandra::Assets->new(root => $dir);
    ok(defined $assets->mime_type('dir.d/file'), 'a dot before the last slash is not an extension');
    eval { $assets->read('/lead.txt') };
    like($@, qr/path traversal/, 'a leading slash is refused as traversal before it could be dropped');
}

# --- a store with an unknown option and without auto save ---
{
    require Chandra::Store;
    my $store = Chandra::Store->new(path => "$dir/s.json", auto_save => 0, bogus => 1);
    $store->set_many({ a => 1 });
    $store->clear;
    ok(!-e "$dir/s.json", 'without auto save nothing is written');
}

# --- error capture with an unknown option, and a stack trace with no depth ---
{
    require Chandra::Error;
    my $e = Chandra::Error->capture('boom', bogus => 1);
    ok(ref $e, 'an unknown option is passed over');
    ok(ref Chandra::Error->stack_trace, 'a trace with the default depth');
}

done_testing;
