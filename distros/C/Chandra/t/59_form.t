#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra;
use Chandra::Form;

# ---- Constructor defaults ----
{
    my $f = Chandra::Form->new;
    isa_ok($f, 'Chandra::Form', 'new() returns blessed object');
    like($f->id, qr/^chandra-form-\d+$/, 'auto-generated id');
    is($f->field_count, 0, 'no fields initially');
    is_deeply($f->fields, [], 'fields() empty');
}

# ---- Constructor with options ----
{
    my $called = 0;
    my $f = Chandra::Form->new(
        id     => 'test-form',
        action => sub { $called++ },
        class  => 'my-class',
    );
    is($f->id, 'test-form', 'custom id');
    ok($f->action, 'action is set');
}

# ---- text() ----
{
    my $f = Chandra::Form->new(id => 'f1');
    my $ret = $f->text('username', {
        label       => 'Username',
        placeholder => 'Enter name',
        value       => 'alice',
        required    => 1,
        maxlength   => 50,
    });
    is($ret, $f, 'text() returns $self for chaining');
    is($f->field_count, 1, 'one field added');
    is_deeply($f->fields, ['username'], 'field name stored');

    my $html = $f->render;
    like($html, qr/<form/, 'render produces <form>');
    like($html, qr/name="username"/, 'input has name');
    like($html, qr/type="text"/, 'input has type text');
    like($html, qr/value="alice"/, 'input has value');
    like($html, qr/required/, 'required attribute');
    like($html, qr/maxlength="50"/, 'maxlength attribute');
    like($html, qr/placeholder="Enter name"/, 'placeholder attribute');
    like($html, qr/<label[^>]*>Username<\/label>/, 'label rendered');
    like($html, qr/class="chandra-form"/, 'form has CSS class');
    like($html, qr/chandra-field/, 'field wrapper class');
    like($html, qr/chandra-error/, 'error placeholder');
}

# ---- password() ----
{
    my $f = Chandra::Form->new(id => 'f2');
    $f->password('pass', { label => 'Password', required => 1, minlength => 8 });
    my $html = $f->render;
    like($html, qr/type="password"/, 'password type');
    like($html, qr/name="pass"/, 'password name');
    like($html, qr/minlength="8"/, 'minlength attribute');
    like($html, qr/required/, 'required');
}

# ---- email() ----
{
    my $f = Chandra::Form->new(id => 'f3');
    $f->email('email', { label => 'Email', value => 'a@b.com' });
    my $html = $f->render;
    like($html, qr/type="email"/, 'email type');
    like($html, qr/value="a\@b\.com"/, 'email value');
}

# ---- textarea() ----
{
    my $f = Chandra::Form->new(id => 'f4');
    $f->textarea('bio', { label => 'Bio', rows => 4, value => 'Hello' });
    my $html = $f->render;
    like($html, qr/<textarea/, 'textarea tag');
    like($html, qr/name="bio"/, 'textarea name');
    like($html, qr/rows="4"/, 'rows attribute');
    like($html, qr/>Hello<\/textarea>/, 'textarea content');
}

# ---- select() ----
{
    my $f = Chandra::Form->new(id => 'f5');
    $f->select('theme', {
        label   => 'Theme',
        options => [
            { value => 'light', label => 'Light' },
            { value => 'dark',  label => 'Dark' },
            { value => 'auto',  label => 'System' },
        ],
        value => 'dark',
    });
    my $html = $f->render;
    like($html, qr/<select/, 'select tag');
    like($html, qr/name="theme"/, 'select name');
    like($html, qr/<option value="light">Light<\/option>/, 'option light');
    like($html, qr/<option value="dark" selected>Dark<\/option>/, 'dark selected');
    like($html, qr/<option value="auto">System<\/option>/, 'option auto');
}

# ---- checkbox() ----
{
    my $f = Chandra::Form->new(id => 'f6');
    $f->checkbox('agree', { label => 'I agree', checked => 1 });
    my $html = $f->render;
    like($html, qr/type="checkbox"/, 'checkbox type');
    like($html, qr/name="agree"/, 'checkbox name');
    like($html, qr/checked/, 'checked attribute');
    like($html, qr/value="1"/, 'default value');
    like($html, qr/chandra-field-checkbox/, 'checkbox class');
    # Label should be after input for checkboxes
    like($html, qr/<input[^>]*>.*<label/s, 'label after checkbox');
}

