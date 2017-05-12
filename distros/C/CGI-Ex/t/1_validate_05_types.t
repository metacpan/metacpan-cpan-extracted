# -*- Mode: Perl; -*-

=head1 NAME

1_validate_05_types.t - Test CGI::Ex::Validate's ability to do multitudinous types of validate

=cut

use strict;
use Test::More tests => 190;

use_ok('CGI::Ex::Validate');

my $v;
my $e;

sub validate { scalar CGI::Ex::Validate->new({as_array_title=>'',as_string_join=>"\n"})->validate(@_) }

### required
$v = {foo => {required => 1}};
$e = validate({}, $v);
ok($e, 'required => 1 - fail');

$e = validate({foo => 1}, $v);
ok(! $e, 'required => 1 - good');

### validate_if
$v = {foo => {required => 1, validate_if => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'validate_if - true');

$e = validate({bar => 1}, $v);
ok($e, 'validate_if - false');

$v = {text1 => {required => 1, validate_if => 'text2 was_valid'}, text2 => {validate_if => 'text3'}};
$e = validate({}, $v);
ok(! $e, "Got no error on validate_if with was_valid");
$e = validate({text2 => 1}, $v);
ok(! $e, "Got no error on validate_if with was_valid with non-validated data");
$e = validate({text3 => 1}, $v);
ok(! $e, "Got no error on validate_if with was_valid with validated - bad data");
$e = validate({text2 => 1, text3 => 1}, $v);
ok(! $e, "Got error on validate_if with was_valid with validated - good data");
$e = validate({text1 => 1, text2 => 1, text3 => 1}, $v);
ok(! $e, "No error on validate_if with was_valid with validated - good data");

$v = {text1 => {required => 1, validate_if => 'text2 had_error'}, text2 => {required => 1}};
$e = validate({}, $v);
ok($e, "Got error on validate_if with had_error");
$e = validate({text2 => 1}, $v);
ok(! $e, "No error on validate_if with had_error and bad_data");
$e = validate({text1 => 1}, $v);
ok($e && ! $e->as_hash->{text1_error}, "No error on validate_if with had_error and good data");

$e = validate({text1 => ""}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2'}});
ok(!$e, "validate_ifstr - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2'}});
ok($e, "validate_ifstr - had error");

$e = validate({text1 => ""}, {'m/^(tex)t1$/' => {required => 1, validate_if => {field => '$1t2',required => 1}}});
ok(!$e, "validate_if - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => {field => '$1t2',required => 1}}});
ok($e, "validate_if - had error");

$e = validate({text1 => ""}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2 was_valid'}});
ok(!$e, "was valid - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2 was_valid'}});
ok(!$e, "was valid - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2 was_valid'}, text2 => {required => 1}, 'group order' => [qw(text2)]});
ok($e, "was valid - had error");

### required_if
$v = {foo => {required_if => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'required_if - false');

$e = validate({bar => 1}, $v);
ok($e , 'required_if - true');

### max_values
$v = {foo => {required => 1}};
$e = validate({foo => [1,2]}, $v);
ok($e, 'max_values');

$v = {foo => {max_values => 2}};
$e = validate({}, $v);
ok(! $e, 'max_values');

$e = validate({foo => "str"}, $v);
ok(! $e, 'max_values');

$e = validate({foo => [1]}, $v);
ok(! $e, 'max_values');

$e = validate({foo => [1,2]}, $v);
ok(! $e, 'max_values');

$e = validate({foo => [1,2,3]}, $v);
ok($e, 'max_values');

### min_values
$v = {foo => {min_values => 3, max_values => 10}};
$e = validate({foo => [1,2,3]}, $v);
ok(! $e, 'min_values');

$e = validate({foo => [1,2,3,4]}, $v);
ok(! $e, 'min_values');

$e = validate({foo => [1,2]}, $v);
ok($e, 'min_values');

$e = validate({foo => "str"}, $v);
ok($e, 'min_values');

$e = validate({}, $v);
ok($e, 'min_values');

### enum
$v = {foo => {enum => [1, 2, 3]}, bar => {enum => "1 || 2||3"}};
$e = validate({}, $v);
ok($e, 'enum');

$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'enum');

$e = validate({foo => 1, bar => 2}, $v);
ok(! $e, 'enum');

$v->{'foo'}->{'match'} = 'm/3/';
$e = validate({foo => 1, bar => 2}, $v);
ok($e, 'enum');
is("$e", "Foo contains invalid characters.", 'enum shortcircuit');

$e = validate({foo => 4, bar => 1}, $v);
ok($e, 'enum');
is("$e", "Foo is not in the given list.", 'enum shortcircuit');

# equals
$v = {foo => {equals => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'equals');

$e = validate({foo => 1}, $v);
ok($e, 'equals');

$e = validate({bar => 1}, $v);
ok($e, 'equals');

$e = validate({foo => 1, bar => 2}, $v);
ok($e, 'equals');

$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'equals');

$v = {foo => {equals => '"bar"'}};
$e = validate({foo => 1, bar => 1}, $v);
ok($e, 'equals');

$e = validate({foo => 'bar', bar => 1}, $v);
ok(! $e, 'equals');

$e = validate({text1 => "foo", text2 =>  "bar"}, {'m/^(tex)t1$/' => {equals => '$1t2'}});
ok($e, "equals - had error");

$e = validate({text1 => "foo", text2 => "foo"}, {'m/^(tex)t1$/' => {equals => '$1t2'}});
ok(!$e, "equals - no error");


### min_len
$v = {foo => {min_len => 10}};
$e = validate({}, $v);
ok($e, 'min_len');

$e = validate({foo => ""}, $v);
ok($e, 'min_len');

$e = validate({foo => "123456789"}, $v);
ok($e, 'min_len');

$e = validate({foo => "1234567890"}, $v);
ok(! $e, 'min_len');

### max_len
$v = {foo => {max_len => 10}};
$e = validate({}, $v);
ok(! $e, 'max_len');

$e = validate({foo => ""}, $v);
ok(! $e, 'max_len');

$e = validate({foo => "1234567890"}, $v);
ok(! $e, 'max_len');

$e = validate({foo => "12345678901"}, $v);
ok($e, 'max_len');

### match
$v = {foo => {match => qr/^\w+$/}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc."}, $v);
ok($e, 'match');

$v = {foo => {match => [qr/^\w+$/, qr/^[a-z]+$/]}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc1"}, $v);
ok($e, 'match');

$v = {foo => {match => 'm/^\w+$/'}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc."}, $v);
ok($e, 'match');

$v = {foo => {match => 'm/^\w+$/ || m/^[a-z]+$/'}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc1"}, $v);
ok($e, 'match');

$v = {foo => {match => '! m/^\w+$/'}};
$e = validate({foo => "abc"}, $v);
ok($e, 'match');

$e = validate({foo => "abc."}, $v);
ok(! $e, 'match');

$v = {foo => {match => 'm/^\w+$/'}};
$e = validate({}, $v);
ok($e, 'match');

$v = {foo => {match => '! m/^\w+$/'}};
$e = validate({}, $v);
ok(! $e, 'match');

### compare
$v = {foo => {compare => '> 0'}};
$e = validate({}, $v);
ok($e, 'compare');
$v = {foo => {compare => '== 0'}};
$e = validate({}, $v);
ok(! $e, 'compare');
$v = {foo => {compare => '< 0'}};
$e = validate({}, $v);
ok($e, 'compare');

$v = {foo => {compare => '> 10'}};
$e = validate({foo => 11}, $v);
ok(! $e, 'compare');
$e = validate({foo => 10}, $v);
ok($e, 'compare');

$v = {foo => {compare => '== 10'}};
$e = validate({foo => 11}, $v);
ok($e, 'compare');
$e = validate({foo => 10}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => '< 10'}};
$e = validate({foo => 9}, $v);
ok(! $e, 'compare');
$e = validate({foo => 10}, $v);
ok($e, 'compare');

$v = {foo => {compare => '>= 10'}};
$e = validate({foo => 10}, $v);
ok(! $e, 'compare');
$e = validate({foo => 9}, $v);
ok($e, 'compare');

$v = {foo => {compare => '!= 10'}};
$e = validate({foo => 10}, $v);
ok($e, 'compare');
$e = validate({foo => 9}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => '<= 10'}};
$e = validate({foo => 11}, $v);
ok($e, 'compare');
$e = validate({foo => 10}, $v);
ok(! $e, 'compare');


$v = {foo => {compare => 'gt ""'}};
$e = validate({}, $v);
ok($e, 'compare');
$v = {foo => {compare => 'eq ""'}};
$e = validate({}, $v);
ok(! $e, 'compare');
$v = {foo => {compare => 'lt ""'}};
$e = validate({}, $v);
ok($e, 'compare'); # 68

$v = {foo => {compare => 'gt "c"'}};
$e = validate({foo => 'd'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'c'}, $v);
ok($e, 'compare');

$v = {foo => {compare => 'eq c'}};
$e = validate({foo => 'd'}, $v);
ok($e, 'compare');
$e = validate({foo => 'c'}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => 'lt c'}};
$e = validate({foo => 'b'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'c'}, $v);
ok($e, 'compare');

$v = {foo => {compare => 'ge c'}};
$e = validate({foo => 'c'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'b'}, $v);
ok($e, 'compare');

$v = {foo => {compare => 'ne c'}};
$e = validate({foo => 'c'}, $v);
ok($e, 'compare');
$e = validate({foo => 'b'}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => 'le c'}};
$e = validate({foo => 'd'}, $v);
ok($e, 'compare');
$e = validate({foo => 'c'}, $v);
ok(! $e, 'compare'); # 80

### sql
### can't really do anything here without prompting for a db connection

### custom
my $n = 1;
$v = {foo => {custom => $n}};
$e = validate({}, $v);
ok(! $e, 'custom');
$e = validate({foo => "str"}, $v);
ok(! $e, 'custom');

$n = 0;
$v = {foo => {custom => $n}};
$e = validate({}, $v);
ok($e, 'custom');
$e = validate({foo => "str"}, $v);
ok($e, 'custom');

$n = sub { my ($key, $val) = @_; return defined($val) ? 1 : 0};
$v = {foo => {custom => $n}};
$e = validate({}, $v);
ok($e, 'custom');
$e = validate({foo => "str"}, $v);
ok(! $e, 'custom');

$e = validate({foo => "str"}, {foo => {custom => sub { my ($k, $v) = @_; die "Always fail ($v)\n" }}});
ok($e, 'Got an error');
is($e->as_hash->{'foo_error'}, "Always fail (str)", "Passed along the message from die");

### type checks
$v = {foo => {type => 'ip', match => 'm/^203\./'}};
$e = validate({foo => '209.108.25'}, $v);
ok($e, 'type ip');
is("$e", 'Foo did not match type ip.', 'type ip'); # make sure they short circuit
$e = validate({foo => '209.108.25.111'}, $v);
ok($e, 'type ip - but had match error');
is("$e", 'Foo contains invalid characters.', 'type ip');
$e = validate({foo => '203.108.25.111'}, $v);
ok(! $e, 'type ip');

$v = {foo => {type => 'domain'}};
$e = validate({foo => 'bar.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => 'bing.bar.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => 'bi-ng.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => '123456789012345678901234567890123456789012345678901234567890123.com'}, $v);
ok(! $e, 'type domain');

$e = validate({foo => 'com'}, $v);
ok($e, 'type domain');
$e = validate({foo => 'bi-.com'}, $v);
ok($e, 'type domain');
$e = validate({foo => 'bi..com'}, $v);
ok($e, 'type domain');
$e = validate({foo => '1234567890123456789012345678901234567890123456789012345678901234.com'}, $v);
ok($e, 'type domain');

ok(!validate({n => $_}, {n => {type => 'num'}}),  "Type num $_")  for qw(0 2 23 -0 -2 -23 0.0 .1 0.1 0.10 1.0 1.01);
ok(!validate({n => $_}, {n => {type => 'int'}}),  "Type int $_")  for qw(0 2 23 -0 -2 -23 2147483647 -2147483648);
ok(!validate({n => $_}, {n => {type => 'uint'}}), "Type uint $_") for qw(0 2 23 4294967295);
ok(validate({n => $_}, {n => {type  => 'num'}}),  "Type num invalid $_")  for qw(0a a2 -0a 0..0 00 001 1.);
ok(validate({n => $_}, {n => {type  => 'int'}}),  "Type int invalid $_")  for qw(1.1 0.1 0.0 -1.1 0a a2 a 00 001 2147483648 -2147483649);
ok(validate({n => $_}, {n => {type  => 'uint'}}), "Type uint invalid $_") for qw(-1 -0 1.1 0.1 0.0 -1.1 0a a2 a 00 001 4294967296);

### min_in_set checks
$v = {foo => {min_in_set => '2 of foo bar baz', max_values => 5}};
$e = validate({foo => 1}, $v);
ok($e, 'min_in_set');
$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'min_in_set');
$e = validate({foo => 1, bar => ''}, $v); # empty string doesn't count as value
ok($e, 'min_in_set');
$e = validate({foo => 1, bar => 0}, $v);
ok(! $e, 'min_in_set');
$e = validate({foo => [1, 2]}, $v);
ok(! $e, 'min_in_set');
$e = validate({foo => [1]}, $v);
ok($e, 'min_in_set');
$v = {foo => {min_in_set => '2 foo bar baz', max_values => 5}};
$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'min_in_set');

### max_in_set checks
$v = {foo => {max_in_set => '2 of foo bar baz', max_values => 5}};
$e = validate({foo => 1}, $v);
ok(! $e, 'max_in_set');
$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'max_in_set');
$e = validate({foo => 1, bar => 1, baz => 1}, $v);
ok($e, 'max_in_set');
$e = validate({foo => [1, 2]}, $v);
ok(! $e, 'max_in_set');
$e = validate({foo => [1, 2, 3]}, $v);
ok($e, 'max_in_set');

### validate_if revisited (but negated - uses max_in_set)
$v = {foo => {required => 1, validate_if => '! bar'}};
$e = validate({}, $v);
ok($e, 'validate_if - negated');

$e = validate({bar => 1}, $v);
ok(! $e, 'validate_if - negated');

### default value
my $f = {};
$v = {foo => {required => 1, default => 'hmmmm'}};
$e = validate($f, $v);
ok(! $e, 'default');

ok($f->{foo} && $f->{foo} eq 'hmmmm', 'had right default');

