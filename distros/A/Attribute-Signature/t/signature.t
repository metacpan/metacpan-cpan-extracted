BEGIN {
  package main;
  use warnings;
  use Attribute::Signature;
  use Test::More tests => 102;
  $^W = 0;
}

#our $AS_DEBUG = 1;

package main;

sub that : method with('string') returns('integer') {
  return 5;
}

sub square : with('integer') returns('number') {
  my $number = shift;
  return $number * $number;
}

sub squaref : with('float') returns('number') {
  my $number = shift;
  return $number * $number;
}

sub squaren : with('number') returns('number') {
  my $number = shift;
  return $number * $number;
}

sub squareh : with('HASH') returns('number') {
  my $hash = shift;
  return $hash->{n} * $hash->{n};
}

sub squarea : with('ARRAY') returns('number') {
  my $array = shift;
  return $array->[0] * $array->[0];
}

sub squarec : with('CODE') returns('number') {
  my $code = shift;
  return $code->() * $code->();
}

sub squarer : with('SCALAR') returns('number') {
  my $ref = shift;
  return $$ref * $$ref;
}

sub rev : with('string') returns('string') {
  my $string = shift;
  return reverse $string;
}

sub this : with('float', 'string') returns('number') {
  my $float  = shift;
  my $string = shift;
  return 5;
}

sub hash : with('string') returns('HASH') {
  my $string = shift;
  return { 'string' => $string };
}

sub hash_bad : with('string') returns('HASH') {
  my $string = shift;
  return $string;
}

sub array : with('string') returns('ARRAY') {
  my $string = shift;
  return [$string];
}

sub array_bad : with('string') returns('ARRAY') {
  my $string = shift;
  return $string;
}

sub reference : with('string') returns('REF') {
  my $string = shift;
  return \$string;
}

sub reference_bad : with('string') returns('REF') {
  my $string = shift;
  return $string;
}

sub code : with('string') returns('CODE') {
  my $string = shift;
  return sub { $string };
}

sub code_bad : with('string') returns('CODE') {
  my $string = shift;
  return $string;
}

sub int : with('string') returns('integer') {
  my $string = shift;
  return 4;
}

sub int_bad : with('string') returns('integer') {
  my $string = shift;
  return $string;
}

sub float : with('string') returns('float') {
  my $string = shift;
  return 1.5;
}

sub float_bad : with('string') returns('float') {
  my $string = shift;
  return $string;
}

sub number : with('string') returns('number') {
  my $string = shift;
  return 42;
}

sub number_bad : with('string') returns('number') {
  my $string = shift;
  return $string;
}

sub string : with('string') returns('string') {
  my $string = shift;
  return "string";
}

sub string_bad : with('string') returns('string') {
  my $string = shift;
  return [];
}

sub multi : with(qw/string integer float/) returns(qw/float integer string/) {
  my($string, $integer, $float) = @_;
  return (1.5, 42, "foo");
}

sub multi_bad : with(qw/string integer float/) returns(qw/float integer string/) {
  my($string, $integer, $float) = @_;
  return ("foo", 42, 1.5);
}

# Test square
eval { square() };
ok($@, "square() should fail");

eval { square('four') };
ok($@, "square('four') should fail");

eval { square({}) };
ok($@, "square({}) should fail");

eval { square([]) };
ok($@, "square([]) should fail");

eval { square(\10) };
ok($@, 'square(\10) should fail');

eval { square(sub {}) };
ok($@, 'square(sub {}) should fail');

eval { square(1.1) };
ok($@, 'square(1.1) should fail');

my $answer;
eval { $answer = square(10) };
ok(!$@);
ok($answer == 100, "square(10) should return 100: $@");


# Test rev
eval { rev() };
ok($@, "rev() should fail");

eval { $answer = rev('four') };
ok($answer eq 'ruof', "rev('four') should return ruof");

eval { $answer = rev({}) };
ok($@, "rev({}) should fail: $answer");

eval { rev([]) };
ok($@, "rev([]) should fail");

eval { rev(\10) };
ok($@, 'rev(\10) should fail');

eval { rev(sub {}) };
ok($@, 'rev(sub {}) should fail');

eval { $answer = rev(1.2) };
ok($answer eq '2.1', 'rev(1.2) should return 2.1');

eval { $answer = rev(42) };
ok($answer eq '24', 'rev(42) should return 24');


# Test squaref
eval { squaref() };
ok($@, "squaref() should fail");

eval { squaref('four') };
ok($@, "squaref('four') should fail");

eval { squaref({}) };
ok($@, "squaref({}) should fail");

eval { squaref([]) };
ok($@, "squaref([]) should fail");

eval { squaref(\10) };
ok($@, 'squaref(\10) should fail');

eval { squaref(sub {}) };
ok($@, 'squaref(sub {}) should fail');

eval { $answer = squaref(1.5) };
ok($answer == 2.25, "squaref(1.5) should return 2.25");

eval { squaref(10) };
ok($@, 'squaref(10) should fail');

eval { $answer = squaref(1.0) };
ok($@, "squaref(1.0) should not work as intended (feature)");


# Test squaren
eval { squaren() };
ok($@, "squaren() should fail");

eval { squaren('four') };
ok($@, "squaren('four') should fail");

eval { squaren({}) };
ok($@, "squaren({}) should fail");

eval { squaren([]) };
ok($@, "squaren([]) should fail");

eval { squaren(\10) };
ok($@, 'squaren(\10) should fail');

eval { squaren(sub {}) };
ok($@, 'squaren(sub {}) should fail');

eval { $answer = squaren(1.5) };
ok($answer == 2.25, "squaren(1.5) should return 2.25");

