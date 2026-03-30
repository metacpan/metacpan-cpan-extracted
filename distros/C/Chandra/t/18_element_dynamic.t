#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Element');

# Reset state
Chandra::Element->reset_ids;

# === Modify element attributes after creation ===
{
    my $el = Chandra::Element->new({ tag => 'div', class => 'original' });
    is($el->class, 'original', 'initial class');

    $el->class('updated');
    is($el->class, 'updated', 'class updated');

    my $html = $el->render;
    like($html, qr/class="updated"/, 'render reflects updated class');
}

# === Modify id after creation ===
{
    my $el = Chandra::Element->new({ tag => 'span', id => 'old-id' });
    is($el->id, 'old-id', 'initial id');

    $el->id('new-id');
    is($el->id, 'new-id', 'id updated');

    my $html = $el->render;
    like($html, qr/id="new-id"/, 'render reflects updated id');
}

# === Modify style after creation ===
{
    my $el = Chandra::Element->new({ tag => 'div', style => 'color: red' });
    is($el->style, 'color: red', 'initial style');

    $el->style('color: blue');
    is($el->style, 'color: blue', 'style updated');

    my $html = $el->render;
    like($html, qr/style="color: blue"/, 'render reflects updated style');
}

# === Modify data after creation ===
{
    my $el = Chandra::Element->new({ tag => 'p', data => 'Hello' });
    is($el->data, 'Hello', 'initial data');

    $el->data('World');
    is($el->data, 'World', 'data updated');

    my $html = $el->render;
    like($html, qr/>World</, 'render reflects updated data');
}

# === data setter with array ===
{
    my $el = Chandra::Element->new({ tag => 'p' });
    $el->data(['array value']);
    is($el->data, 'array value', 'data setter unwraps single-element array');
}

# === Modify attribute after creation ===
{
    my $el = Chandra::Element->new({ tag => 'input', type => 'text' });
    is($el->attribute('type'), 'text', 'initial attribute');

    $el->attribute('type', 'password');
    is($el->attribute('type'), 'password', 'attribute updated');

    my $html = $el->render;
    like($html, qr/type="password"/, 'render reflects updated attribute');
}

# === Add children dynamically ===
{
    my $parent = Chandra::Element->new({ tag => 'ul' });
    is(scalar $parent->children, 0, 'no children initially');

    my $child1 = $parent->add_child({ tag => 'li', data => 'Item 1' });
    my $child2 = $parent->add_child({ tag => 'li', data => 'Item 2' });

    is(scalar $parent->children, 2, 'two children added');
    isa_ok($child1, 'Chandra::Element', 'add_child returns Element');
    is($child1->data, 'Item 1', 'first child data');
    is($child2->data, 'Item 2', 'second child data');

    my $html = $parent->render;
    like($html, qr/<ul.*>.*Item 1.*Item 2.*<\/ul>/s, 'children rendered in order');
}

# === Add Element object as child ===
{
    my $parent = Chandra::Element->new({ tag => 'div' });
    my $child = Chandra::Element->new({ tag => 'span', data => 'child' });
    my $returned = $parent->add_child($child);
    is($returned, $child, 'add_child returns the child element');
    is(scalar $parent->children, 1, 'child added');
}

# === Add text child ===
{
    my $parent = Chandra::Element->new({ tag => 'p' });
    $parent->add_child('plain text');
    my $html = $parent->render;
    like($html, qr/<p[^>]*>plain text<\/p>/, 'plain text child rendered');
}

# === Text child escaping ===
{
    my $parent = Chandra::Element->new({ tag => 'p' });
    $parent->add_child('<script>alert("xss")</script>');
    my $html = $parent->render;
    like($html, qr/&lt;script&gt;/, 'text child is HTML-escaped');
    unlike($html, qr/<script>/, 'no raw script tag');
}

# === get_element_by_id on self ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'target' });
    my $found = $el->get_element_by_id('target');
    is($found, $el, 'finds self by id');
}

# === get_element_by_id on deep nested child ===
{
    my $root = Chandra::Element->new({
        tag => 'div', id => 'root',
        children => [
            { tag => 'div', id => 'level1',
              children => [
                { tag => 'div', id => 'level2',
                  children => [
                    { tag => 'span', id => 'deep-target', data => 'found me' }
                  ]
                }
              ]
            }
        ]
    });

    my $found = $root->get_element_by_id('deep-target');
    ok($found, 'deep element found');
    is($found->data, 'found me', 'correct deep element');
}

