#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util ();

use Chandra::DragDrop;

package MockDDApp;
our (@evals, %bound);
sub new { bless {}, shift }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }

package DDDies;
our @ISA = ('Chandra::DragDrop');
sub _dispatch { die "dispatch died\n" }

package main;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

# --- new with an app and an unknown key ---
{
    my $app = MockDDApp->new;
    my $dd = Chandra::DragDrop->new(app => $app, other => 1);
    is($dd->{app}, $app, 'the app is kept');
    ok(!exists $dd->{other}, 'an unknown key is not stored');
}

# --- handlers that are not code ---
{
    my $dd = Chandra::DragDrop->new;
    eval { $dd->on_drag_leave('nope') };
    like($@, qr/on_drag_leave\(\) requires a coderef/, 'on_drag_leave wants code');
    eval { $dd->on_internal_drop([]) };
    like($@, qr/on_internal_drop\(\) requires a coderef/, 'on_internal_drop wants code');
}

# --- events that go nowhere ---
{
    my $dd = Chandra::DragDrop->new;
    $dd->on_file_drop(sub { fail('no files, no call') });
    $dd->_dispatch('"a string"');
    $dd->_dispatch('{"notype":1}');
    $dd->_dispatch('{"type":"file_drop"}');
    $dd->_dispatch('{"type":"file_drop","files":"not a list"}');
    $dd->_dispatch('{"type":"other"}');
    pass('a string, a typeless event, a file drop without files or with files that are not a list are ignored');
}

# --- every handler that dies warns, and the drop goes on ---
{
    @warned = ();
    my $dd = Chandra::DragDrop->new;
    $dd->add_drop_zone('#zone', sub { die "zone boom\n" });
    $dd->on_file_drop(sub { die "file boom\n" });
    $dd->on_text_drop(sub { die "text boom\n" });
    $dd->on_drag_enter(sub { die "enter boom\n" });
    $dd->on_drag_leave(sub { die "leave boom\n" });
    $dd->on_internal_drop(sub { die "internal boom\n" });
    $dd->_dispatch('{"type":"file_drop","files":["a"],"zone":"#zone","target":{"id":"t"}}');
    $dd->_dispatch('{"type":"text_drop","text":"hi","target":{"id":"t"}}');
    $dd->_dispatch('{"type":"drag_enter","target":{"id":"t"}}');
    $dd->_dispatch('{"type":"drag_leave","target":{"id":"t"}}');
    $dd->_dispatch('{"type":"internal_drop","data":"d","source":"s","target":"t"}');
    is_deeply([ map { /^DragDrop (\w+) handler error: (\w+ boom)/ ? "$1:$2" : $_ } @warned ],
        [ 'zone:zone boom', 'file_drop:file boom', 'text_drop:text boom', 'drag_enter:enter boom', 'drag_leave:leave boom', 'internal_drop:internal boom' ],
        'each handler error is a warning naming the handler');
}

# --- drag_enter feedback reaches the app when there is a target id ---
{
    @MockDDApp::evals = ();
    my $dd = Chandra::DragDrop->new(app => MockDDApp->new);
    $dd->on_drag_enter(sub { 'hover' });
    $dd->_dispatch('{"type":"drag_enter","target":{"id":"box"}}');
    is($MockDDApp::evals[-1], "var _el=document.getElementById('box');if(_el)_el.classList.add('hover');", 'the class is added to the target by id');
    $dd->_dispatch('{"type":"drag_enter","target":{"id":null}}');
    $dd->_dispatch('{"type":"drag_enter","target":{"noid":1}}');
    $dd->_dispatch('{"type":"drag_enter","target":"string"}');
    $dd->_dispatch('{"type":"drag_enter"}');
    is(scalar @MockDDApp::evals, 1, 'no id, a target that is not a hash, or no target adds nothing');
    $dd->on_drag_enter(sub { undef });
    $dd->_dispatch('{"type":"drag_enter","target":{"id":"box"}}');
    is(scalar @MockDDApp::evals, 1, 'a handler returning undef adds nothing');
    my $noapp = Chandra::DragDrop->new;
    $noapp->on_drag_enter(sub { 'hover' });
    $noapp->_dispatch('{"type":"drag_enter","target":{"id":"box"}}');
    is(scalar @MockDDApp::evals, 1, 'and without an app nothing is evaluated');
}

# --- internal_drop fills missing parts with undef ---
{
    my $dd = Chandra::DragDrop->new;
    my @got;
    $dd->on_internal_drop(sub { @got = @_ });
    $dd->_dispatch('{"type":"internal_drop"}');
    is(scalar @got, 3, 'three arguments');
    ok(!grep({ defined } @got), 'all undef when the event has none');
}

# --- inject ---
{
    @MockDDApp::evals = ();
    %MockDDApp::bound = ();
    my $app = MockDDApp->new;
    my $dd = Chandra::DragDrop->new(app => $app);
    is($dd->inject, $dd, 'inject returns self');
    is(ref $MockDDApp::bound{__chandra_dragdrop}, 'CODE', 'the bridge is bound');
    is(scalar @MockDDApp::evals, 1, 'the JS is evaluated');
    is($dd->inject, $dd, 'a second inject returns self');
    is(scalar @MockDDApp::evals, 1, 'and evaluates nothing more');

    my $bridge = $MockDDApp::bound{__chandra_dragdrop};
    my @files;
    $dd->on_file_drop(sub { @files = @{ $_[0] } });
    is($bridge->('{"type":"file_drop","files":["x.txt"]}'), undef, 'the bridge returns undef');
    is_deeply(\@files, ['x.txt'], 'and dispatched the drop');
    is($bridge->(), undef, 'with no argument it dispatches nothing');
    Scalar::Util::weaken(my $gone = $dd);
    undef $dd;
    SKIP: {
        skip 'a coverage runner can keep the object alive past its last reference', 2 if $gone;
        is($bridge->('{"type":"file_drop","files":["y"]}'), undef, 'after the object is gone it does nothing');
        is_deeply(\@files, ['x.txt'], 'and the handler did not run');
    }

    my $again = Chandra::DragDrop->new(app => $app);
    $again->{_dispatch_bound} = 1;
    $again->inject;
    is(scalar @MockDDApp::evals, 2, 'with the bridge already bound only the JS is evaluated');

    my $noapp = Chandra::DragDrop->new;
    is($noapp->inject, $noapp, 'inject without an app returns self');
}

# --- a dispatch that dies inside the bridge is a warning ---
{
    %MockDDApp::bound = ();
    my $dd = DDDies->new(app => MockDDApp->new);
    $dd->inject;
    @warned = ();
    $MockDDApp::bound{__chandra_dragdrop}->('{}');
    like($warned[0], qr/DragDrop dispatch error: dispatch died/, 'the bridge warns when the dispatch dies');
}

done_testing;
