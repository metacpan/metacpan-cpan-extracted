# -*- Mode: Perl; -*-

=head1 NAME

1_validate_11_no_extra.t - Test CGI::Ex::Validate's ability to not allow extra form fields

=cut

use strict;
use Test::More tests => 13;

use_ok('CGI::Ex::Validate');

my ($v, $e);

sub validate { CGI::Ex::Validate::validate(@_) }

###----------------------------------------------------------------###

### test single group for extra fields
$v = {
  'group no_extra_fields' => 1,
  foo => {max_len => 10},
};

$e = validate({}, $v);
ok(! $e);

$e = validate({foo => "foo"}, $v);
ok(! $e);

$e = validate({foo => "foo", bar => "bar"}, $v);
ok($e);

$e = validate({bar => "bar"}, $v);
ok($e);


### test on failed validate if
$v = {
  'group no_extra_fields' => 1,
  'group validate_if' => 'baz',
  foo => {max_len => 10},
};

$e = validate({}, $v);
ok(! $e);

$e = validate({foo => "foo"}, $v);
ok(! $e);

$e = validate({foo => "foo", bar => "bar"}, $v);
ok(! $e);

$e = validate({bar => "bar"}, $v);
ok(! $e);

### test on successful validate if
$v = {
  'group no_extra_fields' => 1,
  'group validate_if' => 'baz',
  foo => {max_len => 10},
  baz => {max_len => 10},
};

$e = validate({baz => 1}, $v);
ok(! $e);

$e = validate({baz => 1, foo => "foo"}, $v);
ok(! $e);

$e = validate({baz => 1, foo => "foo", bar => "bar"}, $v);
ok($e);

$e = validate({baz => 1, bar => "bar"}, $v);
ok($e);

