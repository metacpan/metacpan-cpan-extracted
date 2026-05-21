#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 20;

BEGIN { use_ok('Chandra::Component') }

# ── Test 1: Basic component creation ──────────────────────

{
    package TestBasic;
    use Object::Proto;
    BEGIN {
        Object::Proto::define('TestBasic',
            extends => 'Chandra::Component',
            'title:Str:default(Hello)',
        );
        Object::Proto::import_accessors('TestBasic');
    }
    sub render {
        my ($self) = @_;
        return '<div><h1>' . $self->title . '</h1></div>';
    }
}

package main;

Chandra::Component->reset;

my $comp = TestBasic->new(title => 'Test');
ok($comp, 'component created');
isa_ok($comp, 'TestBasic');
isa_ok($comp, 'Chandra::Component');
is($comp->title, 'Test', 'custom property works');

# ── Test 2: Render ────────────────────────────────────────

my $html = $comp->render;
like($html, qr/<h1>Test<\/h1>/, 'render produces HTML');

# ── Test 3: Component ID ─────────────────────────────────

my $cid = $comp->_cid;
ok($cid, 'component has an ID');
like($cid, qr/^_comp_\d+$/, 'component ID format correct');

# ── Test 4: Registry lookup ──────────────────────────────

my $found = Chandra::Component->find_component($cid);
is($found, $comp, 'find_component returns correct component');

# ── Test 5: Multiple components get unique IDs ───────────

my $comp2 = TestBasic->new(title => 'Second');
isnt($comp->_cid, $comp2->_cid, 'components have unique IDs');

# ── Test 6: _wrap_render adds data-action binding ────────

{
    package TestActions;
    use Object::Proto;
    BEGIN {
        Object::Proto::define('TestActions',
            extends => 'Chandra::Component',
            'count:Int:default(0)',
        );
        Object::Proto::import_accessors('TestActions');
    }
    sub render {
        return '<div><button data-action="increment">+</button></div>';
    }
    sub on_increment { $_[0]->count($_[0]->count + 1) }
}

package main;

my $action_comp = TestActions->new;
my $wrapped = $action_comp->_wrap_render;
like($wrapped, qr/onclick=/, 'data-action rewritten to onclick');
like($wrapped, qr/_comp_action_/, 'onclick calls component action handler');
unlike($wrapped, qr/data-action/, 'data-action attribute removed');

# ── Test 7: Child composition ────────────────────────────

my $parent = TestBasic->new(title => 'Parent');
my $child1 = TestBasic->new(title => 'Child1');
my $child2 = TestBasic->new(title => 'Child2');

$parent->child($child1);
$parent->child($child2);

my @children = @{$parent->_children};
is(scalar @children, 2, 'parent has 2 children');
is($children[0], $child1, 'first child correct');
is($children[1], $child2, 'second child correct');

# ── Test 8: render_children ──────────────────────────────

my $children_html = $parent->render_children;
like($children_html, qr/Child1/, 'render_children includes first child');
like($children_html, qr/Child2/, 'render_children includes second child');

# ── Test 9: Reset ────────────────────────────────────────

Chandra::Component->reset;
my $not_found = Chandra::Component->find_component($cid);
ok(!$not_found, 'reset clears registry');

# ── Test 10: data-action with parameters ─────────────────

{
    package TestParamActions;
    use Object::Proto;
    BEGIN {
        Object::Proto::define('TestParamActions',
            extends => 'Chandra::Component',
        );
    }
    sub render {
        return '<div><button data-action="select:42:blue">Pick</button></div>';
    }
}

package main;

my $param_comp = TestParamActions->new;
my $param_html = $param_comp->_wrap_render;
like($param_html, qr/select.*42.*blue/, 'parameterised action encoded correctly');

done_testing;