eval { $answer = squaren(10) };
ok($answer == 100, "squaren(10) should return 100");


# Test squareh
eval { squareh() };
ok($@, "squareh() should fail");

eval { squareh('four') };
ok($@, "squareh('four') should fail");

eval { $answer = squareh({ n => 9}) };
ok($answer == 81, "squareh({ n => 9 }) should return 81");

eval { squareh([]) };
ok($@, "squareh([]) should fail");

eval { squareh(\10) };
ok($@, 'squareh(\10) should fail');

eval { squareh(sub {}) };
ok($@, 'squareh(sub {}) should fail');

eval { squareh(1.5) };
ok($@, "squareh(1.5) should fail");

eval { squareh(10) };
ok($@, "squareh(10) should fail");


# Test squarea
eval { squarea() };
ok($@, "squarea() should fail");

eval { squarea('four') };
ok($@, "squarea('four') should fail");

eval { squarea({}) };
ok($@, "squarea({}) should fail");

$answer=0;
eval { $answer = squarea([10]) };
ok($answer == 100, "squarea([10]) should return 100");

eval { squarea(\10) };
ok($@, 'squarea(\10) should fail');

eval { squarea(sub {}) };
ok($@, 'squarea(sub {}) should fail');

eval { squarea(1.5) };
ok($@, "squarea(1.5) should fail");

eval { squarea(10) };
ok($@, "squarea(10) should fail");


# Test squarec
eval { squarec() };
ok($@, "squarec() should fail");

eval { squarec('four') };
ok($@, "squarec('four') should fail");

eval { squarec({}) };
ok($@, "squarec({}) should fail");

eval { squarec([]) };
ok($@, "squarec([]) should fail");

eval { squarec(\10) };
ok($@, 'squarec(\10) should fail');

$answer=0;
eval { $answer = squarec(sub { 10 }) };
ok($answer == 100, 'squarec(sub { 10 }) should return 100');

eval { squarec(1.5) };
ok($@, "squarec(1.5) should fail");

eval { squarec(10) };
ok($@, "squarec(10) should fail");


# Test squarer

eval { squarer() };
ok($@, "squarer() should fail");

eval { squarer('four') };
ok($@, "squarer('four') should fail");

eval { squarer({}) };
ok($@, "squarer({}) should fail");

eval { squarer([]) };
ok($@, "squarer([]) should fail");

$answer=0;
eval { $answer = squarer(\11) };
ok(!$@,'squarer(\11) should succeed');
is($answer,121, 'squarer(\11) should return 121');

eval { squarer(sub {}) };
ok($@, 'squarer(sub {}) should fail');

eval { squarer(1.5) };
ok($@, "squarer(1.5) should fail");

eval { squarer(10) };
ok($@, "squarer(10) should fail");

eval { this(); };
ok($@, "this() should fail");

eval { this('test', 1.1) };
ok($@, "this('test', 1.1) should fail");

eval { this(1.1, 'test') };
ok(not($@), "this(1.1, 'test') should succeed");

my $sig = Attribute::Signature->getSignature( 'main::this' );
ok($sig->[0] eq 'float', 'signature of this should be a float');

eval { main->that() };
ok($@, "should get an error from main->that()");

eval { main->that('this') };
ok(not($@), "main->that('this') should succeed: $@");


# Now let's test the returns

eval { hash() };
ok($@, "hash() should fail");

eval { hash("Four") };
ok(not($@), "hash('Four') should succeed");

eval { hash_bad() };
ok($@, "hash_bad() should fail");

eval { hash_bad("Four") };
ok($@, "hash_bad('Four') should fail");

eval { array() };
ok($@, "array() should fail");

eval { array("Four") };
ok(not($@), "array('Four') should succeed");

eval { array_bad() };
ok($@, "array_bad() should fail");

eval { array_bad("Four") };
ok($@, "array_bad('Four') should fail");

eval { reference() };
ok($@, "reference() should fail");

eval { reference("Four") };
ok(not($@), "reference('Four') should succeed");

eval { reference_bad() };
ok($@, "reference_bad() should fail");

eval { reference_bad("Four") };
ok($@, "reference_bad('Four') should fail");

eval { code() };
ok($@, "code() should fail");

eval { code("Four") };
ok(not($@), "code('Four') should succeed");

eval { code_bad() };
ok($@, "code_bad() should fail");

eval { code_bad("Four") };
ok($@, "code_bad('Four') should fail");

eval { int("Four") };
ok(not($@), "int('Four') should succeed");

eval { int_bad("Four") };
ok($@, "int_bad('Four') should fail");

eval { float("Four") };
ok(not($@), "float('Four') should succeed");

eval { float_bad("Four") };
ok($@, "float_bad('Four') should fail");

eval { number("Four") };
ok(not($@), "number('Four') should succeed: $@");

eval { number_bad("Four") };
ok($@, "number_bad('Four') should fail");

eval { string("Four") };
ok(not($@), "string('Four') should succeed");

eval { string_bad("Four") };
ok($@, "string_bad('Four') should fail");


# Check multiple values

eval { multi("Four") };
ok($@, "multi('Four') should fail");

eval { multi("Four", 10) };
ok($@, "multi('Four', 10) should fail");

eval { multi("Four", 10, 0.1) };
ok(not($@), "multi('Four', 10, 0.1) should succeed");


# Check signatures

my($sig, $ret) = Attribute::Signature->getSignature('main::square');
ok($sig->[0] eq 'integer', 'signature of square should be a integer');
ok($ret->[0] eq 'number', 'signature return of square should be a number');