# === get_element_by_id not found ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'x' });
    my $found = $el->get_element_by_id('nonexistent');
    ok(!$found, 'returns undef for missing id');
}

# === get_element_by_tag ===
{
    my $root = Chandra::Element->new({
        tag => 'div',
        children => [
            { tag => 'p', data => 'paragraph' },
            { tag => 'span', data => 'span' },
        ]
    });

    my $p = $root->get_element_by_tag('p');
    ok($p, 'found p element');
    is($p->data, 'paragraph', 'correct element by tag');

    my $div = $root->get_element_by_tag('div');
    is($div, $root, 'get_element_by_tag matches self');
}

# === get_elements_by_class multiple results ===
{
    my $root = Chandra::Element->new({
        tag => 'div',
        children => [
            { tag => 'p', class => 'item highlight', data => 'first' },
            { tag => 'p', class => 'other', data => 'second' },
            { tag => 'p', class => 'item', data => 'third' },
        ]
    });

    my @items = $root->get_elements_by_class('item');
    is(scalar @items, 2, 'found two elements with class item');
    is($items[0]->data, 'first', 'first match correct');
    is($items[1]->data, 'third', 'second match correct');
}

# === get_elements_by_class empty result ===
{
    my $root = Chandra::Element->new({ tag => 'div', class => 'foo' });
    my @results = $root->get_elements_by_class('bar');
    is(scalar @results, 0, 'no results for non-matching class');
}

# === Void elements render without closing tag ===
{
    for my $void_tag (qw(br hr img input)) {
        my $el = Chandra::Element->new({ tag => $void_tag });
        my $html = $el->render;
        like($html, qr/\/>$/, "$void_tag renders as void element");
        unlike($html, qr/<\/$void_tag>/, "$void_tag has no closing tag");
    }
}

# === Non-void elements have closing tag ===
{
    for my $tag (qw(div span p h1 ul li)) {
        my $el = Chandra::Element->new({ tag => $tag });
        my $html = $el->render;
        like($html, qr/<\/$tag>$/, "$tag has closing tag");
    }
}

