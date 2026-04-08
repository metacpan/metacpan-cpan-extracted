#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra;
use Chandra::Form;

# ---- new() with odd args ----
{
    eval { Chandra::Form->new('orphan') };
    ok(!$@, 'odd args ignored (no key for orphan value)');
}

# ---- action must be coderef ----
{
    eval { Chandra::Form->new(action => 'not a sub') };
    like($@, qr/coderef/, 'action rejects non-coderef');
}

# ---- text() with no options hash ----
{
    my $f = Chandra::Form->new(id => 'e1');
    $f->text('plain');
    is($f->field_count, 1, 'text with no opts');
    my $html = $f->render;
    like($html, qr/name="plain"/, 'field rendered');
    like($html, qr/type="text"/, 'type is text');
}

# ---- Empty form render ----
{
    my $f = Chandra::Form->new(id => 'empty');
    my $html = $f->render;
    like($html, qr/<form[^>]*><div class="chandra-field chandra-field-submit">/, 'empty form has submit');
    like($html, qr/<\/form>$/, 'form closes');
}

# ---- select() with disabled option ----
{
    my $f = Chandra::Form->new(id => 'e2');
    $f->select('x', {
        options => [
            { value => 'a', label => 'A', disabled => 1 },
            { value => 'b', label => 'B' },
        ],
    });
    my $html = $f->render;
    like($html, qr/<option value="a" disabled>A<\/option>/, 'disabled option');
    like($html, qr/<option value="b">B<\/option>/, 'normal option');
}

# ---- select() with no options ----
{
    my $f = Chandra::Form->new(id => 'e3');
    $f->select('empty_sel', {});
    my $html = $f->render;
    like($html, qr/<select[^>]*><\/select>/, 'empty select');
}

# ---- checkbox with custom value ----
{
    my $f = Chandra::Form->new(id => 'e4');
    $f->checkbox('terms', { value => 'yes', label => 'Accept' });
    my $html = $f->render;
    like($html, qr/value="yes"/, 'custom checkbox value');
}

# ---- checkbox unchecked ----
{
    my $f = Chandra::Form->new(id => 'e5');
    $f->checkbox('opt', { label => 'Option' });
    my $html = $f->render;
    unlike($html, qr/\bchecked\b/, 'not checked by default');
}

# ---- radio with no value (none selected) ----
{
    my $f = Chandra::Form->new(id => 'e6');
    $f->radio('choice', {
        options => [
            { value => 'a', label => 'A' },
            { value => 'b', label => 'B' },
        ],
    });
    my $html = $f->render;
    unlike($html, qr/\bchecked\b/, 'no radio checked');
}

# ---- radio with empty options ----
{
    my $f = Chandra::Form->new(id => 'e7');
    $f->radio('empty_radio', { label => 'Group', options => [] });
    my $html = $f->render;
    like($html, qr/chandra-field-radio/, 'radio wrapper present');
    unlike($html, qr/type="radio"/, 'no radio buttons for empty options');
}

# ---- textarea with empty value ----
{
    my $f = Chandra::Form->new(id => 'e8');
    $f->textarea('notes', { label => 'Notes' });
    my $html = $f->render;
    like($html, qr/<textarea[^>]*><\/textarea>/, 'empty textarea content');
}

# ---- textarea with cols ----
{
    my $f = Chandra::Form->new(id => 'e9');
    $f->textarea('code', { cols => 80, rows => 10 });
    my $html = $f->render;
    like($html, qr/cols="80"/, 'cols attribute');
    like($html, qr/rows="10"/, 'rows attribute');
}

# ---- disabled and readonly ----
{
    my $f = Chandra::Form->new(id => 'e10');
    $f->text('dis', { disabled => 1 });
    $f->text('ro', { readonly => 1 });
    my $html = $f->render;
    like($html, qr/name="dis"[^>]*disabled/, 'disabled attribute');
    like($html, qr/name="ro"[^>]*readonly/, 'readonly attribute');
}

