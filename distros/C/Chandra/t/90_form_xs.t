#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::Form;

package MockFormApp;
our (%bound, @dispatched);
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }
sub dispatch_eval { my ($self, $js) = @_; push @dispatched, $js; return $self }

package main;

# --- constructor keys ---
{
    my $app = MockFormApp->new;
    my $f = Chandra::Form->new(id => 'keys', method => 'post', class => 'wide', app => $app, other => 1);
    is($f->{method}, 'post', 'method kept');
    is($f->{class}, 'wide', 'class kept');
    is($f->{app}, $app, 'app kept');
    ok(!exists $f->{other}, 'an unknown key is not stored');
    eval { Chandra::Form->new(action => 'not code') };
    like($@, qr/'action' must be a coderef/, 'an action that is not code croaks');
}

# --- every field type, with and without options, inside and outside a group ---
{
    my $f = Chandra::Form->new(id => 'fields');
    my @types = qw(text password email textarea _select checkbox radio number range hidden);
    for my $t (@types) {
        $f->$t("${t}_plain");
        $f->$t("${t}_opts", { label => ucfirst $t });
        $f->$t("${t}_odd", 'not a hash');
    }
    $f->group('Grouped', sub { $f->$_("${_}_grouped", { label => 'g' }) for @types });
    is($f->field_count, 40, 'forty fields');
    my $fields = $f->{_fields};
    is($fields->[0]{name}, 'text_plain', 'the first is the plain text field');
    is_deeply($fields->[0]{opts}, {}, 'with empty options');
    is($fields->[1]{opts}{label}, 'Text', 'the second has its options');
    ok(!exists $fields->[0]{group}, 'no group outside one');
    my ($grouped) = grep { $_->{name} eq 'password_grouped' } @$fields;
    is($grouped->{group}, 'Grouped', 'a field made inside a group carries it');
    is_deeply($f->{_groups}, ['Grouped'], 'the group is listed');
    eval { $f->group('Bad', 'not code') };
    like($@, qr/second argument must be a coderef/, 'a group without code croaks');
    is($f->submit, $f, 'submit without a label keeps the default');
    is($f->{_submit_label}, 'Submit', 'which is Submit');
    $f->submit('Go');
    is($f->{_submit_label}, 'Go', 'and a label replaces it');
    like($f->render, qr/Go/, 'render shows the submit label');
}

# --- render and fields with odd entries ---
{
    my $f = Chandra::Form->new(id => 'odd');
    $f->text('name', { label => 'Name' });
    $f->radio('choice', { options => [ 'a', 'b' ] });
    push @{ $f->{_fields} }, 'not a ref', { name => 'no type' }, { type => 'weird', name => 'weird', opts => {} }, { type => 'text', opts => {} };
    my $html = $f->render;
    like($html, qr/name="name"/, 'the text field renders past the odd entries');
    $f->{_submit_label} = undef;
    unlike($f->render, qr/chandra-submit/, 'no submit button without a label');
    is_deeply($f->fields, ['name', 'choice', 'no type', 'weird'], 'fields lists the names of the hashes that have one');
    like($f->set_values_js({ code => sub { } }), qr/\{\}/, 'values that cannot be encoded become an empty object');
}

# --- dispatch shapes ---
{
    my $f = Chandra::Form->new(id => 'dispatch');
    my (@changes, @values);
    $f->on_change(sub { push @changes, [@_] });
    $f->dispatch('_form_submit', '"a string"');
    $f->dispatch('_form_change', '{"id":"dispatch"}');
    $f->dispatch('_form_change', '{"id":"dispatch","field":null}');
    is(scalar @changes, 0, 'a change without a field runs nothing');
    $f->{_on_change} = 'not a ref';
    $f->dispatch('_form_change', '{"id":"dispatch","field":"x","value":"y"}');
    is_deeply(\@changes, [['x', 'y']], 'with no field table the global handler still runs');
    $f->dispatch('_form_values', '{"id":"dispatch","data":{"a":1}}');
    $f->{_get_values_cb} = sub { push @values, $_[0] };
    $f->dispatch('_form_values', '{"id":"dispatch","data":{"a":1}}');
    is_deeply(\@values, [ { a => 1 } ], 'a pending values callback gets the data');
    ok(!defined $f->{_get_values_cb}, 'and is cleared');
    $f->dispatch('_form_values', '{"id":"dispatch"}');
    eval { $f->on_change('field') };
    like($@, qr/requires a coderef or \(field_name, coderef\)/, 'on_change with a name and no code croaks');
}

