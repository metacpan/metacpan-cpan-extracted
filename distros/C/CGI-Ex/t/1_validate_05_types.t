# -*- Mode: Perl; -*-

=head1 NAME

1_validate_05_types.t - Test CGI::Ex::Validate's ability to do multitudinous types of validate

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Test::More tests => 278;

use_ok('CGI::Ex::Validate');

my $v;
my $e;

sub validate { scalar CGI::Ex::Validate->new({as_array_title=>'',as_string_join=>"\n"})->validate(@_) }
sub validate_as_hash { my $e = validate(@_); $e ? $e->as_hash({as_hash_suffix => ''}) : undef }

# mini-json
my %R = split / /, "\x0a \\n \x0d \\r \t \\t \b \\b \f \\f \x{2028} \\u2028 \x{2029} \\u2029 \\ \\\\ \" \\\"";
$R{pack 'C', $_} ||= sprintf '\u%.4X', $_ for 0x00 .. 0x1f;
sub to_json { &_e_val }
sub _e_array { '['.join(',', map { _e_val($_) } @{$_[0]}).']' }
sub _e_obj { my $o = shift; '{'.join(',', map { _e_str($_).':'._e_val($o->{$_}) } sort keys %$o).'}' }
sub _e_str { (my $s = shift) =~ s{([\x00-\x1f\x{2028}\x{2029}\\"])}{$R{$1}}gs; "\"$s\"" }
sub _e_val {
    my ($v, $r) = shift;
    return 'null' if ! defined $v;
    return $r eq 'HASH' ? _e_obj($v)
        : $r eq 'ARRAY' ? _e_array($v)
        : ($r eq 'SCALAR' || $r =~ /[Bb]ool/) ? ($$v ? 'true' : 'false')
        : (blessed $v and $r = $v->can('TO_JSON')) ? _e_val($v->$r)
        : _e_str($v)
        if $r = ref $v;
    my $c = (my $z = "0") & $v;
    return $v if length($c) && !($c ^ $c) && 0 + $v eq $v && $v * 0 == 0;
    return _e_str($v);
}

sub ok_val {
    my ($args, $val, $err) = @_;

    my $e = CGI::Ex::Validate->new->validate($args, $val);
    $e = $e->as_hash({as_hash_suffix => ''}) if $e;
    my $e_json = $e ? to_json($e) : '';

    my ($file, $pkg, $line) = caller;
    my $sub = (caller 1)[3] || 'main';
    $sub =~ s/.+:://;

    my $had_code_butnonref = ($val->{'foo'} && $val->{'foo'}->{'custom'} && ref($val->{'foo'}->{'custom'}) ne 'CODE');
    $_ = to_json($_) for $args, $val;
    $val =~ s/"custom":null/"custom":sub{...}/ if !$had_code_butnonref;
    $args = substr($args, 0, 70).'...' if length $args > 73;

    if (! defined $err) {
        ok(!$e, "$sub line $line - $val (args: $args) --> Shouldn't have error") || diag explain $e;
    } elsif (! $e) {
        ok(0, "$sub line $line - $val (args: $args) --> Should've had an error but did not");
        diag explain $err;
    } elsif (ref($err) eq ref(qr//)) {
        like($e_json, $err, "$sub line $line - $val (args: $args) --> Like: $err");
    } else {
        my $_err = to_json($err);
        is_deeply($e, $err, "$sub line $line - $val (args: $args) --> $_err") || diag explain [$e, $err];
    }
    return $e || undef;
}

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
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    $e = validate({}, $v);
    is $e, undef, 'enum';
};

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

$v = {'group type_ne_required' => 1, foo => {enum => [1, 2, 3]}, bar => {enum => "1 || 2||3"}};
$e = validate({}, $v);
is $e, undef, 'enum type_ne_required';

# equals
$v = {foo => {equals => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'equals');
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    $e = validate({}, $v);
    is $e, undef, 'equals';
};

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
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    $e = validate({}, $v);
    is $e, undef, 'min_len';
};

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
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    $e = validate({}, $v);
    is $e, undef, 'match type_ne_required';
};

$v = {foo => {match => '! m/^\w+$/'}};
$e = validate({}, $v);
ok(! $e, 'match');

### compare
$v = {foo => {compare => '> 0'}};
$e = validate({}, $v);
ok($e, 'compare');
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    $e = validate({}, $v);
    is $e, undef, 'compare type_ne_required';
};

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
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    $e = validate({}, $v);
    is $e, undef, 'custom - type_ne_required';
};

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
ok(!validate({n => $_}, {n => {type => 'unum'}}), "Type unum $_") for qw(0 2 23 0.0 .1 0.1 0.10 1.0 1.01);
ok(!validate({n => $_}, {n => {type => 'int'}}),  "Type int $_")  for qw(0 2 23 -0 -2 -23 2147483647 -2147483648);
ok(!validate({n => $_}, {n => {type => 'uint'}}), "Type uint $_") for qw(0 2 23 4294967295);
ok(!validate({n => $_}, {n => {type => 'str'  }}), "Type str $_") for '', 12, qw(0 2 a);
ok(!validate({n => $_}, {n => {type => 'code' }}), "Type code") for undef, sub {};