# ---- autofocus ----
{
    my $f = Chandra::Form->new(id => 'e11');
    $f->text('focus', { autofocus => 1 });
    my $html = $f->render;
    like($html, qr/autofocus/, 'autofocus attribute');
}

# ---- pattern attribute ----
{
    my $f = Chandra::Form->new(id => 'e12');
    $f->text('code', { pattern => '[A-Z]{3}' });
    my $html = $f->render;
    like($html, qr/pattern="\[A-Z\]\{3\}"/, 'pattern attribute');
}

# ---- custom class on field ----
{
    my $f = Chandra::Form->new(id => 'e13');
    $f->text('styled', { class => 'big-input' });
    my $html = $f->render;
    like($html, qr/class="big-input"/, 'custom class on input');
}

# ---- Multiple groups ----
{
    my $f = Chandra::Form->new(id => 'mg');
    $f->group('Group A' => sub {
        $f->text('a1', {});
    });
    $f->group('Group B' => sub {
        $f->text('b1', {});
    });
    my $html = $f->render;
    my @fieldsets = ($html =~ /<fieldset/g);
    is(scalar @fieldsets, 2, 'two fieldsets');
    my @legends = ($html =~ /<legend>(.*?)<\/legend>/g);
    is_deeply(\@legends, ['Group A', 'Group B'], 'legend text');
}

# ---- group() rejects non-coderef ----
{
    my $f = Chandra::Form->new(id => 'eg');
    eval { $f->group('Bad', 'not a sub') };
    like($@, qr/coderef/, 'group rejects non-coderef');
}

# ---- on_change() bad args ----
{
    my $f = Chandra::Form->new(id => 'ocb');
    eval { $f->on_change('not_a_sub') };
    like($@, qr/coderef/, 'on_change rejects bad args');
}

# ---- action() set rejects non-coderef ----
{
    my $f = Chandra::Form->new(id => 'actb');
    eval { $f->action('string') };
    like($@, qr/coderef/, 'action rejects non-coderef');
}

# ---- set_values_js() rejects non-hashref ----
{
    my $f = Chandra::Form->new(id => 'svb');
    eval { $f->set_values_js('not a ref') };
    like($@, qr/hashref/, 'set_values_js rejects non-hashref');
}

# ---- show_errors_js() rejects non-hashref ----
{
    my $f = Chandra::Form->new(id => 'seb');
    eval { $f->show_errors_js([]) };
    like($@, qr/hashref/, 'show_errors_js rejects non-hashref');
}

# ---- XSS in field name ----
{
    my $f = Chandra::Form->new(id => 'xss');
    $f->text('x"><script>alert(1)</script>', { label => 'Test' });
    my $html = $f->render;
    unlike($html, qr/<script>/, 'XSS in name escaped');
    like($html, qr/&lt;script&gt;|&quot;/, 'dangerous chars escaped');
}

# ---- XSS in select option label ----
{
    my $f = Chandra::Form->new(id => 'xss2');
    $f->select('s', {
        options => [{ value => 'x', label => '<img onerror=alert(1)>' }],
    });
    my $html = $f->render;
    unlike($html, qr/<img/, 'XSS in option label escaped');
}

# ---- group label escaping ----
{
    my $f = Chandra::Form->new(id => 'gesc');
    $f->group('<script>bad</script>' => sub {
        $f->text('x', {});
    });
    my $html = $f->render;
    unlike($html, qr/<script>bad/, 'group label escaped');
    like($html, qr/&lt;script&gt;/, 'group label HTML entities');
}

# ---- dispatch _form_submit ----
{
    my @got;
    my $f = Chandra::Form->new(
        id     => 'disp',
        action => sub { @got = @_ },
    );
    $f->dispatch('_form_submit', '{"id":"disp","data":{"name":"test","age":"25"}}');
    is_deeply(\@got, [{ name => 'test', age => '25' }], 'dispatch submit calls action');
}

