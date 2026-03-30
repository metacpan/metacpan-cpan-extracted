#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Element');

# === raw content is not escaped ===
{
    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({
        tag => 'div',
        id  => 'rawtest',
        raw => '<b>Bold</b> & <i>italic</i>',
    });
    my $html = $el->render;
    like($html, qr{<b>Bold</b>}, 'raw HTML not escaped');
    like($html, qr{& <i>italic</i>}, 'raw HTML ampersand not escaped');
}

# === raw and data coexist ===
{
    my $el = Chandra::Element->new({
        tag  => 'div',
        id   => 'both',
        raw  => '<em>raw</em>',
        data => 'text data',
    });
    my $html = $el->render;
    like($html, qr{<em>raw</em>}, 'raw content rendered');
    like($html, qr{text data}, 'data content also rendered');
    # raw should come before data
    my $raw_pos = index($html, '<em>raw</em>');
    my $data_pos = index($html, 'text data');
    ok($raw_pos < $data_pos, 'raw content rendered before data');
}

# === raw setter ===
{
    my $el = Chandra::Element->new({ tag => 'p', id => 'rs' });
    $el->raw('<strong>new</strong>');
    is($el->raw, '<strong>new</strong>', 'raw setter works');
    like($el->render, qr{<strong>new</strong>}, 'updated raw rendered');
}

# === boolean attribute (undef value) ===
{
    my $el = Chandra::Element->new({
        tag      => 'input',
        id       => 'bool',
        disabled => undef,
        type     => 'text',
    });
    my $html = $el->render;
    like($html, qr{ disabled(?=[ />])}, 'boolean attribute rendered without value');
    like($html, qr{type="text"}, 'regular attribute still has value');
}

# === style setter ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'ss' });
    $el->style('display: none');
    is($el->style, 'display: none', 'style setter works');
    like($el->render, qr{style="display: none"}, 'updated style rendered');
}

# === style setter with hashref ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'ssh' });
    $el->style({ color => 'red', padding => '10px' });
    is(ref $el->style, 'HASH', 'style set to hashref');
    my $html = $el->render;
    like($html, qr/color: red/, 'hashref style color rendered');
    like($html, qr/padding: 10px/, 'hashref style padding rendered');
}

# === class setter ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'cs' });
    $el->class('new-class');
    is($el->class, 'new-class', 'class setter works');
    like($el->render, qr{class="new-class"}, 'updated class rendered');
}

# === id setter ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'old-id' });
    $el->id('new-id');
    is($el->id, 'new-id', 'id setter works');
    like($el->render, qr{id="new-id"}, 'updated id rendered');
}

# === data setter with array (Moonshine compat) unwraps first element ===
{
    my $el = Chandra::Element->new({ tag => 'span' });
    $el->data(['wrapped']);
    is($el->data, 'wrapped', 'data arrayref unwraps first element');
}

# === all void elements self-close ===
{
    my @voids = qw(area base br col embed hr img input link meta param source track wbr);
    for my $tag (@voids) {
        Chandra::Element->reset_ids;
        my $el = Chandra::Element->new({ tag => $tag });
        my $html = $el->render;
        like($html, qr{/>$}, "$tag self-closes");
        unlike($html, qr{</$tag>}, "$tag has no closing tag");
    }
}

# === non-void elements have closing tags ===
{
    my @non_voids = qw(div span p h1 ul li form button select textarea table tr td);
    for my $tag (@non_voids) {
        Chandra::Element->reset_ids;
        my $el = Chandra::Element->new({ tag => $tag });
        my $html = $el->render;
        like($html, qr{</$tag>$}, "$tag has closing tag");
    }
}

# === handler non-coderef ignored ===
{
    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({
        tag     => 'button',
        id      => 'noop',
        onclick => 'not a coderef',
    });
    my $html = $el->render;
    # 'not a coderef' is treated as a regular attribute since ref check fails
    unlike($html, qr{window\.chandra\._event}, 'non-coderef onclick not wired to bridge');
}