ok(validate({n => $_}, {n => {type  => 'num'}}),  "Type num invalid $_")  for qw(0a a2 -0a 0..0 00 001 1.);
ok(validate({n => $_}, {n => {type  => 'int'}}),  "Type int invalid $_")  for qw(1.1 0.1 0.0 -1.1 0a a2 a 00 001 2147483648 -2147483649);
ok(validate({n => $_}, {n => {type  => 'uint'}}), "Type uint invalid $_") for qw(-1 -0 1.1 0.1 0.0 -1.1 0a a2 a 00 001 4294967296);

ok(validate({n => $_}, {n => {type  => 'str' }}), "Type str invalid $_") for {}, sub {}, [];
ok(validate({n => $_}, {n => {type  => 'code'}}), "Type code invalid $_") for qw(1);

$v = {foo => {type => {bar => {required => 1}}, max_values => 2}};

ok_val({}, $v, {foo => 'Foo did not match type hash.'});
do {
    local $CGI::Ex::Validate::type_ne_required = 1;
    ok_val({}, $v, undef);
};

ok_val({foo => 1}, $v, {foo => 'Foo did not match type hash.'});
ok_val({foo => {}}, $v, {'foo.bar' => 'The field foo.bar is required.'});

ok_val({foo => {bar => 2}}, $v, undef);
ok_val({foo => {bar => 2}}, $v, undef);
ok_val({foo => [{bar => 2}]}, $v, undef);
ok_val({foo => [{bar => 2}, {bar => 3}]}, $v, undef);

$v = {foo => {type => []}};
ok_val({}, $v, undef);
ok_val({foo => [1]}, $v, undef);
ok_val({foo => [1,'s']}, $v, undef);

ok_val({foo => 1}, $v, {foo => 'Foo did not match type [].'});

$v = {foo => {type => [], coerce => 1}};
ok_val(my $f = {}, $v, undef);
is_deeply($f, {}, 'type line '.__LINE__.' - coerce (not passed)');
ok_val({foo => [1]}, $v, undef);
ok_val({foo => [1,'s']}, $v, undef);
for my $n (1, 0, '', undef) {
    ok_val(my $f = {foo => $n}, $v, undef);
    is_deeply($f, {foo => [$n]}, 'type line '.__LINE__.' - coerce '.(defined($n) ? $n : 'undef')) || debug $f;
}

$v = {foo => {type => 'array'}};
ok_val({foo => [1]}, $v, undef);
ok_val({foo => [1,'s']}, $v, undef);
ok_val({foo => 1}, $v, {foo => 'Foo did not match type array.'});

$v = {foo => {type => ['int']}};
ok_val({foo => [1]}, $v, undef);
ok_val({foo => [1,undef,2]}, {%$v, 'group type_ne_required' => 1}, undef);
ok_val({foo => [1,'s']}, $v, {foo => 'Foo did not match type int.'});
ok_val({foo => 1}, $v, {foo => 'Foo did not match type [].'});

$v = {foo => {type => ['int'], req => 1}};
ok_val({foo => [1,2,undef]}, $v, {foo => 'Foo is required.'});

$v = {foo => {type => ['str']}};
ok_val({foo => [1,undef,2,"bar",'']}, {%$v, 'group type_ne_required' => 1}, undef);
ok_val({foo => [1,2,"bar",'']}, $v, undef);


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
$f = {};
$v = {foo => {required => 1, default => 'hmmmm'}};
$e = validate($f, $v);
ok(! $e, 'default');

ok($f->{foo} && $f->{foo} eq 'hmmmm', 'had right default');


###----------------------------------------------------------------###

note 'nested types';

