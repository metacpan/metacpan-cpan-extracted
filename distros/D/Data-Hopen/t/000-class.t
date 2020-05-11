#!perl
# 000-class.t: test Data::Hopen::Class
use rlib 'lib';
use HopenTest;
use Test::Fatal;

{
    package Sample;
    use parent 'Data::Hopen::Class';    # abort if we can't
    use Class::Tiny qw(first second);
}

# Basics
my $e = Sample->new(first => 'val');
ok($e->can('BUILDARGS'), 'class can(BUILDARGS)');
exit 1 unless $e->can('BUILDARGS');     # No sense in running the rest
isa_ok($e, 'Sample');

# Arg checks
is($e->first, 'val', 'first was set by constructor');
$e->first('val2');
is($e->first, 'val2', 'first was set by accessor');

$e = Sample->new(-first => 'val');
isa_ok($e, 'Sample');
is($e->first, 'val', 'first was set by constructor');

$e = Sample->new(second => 'val');
isa_ok($e, 'Sample');
is($e->second, 'val', 'second was set by constructor');

$e = Sample->new(-second => 'val');
isa_ok($e, 'Sample');
is($e->second, 'val', 'second was set by constructor');

# Mixed syntax
$e = Sample->new(first => 'foo', -second => 'bar');
isa_ok($e, 'Sample');
is($e->first, 'foo', 'first was set by constructor');
is($e->second, 'bar', 'second was set by constructor');

$e = Sample->new(-first => 'foo', second => 'bar');
isa_ok($e, 'Sample');
is($e->first, 'foo', 'first was set by constructor');
is($e->second, 'bar', 'second was set by constructor');

# Wrapped in a hashref
$e = Sample->new({first => 'foo', -second => 'bar'});
isa_ok($e, 'Sample');
is($e->first, 'foo', 'first was set by constructor');
is($e->second, 'bar', 'second was set by constructor');

$e = Sample->new({-first => 'foo', second => 'bar'});
isa_ok($e, 'Sample');
is($e->first, 'foo', 'first was set by constructor');
is($e->second, 'bar', 'second was set by constructor');

# Misc.
$e = Sample->new();
isa_ok($e, 'Sample');
$e = Sample->new({});
isa_ok($e, 'Sample');

# Errors
like exception { Sample->new(42) }, qr/\bodd\b/i, 'Odd number of args throws';
like exception { Sample->new([]) }, qr/\bARRAY\b.*\bHASH\b/i,
    'non-hashref throws';

like exception { Sample->can('BUILDARGS')->() }, qr/^Need a class/,
    'internal builder throws absent a class';

done_testing();
