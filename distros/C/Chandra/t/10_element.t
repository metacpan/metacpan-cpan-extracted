#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Element');

# Reset state between tests
Chandra::Element->reset_ids;

# --- Basic construction ---
{
    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({ tag => 'div' });
    ok($el, 'element created');
    isa_ok($el, 'Chandra::Element');
    is($el->tag, 'div', 'tag is div');
}

# --- Default tag ---
{
    my $el = Chandra::Element->new({});
    is($el->tag, 'div', 'default tag is div');
}

# --- id, class, data, style ---
{
    my $el = Chandra::Element->new({
        tag   => 'span',
        id    => 'myid',
        class => 'foo bar',
        data  => 'Hello',
        style => 'color: red',
    });
    is($el->id, 'myid', 'id accessor');
    is($el->class, 'foo bar', 'class accessor');
    is($el->data, 'Hello', 'data accessor');
    is($el->style, 'color: red', 'style accessor (string)');
}

# --- Style hashref ---
{
    my $el = Chandra::Element->new({
        tag   => 'div',
        style => { color => 'blue', 'font-size' => '14px' },
    });
    my $html = $el->render;
    like($html, qr/style="/, 'style attribute present');
    like($html, qr/color: blue/, 'style hashref rendered');
    like($html, qr/font-size: 14px/, 'style hashref key-value');
}

# --- Auto-generated id ---
{
    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({ tag => 'p' });
    like($el->id, qr/^_e_\d+$/, 'auto-generated id');
}

# --- render basic ---
{
    my $el = Chandra::Element->new({
        tag  => 'p',
        id   => 'test-p',
        data => 'Hello World',
    });
    my $html = $el->render;
    like($html, qr{<p\b}, 'starts with <p');
    like($html, qr{</p>$}, 'ends with </p>');
    like($html, qr{id="test-p"}, 'has id');
    like($html, qr{Hello World}, 'has text content');
}

# --- render with class ---
{
    my $el = Chandra::Element->new({
        tag   => 'div',
        id    => 'c1',
        class => 'container',
        data  => 'text',
    });
    my $html = $el->render;
    like($html, qr{class="container"}, 'class rendered');
}

# --- HTML escaping ---
{
    my $el = Chandra::Element->new({
        tag  => 'p',
        id   => 'esc',
        data => '<script>alert("xss")</script>',
    });
    my $html = $el->render;
    unlike($html, qr{<script>}, 'script tag escaped');
    like($html, qr{&lt;script&gt;}, 'HTML escaped in content');
}

# --- Attribute escaping ---
{
    my $el = Chandra::Element->new({
        tag   => 'div',
        id    => 'a1',
        class => 'foo"bar',
    });
    my $html = $el->render;
    like($html, qr{class="foo&quot;bar"}, 'attribute escaped');
}

# --- Void elements ---
{
    my $el = Chandra::Element->new({ tag => 'br', id => 'br1' });
    my $html = $el->render;
    like($html, qr{/>$}, 'void element self-closes');
    unlike($html, qr{</br>}, 'no closing tag for void');

    my $input = Chandra::Element->new({
        tag  => 'input',
        id   => 'inp1',
        type => 'text',
    });
    $html = $input->render;
    like($html, qr{type="text"}, 'input has type attr');
    like($html, qr{/>$}, 'input self-closes');
}

# --- Children ---
{
    Chandra::Element->reset_ids;
    my $div = Chandra::Element->new({
        tag => 'div',
        id  => 'parent',
        children => [
            { tag => 'h1', data => 'Title' },
            { tag => 'p', data => 'Paragraph' },
        ],
    });
    my @kids = $div->children;
    is(scalar @kids, 2, 'two children');
    isa_ok($kids[0], 'Chandra::Element');
    is($kids[0]->tag, 'h1', 'first child is h1');

    my $html = $div->render;
    like($html, qr{<h1\b.*>Title</h1>}, 'h1 child rendered');
    like($html, qr{<p\b.*>Paragraph</p>}, 'p child rendered');
}

# --- add_child ---
{
    my $ul = Chandra::Element->new({ tag => 'ul', id => 'list' });
    my $li = $ul->add_child({ tag => 'li', data => 'Item 1' });
    isa_ok($li, 'Chandra::Element', 'add_child returns element');
    is($li->data, 'Item 1', 'child data');

    $ul->add_child({ tag => 'li', data => 'Item 2' });
    my @kids = $ul->children;
    is(scalar @kids, 2, 'two children after add_child');

    my $html = $ul->render;
    like($html, qr{<li\b.*>Item 1</li>}, 'li1 rendered');
    like($html, qr{<li\b.*>Item 2</li>}, 'li2 rendered');
}

# --- add_child with Element object ---
{
    my $div = Chandra::Element->new({ tag => 'div', id => 'wrp' });
    my $child = Chandra::Element->new({ tag => 'span', data => 'hello' });
    my $ret = $div->add_child($child);
    is($ret, $child, 'add_child with element returns same object');
    like($div->render, qr{<span\b.*>hello</span>}, 'element child rendered');
}

# --- Nested children ---
{
    my $div = Chandra::Element->new({
        tag => 'div',
        id  => 'nest',
        children => [
            {
                tag => 'ul',
                children => [
                    { tag => 'li', data => 'A' },
                    { tag => 'li', data => 'B' },
                ],
            },
        ],
    });
    my $html = $div->render;
    like($html, qr{<ul\b.*<li\b.*>A</li>}, 'nested children rendered');
}

# --- Event handlers ---
{
    Chandra::Element->reset_ids;
    my $clicked = 0;
    my $btn = Chandra::Element->new({
        tag     => 'button',
        id      => 'btn1',
        data    => 'Click',
        onclick => sub { $clicked = 1 },
    });
    my $html = $btn->render;
    like($html, qr{onclick="}, 'onclick attribute present');
    like($html, qr{window\.chandra\._event}, 'handler calls chandra._event');
    like($html, qr{_h_\d+}, 'handler ID in onclick');
    like($html, qr{_eventData}, 'uses _eventData');
}

# --- Handler registry ---
{
    Chandra::Element->reset_ids;
    my $btn = Chandra::Element->new({
        tag     => 'button',
        id      => 'btn2',
        onclick => sub { return 'clicked' },
    });
    my $handlers = Chandra::Element->handlers;
    ok(scalar keys %$handlers > 0, 'handlers registered');

    # Find the handler for this button
    my ($hid) = values %{$btn->{_handlers}};
    ok(exists $handlers->{$hid}, 'handler in global registry');
    is(ref $handlers->{$hid}, 'CODE', 'handler is coderef');
    is($handlers->{$hid}->(), 'clicked', 'handler callable');
}

# --- Multiple event handlers ---
{
    Chandra::Element->reset_ids;
    my $input = Chandra::Element->new({
        tag      => 'input',
        id       => 'inp2',
        type     => 'text',
        oninput  => sub { 'input' },
        onfocus  => sub { 'focus' },
        onblur   => sub { 'blur' },
    });
    my $html = $input->render;
    like($html, qr{oninput="}, 'oninput handler');
    like($html, qr{onfocus="}, 'onfocus handler');
    like($html, qr{onblur="}, 'onblur handler');

    my $handler_count = scalar keys %{$input->{_handlers}};
    is($handler_count, 3, 'three handlers registered on element');
}

# --- clear_handlers ---
{
    Chandra::Element->new({ tag => 'button', onclick => sub {} });
    my $before = scalar keys %{Chandra::Element->handlers};
    ok($before > 0, 'handlers exist before clear');

    Chandra::Element->clear_handlers;
    my $after = scalar keys %{Chandra::Element->handlers};
    is($after, 0, 'handlers cleared');
}

# --- get_element_by_id ---
{
    my $tree = Chandra::Element->new({
        tag => 'div', id => 'root',
        children => [
            { tag => 'p', id => 'p1', data => 'First' },
            {
                tag => 'div', id => 'inner',
                children => [
                    { tag => 'span', id => 'deep', data => 'Deep' },
                ],
            },
        ],
    });

    my $found = $tree->get_element_by_id('deep');
    ok($found, 'found nested element by id');
    is($found->data, 'Deep', 'found correct element');

    my $root = $tree->get_element_by_id('root');
    is($root, $tree, 'find self by id');

    my $missing = $tree->get_element_by_id('nonexistent');
    is($missing, undef, 'missing id returns undef');
}

# --- get_element_by_tag ---
{
    my $tree = Chandra::Element->new({
        tag => 'div', id => 'r',
        children => [
            { tag => 'h1', data => 'Title' },
            { tag => 'p', data => 'Content' },
        ],
    });

    my $h1 = $tree->get_element_by_tag('h1');
    ok($h1, 'found by tag');
    is($h1->data, 'Title', 'correct element');

    my $div = $tree->get_element_by_tag('div');
    is($div, $tree, 'finds self by tag');
}

# --- get_elements_by_class ---
{
    my $tree = Chandra::Element->new({
        tag => 'div', id => 'rc',
        children => [
            { tag => 'p', class => 'highlight', data => 'A' },
            { tag => 'p', class => 'normal', data => 'B' },
            { tag => 'p', class => 'highlight bold', data => 'C' },
        ],
    });

    my @found = $tree->get_elements_by_class('highlight');
    is(scalar @found, 2, 'found 2 elements with class');
    is($found[0]->data, 'A', 'first match');
    is($found[1]->data, 'C', 'second match');
}

# --- data setter with array ref (Moonshine compat) ---
{
    my $el = Chandra::Element->new({ tag => 'h1', data => 'Old' });
    is($el->data, 'Old', 'initial data');
    $el->data(['New']);
    is($el->data, 'New', 'data updated via arrayref');
}

# --- data setter with string ---
{
    my $el = Chandra::Element->new({ tag => 'p', data => 'A' });
    $el->data('B');
    is($el->data, 'B', 'data updated via string');
}

# --- Extra attributes ---
{
    my $el = Chandra::Element->new({
        tag         => 'a',
        id          => 'link1',
        href        => 'https://example.com',
        target      => '_blank',
        placeholder => 'test',
    });
    my $html = $el->render;
    like($html, qr{href="https://example.com"}, 'href attr');
    like($html, qr{target="_blank"}, 'target attr');
    like($html, qr{placeholder="test"}, 'placeholder attr');
}

# --- attribute() accessor ---
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'a2' });
    $el->attribute('data-value', '42');
    is($el->attribute('data-value'), '42', 'attribute set and get');
    like($el->render, qr{data-value="42"}, 'attribute rendered');
}

# --- Complex render: full page structure ---
{
    Chandra::Element->reset_ids;
    my $page = Chandra::Element->new({
        tag => 'div',
        id  => 'app',
        children => [
            { tag => 'h1', data => 'My App' },
            {
                tag => 'form',
                id  => 'myform',
                children => [
                    { tag => 'input', type => 'text', id => 'name', placeholder => 'Name' },
                    { tag => 'button', data => 'Submit', type => 'submit' },
                ],
            },
        ],
    });

    my $html = $page->render;
    like($html, qr{^<div\b}, 'starts with div');
    like($html, qr{</div>$}, 'ends with /div');
    like($html, qr{<h1\b.*>My App</h1>}, 'h1 rendered');
    like($html, qr{<form\b}, 'form rendered');
    like($html, qr{<input\b.*type="text".*/>}, 'input rendered');
    like($html, qr{<button\b.*>Submit</button>}, 'button rendered');
}

done_testing();