# === Style as hashref ===
{
    my $el = Chandra::Element->new({
        tag => 'div',
        style => { color => 'red', 'font-size' => '14px' },
    });
    my $html = $el->render;
    like($html, qr/style="/, 'style attribute present');
    like($html, qr/color: red/, 'color in style');
    like($html, qr/font-size: 14px/, 'font-size in style');
}

# === Event handler registration ===
{
    Chandra::Element->clear_handlers;
    my $clicked = 0;
    my $el = Chandra::Element->new({
        tag => 'button',
        data => 'Click',
        onclick => sub { $clicked++ },
    });

    my $html = $el->render;
    like($html, qr/onclick="/, 'onclick attribute in HTML');
    like($html, qr/window\.chandra\._event/, 'event calls bridge');

    # Handler should be in registry
    my $handlers = Chandra::Element->handlers;
    ok(scalar keys %$handlers >= 1, 'handler registered');
}

# === Multiple event handlers on same element ===
{
    Chandra::Element->clear_handlers;
    my $el = Chandra::Element->new({
        tag => 'input',
        type => 'text',
        oninput => sub { },
        onfocus => sub { },
        onblur => sub { },
    });

    my $html = $el->render;
    like($html, qr/oninput="/, 'oninput handler present');
    like($html, qr/onfocus="/, 'onfocus handler present');
    like($html, qr/onblur="/, 'onblur handler present');

    my $handlers = Chandra::Element->handlers;
    is(scalar keys %$handlers, 3, 'three handlers registered');
}

# === Non-coderef event handler ignored ===
{
    Chandra::Element->clear_handlers;
    my $el = Chandra::Element->new({
        tag => 'button',
        onclick => 'not a coderef',
    });

    my $html = $el->render;
    unlike($html, qr/onclick=/, 'string onclick not rendered as handler');
    my $handlers = Chandra::Element->handlers;
    is(scalar keys %$handlers, 0, 'no handler registered for non-coderef');
}

# === HTML escaping in data ===
{
    my $el = Chandra::Element->new({
        tag => 'p',
        data => '<b>bold</b> & "quotes"',
    });
    my $html = $el->render;
    like($html, qr/&lt;b&gt;bold&lt;\/b&gt;/, 'HTML tags escaped in data');
    like($html, qr/&amp;/, 'ampersand escaped in data');
}

# === Attribute escaping ===
{
    my $el = Chandra::Element->new({
        tag => 'div',
        id => 'a"b',
        class => '<evil>',
    });
    my $html = $el->render;
    like($html, qr/id="a&quot;b"/, 'quotes escaped in id attribute');
    like($html, qr/class="&lt;evil&gt;"/, 'angle brackets escaped in class');
}

# === Boolean attribute (undef value) ===
{
    my $el = Chandra::Element->new({ tag => 'input' });
    $el->attribute('disabled', undef);
    # attribute() returns undef for undef value set
    # But in render, undef values render as bare attributes
    $el->{attributes}{required} = undef;
    my $html = $el->render;
    like($html, qr/ required(?!=)/, 'boolean attribute rendered without value');
}

# === Constructor with no args ===
{
    my $el = Chandra::Element->new;
    is($el->tag, 'div', 'default tag is div');
    ok(defined $el->id, 'auto-generated id');
    like($el->id, qr/^_e_\d+$/, 'auto-id format');
}

# === Constructor with empty hashref ===
{
    my $el = Chandra::Element->new({});
    is($el->tag, 'div', 'empty hashref defaults to div');
}

# === Auto-generated IDs are unique ===
{
    my $el1 = Chandra::Element->new({});
    my $el2 = Chandra::Element->new({});
    isnt($el1->id, $el2->id, 'auto IDs are unique');
}

# === clear_handlers and reset_ids ===
{
    Chandra::Element->clear_handlers;
    my $handlers = Chandra::Element->handlers;
    is(scalar keys %$handlers, 0, 'handlers cleared');

    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({});
    like($el->id, qr/^_e_1$/, 'ID counter reset');
}

# === Children constructed from hashrefs in constructor ===
{
    Chandra::Element->reset_ids;
    my $root = Chandra::Element->new({
        tag => 'div',
        children => [
            { tag => 'p', data => 'child1' },
            { tag => 'p', data => 'child2' },
        ],
    });

    my @children = $root->children;
    is(scalar @children, 2, 'two children from constructor');
    isa_ok($children[0], 'Chandra::Element', 'hashref child auto-wrapped');
    is($children[0]->tag, 'p', 'child tag correct');
    is($children[0]->data, 'child1', 'child data correct');
}

# === Complex nested render ===
{
    Chandra::Element->reset_ids;
    my $root = Chandra::Element->new({
        tag => 'div',
        id => 'app',
        class => 'container',
        children => [
            { tag => 'h1', data => 'Title' },
            {
                tag => 'ul',
                children => [
                    { tag => 'li', data => 'One' },
                    { tag => 'li', data => 'Two' },
                    { tag => 'li', data => 'Three' },
                ],
            },
        ],
    });

    my $html = $root->render;
    like($html, qr/<div id="app" class="container">/, 'root element');
    like($html, qr/<h1[^>]*>Title<\/h1>/, 'h1 child');
    like($html, qr/<ul[^>]*>.*<li[^>]*>One<\/li>.*<li[^>]*>Two<\/li>.*<li[^>]*>Three<\/li>.*<\/ul>/s, 'nested list');
    like($html, qr/<\/div>$/, 'closing root tag');
}

# === get_handler class method ===
{
    Chandra::Element->reset_ids;
    my $handler_sub = sub { 'test' };
    my $el = Chandra::Element->new({
        tag => 'button',
        onclick => $handler_sub,
    });

    my $handlers = Chandra::Element->handlers;
    my ($hid) = keys %$handlers;
    ok($hid, 'handler ID exists');

    my $retrieved = Chandra::Element->get_handler($hid);
    is(ref $retrieved, 'CODE', 'get_handler returns coderef');
    is($retrieved->(), 'test', 'handler returns correct value');
}

# === get_handler for non-existent ID ===
{
    my $result = Chandra::Element->get_handler('nonexistent_id');
    ok(!$result, 'get_handler returns undef for missing ID');
}

done_testing;