# ---- radio() ----
{
    my $f = Chandra::Form->new(id => 'f7');
    $f->radio('priority', {
        label   => 'Priority',
        options => [
            { value => 'low',    label => 'Low' },
            { value => 'medium', label => 'Medium' },
            { value => 'high',   label => 'High' },
        ],
        value => 'medium',
    });
    my $html = $f->render;
    like($html, qr/type="radio"/, 'radio type');
    like($html, qr/name="priority"/, 'radio name');
    like($html, qr/value="medium" checked/, 'medium checked');
    like($html, qr/chandra-field-radio/, 'radio class');
    like($html, qr/chandra-radio-option/, 'radio option wrapper');
    # Should have 3 radio options
    my @radios = ($html =~ /type="radio"/g);
    is(scalar @radios, 3, 'three radio buttons');
}

# ---- number() ----
{
    my $f = Chandra::Form->new(id => 'f8');
    $f->number('qty', { label => 'Qty', min => 1, max => 99, step => 1, value => 10 });
    my $html = $f->render;
    like($html, qr/type="number"/, 'number type');
    like($html, qr/min="1"/, 'min attribute');
    like($html, qr/max="99"/, 'max attribute');
    like($html, qr/step="1"/, 'step attribute');
    like($html, qr/value="10"/, 'value');
}

# ---- range() ----
{
    my $f = Chandra::Form->new(id => 'f9');
    $f->range('vol', { label => 'Volume', min => 0, max => 100, value => 75 });
    my $html = $f->render;
    like($html, qr/type="range"/, 'range type');
    like($html, qr/min="0"/, 'min');
    like($html, qr/max="100"/, 'max');
    like($html, qr/value="75"/, 'value');
}

# ---- hidden() ----
{
    my $f = Chandra::Form->new(id => 'f10');
    $f->hidden('token', { value => 'abc123' });
    my $html = $f->render;
    like($html, qr/type="hidden"/, 'hidden type');
    like($html, qr/value="abc123"/, 'hidden value');
    unlike($html, qr/<label[^>]*for="f10-token"/, 'no label for hidden');
}

# ---- submit() ----
{
    my $f = Chandra::Form->new(id => 'f11');
    $f->text('name', { label => 'Name' });
    $f->submit('Save');
    my $html = $f->render;
    like($html, qr/<button type="submit"[^>]*>Save<\/button>/, 'submit button');
    like($html, qr/chandra-submit/, 'submit class');
}

# ---- Default submit label ----
{
    my $f = Chandra::Form->new(id => 'f12');
    $f->text('x', {});
    my $html = $f->render;
    like($html, qr/>Submit<\/button>/, 'default submit label');
}

# ---- Chaining ----
{
    my $f = Chandra::Form->new(id => 'chain');
    my $result = $f->text('a', {})->password('b', {})->email('c', {})->submit('Go');
    is($result, $f, 'all methods chain');
    is($f->field_count, 3, '3 fields after chain');
}

# ---- group() ----
{
    my $f = Chandra::Form->new(id => 'grp');
    $f->text('name', { label => 'Name' });
    $f->group('Appearance' => sub {
        $f->select('theme', {
            label => 'Theme',
            options => [{ value => 'dark', label => 'Dark' }],
        });
        $f->number('font', { label => 'Font Size' });
    });
    $f->text('other', { label => 'Other' });
    my $html = $f->render;
    like($html, qr/<fieldset class="chandra-group">/, 'fieldset rendered');
    like($html, qr/<legend>Appearance<\/legend>/, 'legend rendered');
    like($html, qr/<\/fieldset>/, 'fieldset closed');
}

# ---- bind_js() ----
{
    my $f = Chandra::Form->new(id => 'js-test');
    my $js = $f->bind_js;
    like($js, qr/js-test/, 'JS contains form id');
    like($js, qr/addEventListener/, 'JS has event listener');
    like($js, qr/submit/, 'JS handles submit');
    like($js, qr/change/, 'JS handles change');
    like($js, qr/_form_submit/, 'JS invokes _form_submit');
}