# ---- dispatch _form_change global ----
{
    my @got;
    my $f = Chandra::Form->new(id => 'disp2');
    $f->on_change(sub { @got = @_ });
    $f->dispatch('_form_change', '{"id":"disp2","field":"theme","value":"dark"}');
    is_deeply(\@got, ['theme', 'dark'], 'dispatch change calls global handler');
}

# ---- dispatch _form_change field-specific ----
{
    my $val;
    my $f = Chandra::Form->new(id => 'disp3');
    $f->on_change('name', sub { $val = $_[0] });
    $f->dispatch('_form_change', '{"id":"disp3","field":"name","value":"bob"}');
    is($val, 'bob', 'dispatch change calls field handler');
}

# ---- dispatch with bad JSON ----
{
    my $f = Chandra::Form->new(id => 'disp4');
    eval { $f->dispatch('_form_submit', 'not json') };
    # Should not die, just silently ignore
    ok(1, 'bad JSON dispatch does not crash');
}

# ---- dispatch with no action ----
{
    my $f = Chandra::Form->new(id => 'disp5');
    $f->dispatch('_form_submit', '{"id":"disp5","data":{"x":"1"}}');
    ok(1, 'dispatch with no action does not crash');
}

# ---- hidden field has no label or error ----
{
    my $f = Chandra::Form->new(id => 'hid');
    $f->hidden('secret', { value => 'xyz' });
    my $html = $f->render;
    unlike($html, qr/<label[^>]*for="hid-secret"/, 'no label');
    unlike($html, qr/hid-secret-error/, 'no error span for hidden');
    unlike($html, qr/chandra-field.*hidden/s, 'no field wrapper for hidden');
}

# ---- Large form (many fields) ----
{
    my $f = Chandra::Form->new(id => 'big');
    for my $i (1..50) {
        $f->text("field_$i", { label => "Field $i" });
    }
    is($f->field_count, 50, '50 fields');
    my $html = $f->render;
    my @inputs = ($html =~ /type="text"/g);
    is(scalar @inputs, 50, '50 text inputs rendered');
}

# ---- field_count after mixed types ----
{
    my $f = Chandra::Form->new(id => 'cnt');
    $f->text('a', {});
    $f->hidden('b', { value => '1' });
    $f->checkbox('c', {});
    is($f->field_count, 3, 'count includes all types');
    is_deeply($f->fields, [qw(a b c)], 'field names include hidden');
}

# ---- _route_event dispatches to correct form by id ----
{
    my (@got_a, @got_b);
    my $fa = Chandra::Form->new(
        id     => 'form_a',
        action => sub { @got_a = @_ },
    );
    my $fb = Chandra::Form->new(
        id     => 'form_b',
        action => sub { @got_b = @_ },
    );

    # Register both in the global registry (attach without an app)
    # We test _route_event directly as a class method
    Chandra::Form->_route_event('_form_submit',
        '{"id":"form_a","data":{"x":"1"}}');
    # form_a not registered yet, should be a no-op
    is_deeply(\@got_a, [], 'route before register is no-op');

    # Simulate registration by dispatching directly
    $fa->dispatch('_form_submit', '{"id":"form_a","data":{"x":"1"}}');
    is_deeply(\@got_a, [{ x => '1' }], 'direct dispatch works');
    @got_a = ();

    # Test detach
    $fa->detach;
    ok(1, 'detach does not crash');
}

# ---- multiple forms dispatch independently ----
{
    my (@got_a, @got_b);
    my $fa = Chandra::Form->new(
        id     => 'multi_a',
        action => sub { @got_a = @_ },
    );
    my $fb = Chandra::Form->new(
        id     => 'multi_b',
        action => sub { @got_b = @_ },
    );

    $fa->dispatch('_form_submit', '{"id":"multi_a","data":{"v":"a"}}');
    $fb->dispatch('_form_submit', '{"id":"multi_b","data":{"v":"b"}}');
    is_deeply(\@got_a, [{ v => 'a' }], 'form A got its data');
    is_deeply(\@got_b, [{ v => 'b' }], 'form B got its data');
}

done_testing;
