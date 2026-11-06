#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::ContextMenu;

# A mock app records every eval and bind the menu asks of it.
package MockCMApp;
our (@evals, %bound);
sub new { bless {}, shift }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }

package CMDies;
our @ISA = ('Chandra::ContextMenu');
sub _dispatch { die "dispatch died\n" }

package main;

# --- new keeps a given mode, and ignores an unknown key ---
{
    my $cm = Chandra::ContextMenu->new(app => MockCMApp->new, mode => 'native', other => 1);
    is($cm->{mode}, 'native', 'a given mode is kept');
    ok(!exists $cm->{other}, 'an unknown key is not stored');
    is(Chandra::ContextMenu->new->{mode}, 'html', 'the default mode is html');
}

# --- attach: no selector, a static one, a dynamic one ---
{
    my $cm = Chandra::ContextMenu->new;
    eval { $cm->attach(undef) };
    like($@, qr/attach\(\) requires a CSS selector string/, 'attach without a selector croaks');
    $cm->attach('.static');
    $cm->attach('.dynamic', sub { [] });
    $cm->attach('.plain', 'not code');
    is($cm->{_attachments}{'.static'}, 1, 'a static attachment is marked with 1');
    is(ref $cm->{_attachments}{'.dynamic'}, 'CODE', 'a dynamic attachment keeps its code');
    is($cm->{_attachments}{'.plain'}, 1, 'a callback that is not code is a static attachment');
}

# --- set_item, add_item and remove_item with odd items ---
{
    my $cm = Chandra::ContextMenu->new;
    eval { $cm->set_item(undef, label => 'x') };
    like($@, qr/set_item\(\) requires a label/, 'set_item without a label croaks');
    eval { $cm->add_item('not a hash') };
    like($@, qr/add_item\(\) requires a hashref/, 'add_item without a hash croaks');
    $cm->add_item({ label => 'Cut', action => sub { 'cut' } });
    push @{ $cm->{_items} }, 'not a hash', { nolabel => 1 }, { label => undef };
    is($cm->set_item('Cut', disabled => 1), $cm, 'set_item skips items that are not hashes or have no label');
    is($cm->{_items}[0]{disabled}, 1, 'and updates the one that matches');
    is($cm->remove_item('Cut'), $cm, 'remove_item skips the same oddities');
    is(scalar @{ $cm->{_items} }, 3, 'and removes the match');
}

# --- _dispatch: events that are not objects, or have no type ---
{
    my $cm = Chandra::ContextMenu->new;
    $cm->_dispatch('"just a string"');
    $cm->_dispatch('[1,2]');
    $cm->_dispatch('{"notype":1}');
    $cm->_dispatch('{"type":null}');
    $cm->_dispatch('{"type":"unknown"}');
    pass('events that are not objects, or have no type, are ignored');
}

# --- _dispatch: an action with a checked state walks items that are not hashes ---
{
    my $cm = Chandra::ContextMenu->new;
    my @got;
    push @{ $cm->{_items} }, 'not a hash';
    $cm->add_item({ label => 'Tick', checkable => 1, action => sub { push @got, @_ } });
    my $id = $cm->{_items}[1]{_id};
    $cm->_dispatch(qq({"type":"action","id":$id,"chk":true}));
    is($cm->{_items}[1]{checked}, 1, 'the checked state reaches the item past the one that is not a hash');
    is_deeply(\@got, [1], 'and the action gets the state');
    $cm->_dispatch(qq({"type":"action","id":999,"chk":true}));
    $cm->_dispatch(qq({"type":"action","id":null}));
    is(scalar @got, 1, 'an unknown or null id runs nothing');
}

# --- _dispatch: a context menu request, static ---
{
    @MockCMApp::evals = ();
    my $cm = Chandra::ContextMenu->new(app => MockCMApp->new);
    $cm->_dispatch('{"type":"contextmenu","x":10,"y":20}');
    is($MockCMApp::evals[-1], 'window.__chandraCtxShow(10,20);', 'a static request shows the menu where asked');
    $cm->_dispatch('{"type":"contextmenu"}');
    is($MockCMApp::evals[-1], 'window.__chandraCtxShow(0,0);', 'missing coordinates are zero');
    $cm->_dispatch('{"type":"contextmenu","target":"string"}');
    $cm->_dispatch('{"type":"contextmenu","target":{"nosel":1}}');
    $cm->_dispatch('{"type":"contextmenu","target":{"sel":""}}');
    $cm->_dispatch('{"type":"contextmenu","target":{"sel":".unknown"}}');
    $cm->attach('.static');
    $cm->_dispatch('{"type":"contextmenu","target":{"sel":".static"}}');
    is(scalar @MockCMApp::evals, 7, 'a target that is not a hash, has no selector, an empty one, an unknown one or a static one all show the static menu');
    my $quiet = Chandra::ContextMenu->new;
    $quiet->_dispatch('{"type":"contextmenu","x":1,"y":1}');
    is(scalar @MockCMApp::evals, 7, 'with no app nothing is evaluated');
}