# ---- set_values_js() ----
{
    my $f = Chandra::Form->new(id => 'sv-test');
    my $js = $f->set_values_js({ name => 'bob', age => 30 });
    like($js, qr/sv-test/, 'set_values JS has form id');
    like($js, qr/bob/, 'JS contains value');
}

# ---- get_values_js() ----
{
    my $f = Chandra::Form->new(id => 'gv-test');
    my $js = $f->get_values_js;
    like($js, qr/gv-test/, 'get_values JS has form id');
    like($js, qr/_form_values/, 'JS invokes _form_values');
}

# ---- show_errors_js() ----
{
    my $f = Chandra::Form->new(id => 'err-test');
    $f->text('username', {});
    my $js = $f->show_errors_js({ username => 'Required' });
    like($js, qr/err-test-username/, 'error JS has field id');
    like($js, qr/Required/, 'error message in JS');
}

# ---- clear_errors_js() ----
{
    my $f = Chandra::Form->new(id => 'clr-test');
    my $js = $f->clear_errors_js;
    like($js, qr/clr-test/, 'clear JS has form id');
    like($js, qr/chandra-error/, 'targets error spans');
}

# ---- on_change() global ----
{
    my $f = Chandra::Form->new(id => 'oc1');
    my @changes;
    $f->on_change(sub { push @changes, [@_] });
    ok(1, 'global on_change registered');
}

# ---- on_change() field-specific ----
{
    my $f = Chandra::Form->new(id => 'oc2');
    my $theme_val;
    $f->on_change('theme', sub { $theme_val = $_[0] });
    ok(1, 'field on_change registered');
}

# ---- action() get/set ----
{
    my $f = Chandra::Form->new(id => 'act');
    is($f->action, undef, 'no action initially');
    my $cb = sub { 42 };
    $f->action($cb);
    is(ref($f->action), 'CODE', 'action set');
}

# ---- Custom form class ----
{
    my $f = Chandra::Form->new(id => 'cls', class => 'dark-theme');
    my $html = $f->render;
    like($html, qr/class="chandra-form dark-theme"/, 'custom class appended');
}

# ---- HTML escaping ----
{
    my $f = Chandra::Form->new(id => 'esc');
    $f->text('data', {
        label       => 'A & B',
        placeholder => 'Use "quotes"',
        value       => '<script>alert(1)</script>',
    });
    my $html = $f->render;
    like($html, qr/A &amp; B/, 'label escaped');
    like($html, qr/&lt;script&gt;/, 'value escaped');
    like($html, qr/Use &quot;quotes&quot;/, 'placeholder escaped');
}

# ---- Multiple field types in one form ----
{
    my $f = Chandra::Form->new(id => 'multi');
    $f->text('name', { label => 'Name' });
    $f->email('email', { label => 'Email' });
    $f->password('pass', { label => 'Pass' });
    $f->textarea('notes', { label => 'Notes' });
    $f->select('role', {
        label => 'Role',
        options => [{ value => 'admin', label => 'Admin' }],
    });
    $f->checkbox('active', { label => 'Active' });
    $f->radio('level', {
        options => [{ value => '1', label => 'One' }],
    });
    $f->number('age', { label => 'Age' });
    $f->range('score', { label => 'Score' });
    $f->hidden('id', { value => '42' });
    $f->submit('Create');

    is($f->field_count, 10, '10 fields');
    is_deeply($f->fields,
        [qw(name email pass notes role active level age score id)],
        'field names in order');

    my $html = $f->render;
    like($html, qr/<form.*<\/form>/s, 'complete form rendered');
    # Count field types
    like($html, qr/type="text"/, 'has text');
    like($html, qr/type="email"/, 'has email');
    like($html, qr/type="password"/, 'has password');
    like($html, qr/<textarea/, 'has textarea');
    like($html, qr/<select/, 'has select');
    like($html, qr/type="checkbox"/, 'has checkbox');
    like($html, qr/type="radio"/, 'has radio');
    like($html, qr/type="number"/, 'has number');
    like($html, qr/type="range"/, 'has range');
    like($html, qr/type="hidden"/, 'has hidden');
}

done_testing;