$v = {
    foo => {
        validate_if => 'foo',
        type => {
            baz => {required => 1}, # required only if "foo" exists
        },
    },
};
$e = validate_as_hash({}, $v);
ok(! $e, "Type hash, optional check") || debug $e;

$e = validate_as_hash({foo => 1}, $v);
is_deeply($e, {foo => 'Foo did not match type hash.'}, "Type hash, type check");


$e = validate_as_hash({foo => {}}, $v);
is_deeply($e, {'foo.baz' => 'The field foo.baz is required.'}, "Type hash, inner required check");

$e = validate_as_hash({foo => {baz => 1}}, $v);
ok(! $e, "Type hash, inner required ok");

$v = {
    foo => {
        max_values => 2,
        type => {
            baz => {required => 1}, # required only if "foo" exists
        },
    },
};
$e = validate_as_hash({foo => {baz => 1}}, $v);
ok(! $e, "Type hash, array 1 element ok");

$e = validate_as_hash({foo => []}, $v);
ok(! $e, "Type hash, array 0 elements ok");

$e = validate_as_hash({foo => [{baz => 1},{baz=>2}]}, $v);
ok(! $e, "Type hash, array 2 elements ok");

$e = validate_as_hash({foo => [{baz => 1},{baz=>2},{baz=>3}]}, $v);
is_deeply($e, {'foo' => 'Foo had more than 2 values.'}, "Type hash, over max_values");

$e = validate_as_hash({foo => [{baz => 1},{fail=>1}]}, $v);
is_deeply($e, {'foo.baz' => 'The field foo.baz is required.'}, "Type hash, inner required check");


$v = {
    foo => {
        type => {
            baz => {
                max_values => 2,
                type => {
                    bar => {},
                },
            },
        },
    },
};
$e = validate_as_hash({foo => {baz => [{},{}]}}, $v);
ok(! $e, "Type hash, nested array 2 elements ok");

$e = validate_as_hash({foo => {baz => [{},{},{}]}}, $v);
ok($e, "Type hash, nested array 3 elements, over max_values");


$v = {
    foo => {
        max_values => 3,
        type => {
            baz => {
                required => 1, # required only if "foo" exists
                default => '2',
            },
        },
        #validate_if => 'foo', #added later
    },
};

my $form = {foo => [{baz => 1},{}]};
$e = validate_as_hash($form, $v);
ok(! $e, "Type hash, array 2 elements ok");
is_deeply($form, { 'foo' => [ { 'baz' => 1 }, { 'baz' => '2' } ] }, 'defaults set without validate_if');

$v->{foo}{validate_if} = 'foo';

$form = { foo => [ {} ] };
$e = validate_as_hash($form, $v);
ok(!$e, "Type hash, array 1 elements ok");
is_deeply($form, { 'foo' => [ { 'baz' => '2' } ] }, 'default works with validate_if');

$form = { foo => [ {baz=>1}, {x=>1}, {} ] };
$e = validate_as_hash($form, $v);
ok(!$e, "Type hash, array 3 elements ok");
is_deeply($form, { 'foo' => [ {baz=>1}, {x=>1,baz=>2}, {baz=>2} ] }, 'defaults set with validate_if containing an array of multiple values');


$v = {
    'group no_extra_fields' => 1,
    foo => {
        max_values => 3,
        type => 'uint',
    },
};

$form = {foo => [3]};
$e = validate_as_hash($form, $v);
ok(! $e, "Verify no_extra_fields works on non-hash data inside an array") or note explain $e;

$v = {foo => {type => [{}], coerce => 1}};
ok_val({foo => 1}, $v, {foo => 'Foo did not match type hash.'});
ok_val({foo => [1]}, $v, {foo => 'Foo did not match type hash.'});
ok_val({foo => {}}, $v, undef);
ok_val({foo => [{}]}, $v, undef);

$v = {foo => {type => [{bar => {type => ['uint']}}], coerce => 1}};
ok_val({foo => {}}, {%$v, 'group type_ne_required' => 1}, undef);
ok_val({foo => {bar => 1}}, $v, {'foo.bar' => 'The field foo.bar did not match type [].'});
ok_val({foo => {bar => [1]}}, $v, undef);
$v = {foo => {type => [{bar => {type => ['uint'], coerce => 1}}], coerce => 1}};
ok_val($f = {foo => {bar => 1}}, $v, undef);
is_deeply($f, {foo=>[{bar => [1]}]}, 'nested line '.__LINE__.' - coerce');