# === multiple event types on same element ===
{
    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({
        tag         => 'div',
        id          => 'multi-ev',
        onclick     => sub { 'click' },
        onmouseover => sub { 'hover' },
        onkeydown   => sub { 'key' },
    });
    my $html = $el->render;
    like($html, qr{onclick="}, 'onclick present');
    like($html, qr{onmouseover="}, 'onmouseover present');
    like($html, qr{onkeydown="}, 'onkeydown present');
    my @handler_ids = $html =~ /(_h_\d+)/g;
    my %unique = map { $_ => 1 } @handler_ids;
    is(scalar keys %unique, 3, 'three unique handler IDs');
}

# === HTML escaping in data ===
{
    my $el = Chandra::Element->new({
        tag  => 'p',
        id   => 'esc1',
        data => '1 < 2 & 3 > 1',
    });
    my $html = $el->render;
    like($html, qr{1 &lt; 2 &amp; 3 &gt; 1}, 'all HTML entities escaped in data');
}

# === attribute escaping with quotes ===
{
    my $el = Chandra::Element->new({
        tag   => 'div',
        id    => 'esc2',
        title => 'He said "hello" & <goodbye>',
    });
    my $html = $el->render;
    like($html, qr{title="He said &quot;hello&quot; &amp; &lt;goodbye&gt;"}, 'attribute fully escaped');
}

# === child as string gets HTML-escaped ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'str-child' });
    push @{$el->{children}}, '<script>alert(1)</script>';
    my $html = $el->render;
    like($html, qr{&lt;script&gt;}, 'string child is HTML-escaped');
    unlike($html, qr{<script>alert}, 'no raw script tag from string child');
}

# === get_element_by_id returns undef for string children ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'parent-str' });
    push @{$el->{children}}, 'just a string';
    my $found = $el->get_element_by_id('nonexistent');
    is($found, undef, 'get_element_by_id handles string children safely');
}

# === get_element_by_tag with string children ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'parent-str2' });
    push @{$el->{children}}, 'text';
    my $found = $el->get_element_by_tag('span');
    is($found, undef, 'get_element_by_tag handles string children safely');
}

# === get_elements_by_class with string children ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'parent-str3', class => 'target' });
    push @{$el->{children}}, 'text';
    my @found = $el->get_elements_by_class('target');
    is(scalar @found, 1, 'get_elements_by_class handles string children, finds parent');
}

# === get_elements_by_class with no class ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'no-class' });
    my @found = $el->get_elements_by_class('anything');
    is(scalar @found, 0, 'element without class not matched');
}

# === get_elements_by_class with multiple classes ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'mc', class => 'foo bar baz' });
    my @found_foo = $el->get_elements_by_class('foo');
    my @found_bar = $el->get_elements_by_class('bar');
    my @found_baz = $el->get_elements_by_class('baz');
    my @found_qux = $el->get_elements_by_class('qux');
    is(scalar @found_foo, 1, 'found by first class');
    is(scalar @found_bar, 1, 'found by middle class');
    is(scalar @found_baz, 1, 'found by last class');
    is(scalar @found_qux, 0, 'not found by absent class');
}

# === reset_ids resets element and handler counters ===
{
    Chandra::Element->reset_ids;
    my $el1 = Chandra::Element->new({ tag => 'div' });
    like($el1->id, qr/^_e_1$/, 'first element after reset is _e_1');

    Chandra::Element->reset_ids;
    my $el2 = Chandra::Element->new({ tag => 'div' });
    like($el2->id, qr/^_e_1$/, 'first element after second reset is _e_1 again');
}

# === get_handler class method ===
{
    Chandra::Element->reset_ids;
    my $el = Chandra::Element->new({
        tag     => 'button',
        id      => 'gh',
        onclick => sub { return 'found' },
    });
    my ($hid) = values %{$el->{_handlers}};
    my $handler = Chandra::Element->get_handler($hid);
    ok(ref $handler eq 'CODE', 'get_handler returns coderef');
    is($handler->(), 'found', 'get_handler returns correct handler');
}

# === get_handler for non-existent returns undef ===
{
    my $handler = Chandra::Element->get_handler('_h_nonexistent');
    is($handler, undef, 'get_handler for non-existent returns undef');
}

# === constructor with non-hashref defaults to empty ===
{
    my $el = Chandra::Element->new('not a hash');
    is($el->tag, 'div', 'non-hashref arg defaults to div');
}

# === constructor with undef defaults to empty ===
{
    my $el = Chandra::Element->new(undef);
    is($el->tag, 'div', 'undef arg defaults to div');
}

# === deeply nested tree query ===
{
    my $tree = Chandra::Element->new({
        tag => 'div', id => 'l1',
        children => [{
            tag => 'div', id => 'l2',
            children => [{
                tag => 'div', id => 'l3',
                children => [{
                    tag => 'span', id => 'l4', data => 'deep',
                }],
            }],
        }],
    });
    my $found = $tree->get_element_by_id('l4');
    ok($found, 'found deeply nested element');
    is($found->data, 'deep', 'correct deeply nested element');
}

# === attribute accessor get and set ===
{
    my $el = Chandra::Element->new({ tag => 'div', id => 'attr' });
    is($el->attribute('missing'), undef, 'nonexistent attribute returns undef');
    $el->attribute('role', 'button');
    is($el->attribute('role'), 'button', 'attribute set and retrieved');
}

# === empty style hashref produces no style attribute ===
{
    my $el = Chandra::Element->new({
        tag   => 'div',
        id    => 'empty-style',
        style => {},
    });
    my $html = $el->render;
    unlike($html, qr/style=/, 'empty style hashref produces no style attribute');
}

# === empty style string produces no style attribute ===
{
    my $el = Chandra::Element->new({
        tag   => 'div',
        id    => 'empty-style-str',
        style => '',
    });
    my $html = $el->render;
    unlike($html, qr/style=/, 'empty style string produces no style attribute');
}

done_testing;