# --- routing events to attached forms ---
{
    %MockFormApp::bound = ();
    @MockFormApp::dispatched = ();
    my $app = MockFormApp->new;
    my $f = Chandra::Form->new(id => 'routed');
    my @got;
    $f->action(sub { push @got, $_[0] });
    is($f->attach($app), $f, 'attach returns the form');
    is_deeply([ sort keys %MockFormApp::bound ], [qw(_form_change _form_input _form_submit _form_values)], 'the four events are bound');
    is(scalar @MockFormApp::dispatched, 1, 'and the form script is dispatched');
    my $second = Chandra::Form->new(id => 'second');
    $second->attach($app);
    is(scalar keys %MockFormApp::bound, 4, 'a second attach binds nothing more');
    $MockFormApp::bound{_form_submit}->('{"id":"routed","data":{"k":"v"}}');
    is_deeply(\@got, [ { k => 'v' } ], 'a bound event reaches the right form');
    Chandra::Form->_route_event('_form_submit', 'not json');
    Chandra::Form->_route_event('_form_submit', '[1]');
    Chandra::Form->_route_event('_form_submit', '{"noid":1}');
    Chandra::Form->_route_event('_form_submit', '{"id":"nobody"}');
    is(scalar @got, 1, 'bad JSON, a list, no id and an unknown id reach no form');
    is($f->detach, $f, 'detach returns the form');
    Chandra::Form->_route_event('_form_submit', '{"id":"routed","data":{}}');
    is(scalar @got, 1, 'a detached form gets nothing');
    {
        no warnings 'redefine';
        local *Chandra::Form::bind_js = sub { undef };
        my $quiet = Chandra::Form->new(id => 'quiet');
        $quiet->attach($app);
        is(scalar @MockFormApp::dispatched, 2, 'a form with no script dispatches nothing');
    }
    my $noid = Chandra::Form->new;
    $noid->{id} = undef;
    eval { $noid->attach($app) };
    like($@, qr/form has no id/, 'a form without an id cannot attach');
    is($noid->detach, $noid, 'but detaches harmlessly');
}

# --- validation ---
{
    my $f = Chandra::Form->new(id => 'valid');
    eval { $f->validate('not a hash') };
    like($@, qr/validate\(\) requires a hashref/, 'validate wants a hash');
    $f->text('plain', { required => 1 });
    $f->text('labelled', { required => 1, label => 'The label' });
    $f->text('messaged', { required => 1, required_msg => 'Say something' });
    $f->text('short', { minlength => 3, minlength_msg => 'Too short' });
    $f->text('long', { maxlength => 3 });
    $f->text('coded', { pattern => qr/^\d+$/ });
    $f->text('stringy', { pattern => '^[a-z]+$', pattern_msg => 'Letters only' });
    $f->text('broken', { pattern => '(' });
    $f->hidden('token');
    push @{ $f->{_fields} }, 'not a ref', { type => 'text', opts => {} }, { type => 'submit', name => 'go', opts => {} }, { type => 'text', name => 'noopts', opts => 'x' };
    my $errors = $f->validate({ short => 'ab', long => 'abcd', coded => 'x', stringy => '123', broken => 'z' });
    is_deeply($errors, {
        plain    => 'plain is required',
        labelled => 'The label is required',
        messaged => 'Say something',
        short    => 'Too short',
        long     => 'Must be at most 3 characters',
        coded    => 'Invalid format',
        stringy  => 'Letters only',
        broken   => 'Invalid format',
    }, 'every rule reports in its own words');
    ok(!defined $f->validate({ plain => 'p', labelled => 'l', messaged => 'm', coded => '42', stringy => 'abc' }), 'valid data gives undef, with the broken pattern left empty');
    $f->{_fields} = 'not a ref';
    ok(!defined $f->validate({}), 'no field list gives undef');
}

done_testing;
