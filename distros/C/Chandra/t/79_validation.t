#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 19;

BEGIN {
    use_ok('Chandra::Form');
    use_ok('Chandra::Form::Validator');
}

# ── Build a form with validation rules ───────────────────

my $form = Chandra::Form->new(
    id     => 'test-form',
    action => sub {},
);

$form->text('username', {
    label     => 'Username',
    required  => 1,
    minlength => 3,
    maxlength => 20,
    pattern   => '^[a-zA-Z0-9]+$',
    pattern_msg => 'Letters and numbers only',
});

$form->email('email', {
    label    => 'Email',
    required => 1,
});

$form->number('age', {
    label => 'Age',
    min   => 18,
    max   => 120,
});

$form->password('password', {
    label     => 'Password',
    required  => 1,
    minlength => 8,
    validate  => sub {
        my ($val) = @_;
        return 'Must contain a number' unless $val =~ /\d/;
        return undef;
    },
});

$form->text('optional', { label => 'Optional' });

# ── Test: valid data ─────────────────────────────────────

my $errors = Chandra::Form::Validator->validate($form, {
    username => 'alice',
    email    => 'alice@example.com',
    age      => 25,
    password => 'secret123',
});
ok(!$errors, 'valid data passes');

# ── Test: required fields ────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => '',
    email    => '',
    password => '',
});
ok($errors, 'empty required fields fail');
like($errors->{username}, qr/required/i, 'username required error');
like($errors->{email}, qr/required/i, 'email required error');
like($errors->{password}, qr/required/i, 'password required error');

# ── Test: minlength ──────────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'ab',
    email    => 'a@b.com',
    password => 'short1',  # has digit, but too short
});
like($errors->{username}, qr/at least 3/, 'username minlength error');
like($errors->{password}, qr/at least 8/, 'password minlength error');

# ── Test: maxlength ──────────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'a' x 25,
    email    => 'a@b.com',
    password => 'longpassword1',
});
like($errors->{username}, qr/at most 20/, 'username maxlength error');

# ── Test: pattern ────────────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'has spaces',
    email    => 'a@b.com',
    password => 'password1',
});
like($errors->{username}, qr/Letters and numbers/, 'pattern custom message');

# ── Test: min/max ────────────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'alice',
    email    => 'a@b.com',
    age      => 15,
    password => 'password1',
});
like($errors->{age}, qr/at least 18/, 'age min error');

$errors = Chandra::Form::Validator->validate($form, {
    username => 'alice',
    email    => 'a@b.com',
    age      => 200,
    password => 'password1',
});
like($errors->{age}, qr/at most 120/, 'age max error');

# ── Test: email format ───────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'alice',
    email    => 'not-an-email',
    password => 'password1',
});
like($errors->{email}, qr/email/i, 'invalid email error');

# ── Test: custom validator ───────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'alice',
    email    => 'a@b.com',
    password => 'nodigits',
});
like($errors->{password}, qr/number/, 'custom validator error');

# ── Test: optional field ─────────────────────────────────

$errors = Chandra::Form::Validator->validate($form, {
    username => 'alice',
    email    => 'a@b.com',
    password => 'password1',
    optional => '',
});
ok(!$errors, 'empty optional field passes');

# ── Test: JS generation ─────────────────────────────────

my $js = Chandra::Form::Validator->validation_js($form);
ok(length($js) > 50, 'validation JS generated');
like($js, qr/required/, 'JS contains required rule');
like($js, qr/minlength/, 'JS contains minlength rule');

done_testing;