# --- _dispatch: a context menu request with dynamic items ---
{
    @MockCMApp::evals = ();
    my $cm = Chandra::ContextMenu->new(app => MockCMApp->new);
    my @seen;
    $cm->attach('.dyn', sub { push @seen, $_[0]; return [ { label => 'Dyn', action => sub { 'd' } }, { separator => 1 } ] });
    $cm->_dispatch('{"type":"contextmenu","x":5,"y":6,"target":{"sel":".dyn","tag":"li"}}');
    is(scalar @seen, 1, 'the dynamic callback ran with the target');
    is($seen[0]{tag}, 'li', 'and saw it whole');
    like($MockCMApp::evals[-1], qr/^window\.__chandraCtxShow\(5,6,\[.*Dyn.*\]\);$/, 'the dynamic items are shown');
    ok(scalar(grep { ref $_ eq 'CODE' } values %{ $cm->{_actions} }), 'the dynamic action is registered');

    $cm->attach_global(sub { return 'not an array' });
    $cm->_dispatch('{"type":"contextmenu","target":{"sel":".none"}}');
    is(scalar @MockCMApp::evals, 1, 'a global callback that returns no array shows nothing');
    $cm->attach_global(sub { return });
    $cm->_dispatch('{"type":"contextmenu","target":null}');
    is(scalar @MockCMApp::evals, 1, 'nor does one that returns nothing, with a null target');

    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    $cm->attach_global(sub { die "dyn boom\n" });
    $cm->_dispatch('{"type":"contextmenu"}');
    like($warned[0], qr/ContextMenu dynamic callback error: dyn boom/, 'a dying callback warns');

    my $noapp = Chandra::ContextMenu->new;
    $noapp->attach_global(sub { [ { label => 'x' } ] });
    $noapp->_dispatch('{"type":"contextmenu"}');
    is(scalar @MockCMApp::evals, 1, 'dynamic items with no app evaluate nothing');
}

# --- inject: binds the bridge, evaluates the JS, and only once ---
{
    @MockCMApp::evals = ();
    %MockCMApp::bound = ();
    my $app = MockCMApp->new;
    my $cm = Chandra::ContextMenu->new(app => $app);
    is($cm->inject, $cm, 'inject returns self');
    is(ref $MockCMApp::bound{__chandraContextMenuBridge}, 'CODE', 'the bridge is bound');
    is(scalar @MockCMApp::evals, 1, 'the JS is evaluated once');
    is($cm->inject, $cm, 'a second inject returns self');
    is(scalar @MockCMApp::evals, 1, 'and evaluates nothing more');

    my $bridge = $MockCMApp::bound{__chandraContextMenuBridge};
    my @got;
    $cm->add_item({ label => 'Go', action => sub { push @got, 'go' } });
    my $id = $cm->{_items}[0]{_id};
    is($bridge->(qq({"type":"action","id":$id})), undef, 'the bridge returns undef');
    is_deeply(\@got, ['go'], 'and dispatched the action');
    is($bridge->(), undef, 'the bridge with no argument dispatches nothing');
    undef $cm;
    is($bridge->('{"type":"action"}'), undef, 'after the menu is gone the bridge does nothing');

    my $again = Chandra::ContextMenu->new(app => $app);
    $again->{_dispatch_bound} = 1;
    $again->inject;
    is(scalar @MockCMApp::evals, 2, 'with the bridge already bound only the JS is evaluated');

    my $noapp = Chandra::ContextMenu->new;
    is($noapp->inject, $noapp, 'inject without an app returns self');
}

# --- a dispatch that dies inside the bridge is a warning ---
{
    %MockCMApp::bound = ();
    my $cm = CMDies->new(app => MockCMApp->new);
    $cm->inject;
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    $MockCMApp::bound{__chandraContextMenuBridge}->('{}');
    like($warned[0], qr/ContextMenu dispatch error: dispatch died/, 'the bridge warns when the dispatch dies');
}

done_testing;
