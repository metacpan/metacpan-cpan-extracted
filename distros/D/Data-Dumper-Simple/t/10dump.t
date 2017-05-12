#!/usr/bin/perl
# '$Id: 10dump.t,v 1.6 2004/08/03 04:52:28 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 24;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'Data::Dumper::Simple';
    use_ok($CLASS) or die;
}

my $scalar = 'Ovid';
my @array  = qw/Data Dumper Simple Rocks!/;
my %hash   = (
    at => 'least',
    I  => 'hope',
    it => 'does',
);

is(Dumper($scalar), "\$scalar = 'Ovid';\n",
    '... and dumped variables are named');
is(Dumper(\$scalar), "\$scalar = 'Ovid';\n",
    '... and dumping a scalar as a reference is a no-op');

my $expected = Data::Dumper->Dump([\@array], ['*array']);
is(Dumper(@array), $expected, '... and arrays should not flatten');
$expected = Data::Dumper->Dump([\@array], ['$array']);
is(Dumper(\@array), $expected, '... but they DWIM if I take a take a reference to them');

$expected = Data::Dumper->Dump(
    [$scalar, \@array, \%hash],
    [qw/$scalar *array *hash/]
);

is(Dumper($scalar, @array, %hash), $expected,
    '... or have a list of them');

$expected = Data::Dumper->Dump(
    [$scalar, \@array, \%hash],
    [qw/$scalar $array $hash/]
);
is(Dumper($scalar, \@array, \%hash), $expected,
    '... or a list of references');

$expected = Data::Dumper->Dump(
    [$scalar, \@array, \%hash],
    [qw/$scalar *array *hash/]
);

is(
    Dumper(
        $scalar =>
        @array =>
        %hash
    ), 
    $expected,
    '... or fat commas "=>"');

is(
    Dumper( $scalar => @array =>
        %hash
    ), 
    $expected,
    '... regardless of whitespace');

is(
    Dumper(
        $scalar, 
        @array, 
        %hash
    ), 
    $expected,
    '... and even do the right thing if there are newlines in the arg list');

$Data::Dumper::Indent = 1;
$expected = Data::Dumper->Dump(
    [$scalar, \@array, \%hash],
    [qw/$scalar *array *hash/]
);

is(Dumper($scalar, @array, %hash), $expected,
    '... and $Data::Dumper::Indent is respected');

my $foo   = { hash => 'ref' };
my @foo   = qw/foo bar baz/;
$expected = Data::Dumper->Dump(
    [$foo, \@foo],
    [qw/$foo $foo/],
);

is(Dumper($foo, \@foo), $expected,
     '... and a reference to a simarly named variable won\'t confuse things');
is(Dumper(\$foo, \@foo), $expected,
     '... even if we take references to both of them.');

is(Dumper($array[2]), "\$array[2] = 'Simple';\n",
    "Indexed items in arrays are dumped intuitively.");

my $aref = \@array;

is(Dumper($aref->[2]), "\$aref->[2] = 'Simple';\n",
    "... even if they're references");

is(Dumper($hash{at}), "\$hash{at} = 'least';\n",
    "Indexed items in hashes are dumped intuitively");

my $href = \%hash;
is(Dumper($href->{at}), "\$href->{at} = 'least';\n",
    "... even if they're references");

my @array2 = (
    [qw/foo bar baz/],
    [qw/one two three/],
);

$expected = Data::Dumper->Dump(
    [$array2[1][2]],
    [qw/$array2[1][2]/]
);
is(Dumper($array2[1][2]), $expected,
    'Multi-dimensioanl arrays should be handled correctly');

my ($w, $x) = (1,2);
$expected = Data::Dumper->Dump(
    [$array2[$w][$x]],
    [qw/$array2[$w][$x]/]
);
is(Dumper($array2[$w][$x]), $expected,
    '... even if the indexes are also variables');

my %hash2 = (
    first  => { this => 'that' },
    second => { next => 1 },
);
$expected = Data::Dumper->Dump(
    [$hash2{second}{next}],
    [qw/*hash2{second}{next}/]
);
is( Dumper($hash2{second}{next}), $expected,
    'Multi-level hashes should be handled correctly');
my ($y, $z) = qw/second next/;

$expected = Data::Dumper->Dump(
    [$hash2{$y}{$z}],
    [qw/*hash2{$y}{$z}/]
);
is( Dumper($hash2{$y}{$z}), $expected,
    '... even if the indexes are variables');

eval "
    # Dumper($foo);
";
ok(! $@, 'Commenting out a dumper item should not throw an exception');

$foo = [4, 17];
$expected = Data::Dumper->Dump([$foo->[ 1 ]],[qw/$foo->[1]/]);
is(Dumper($foo->[ 1 ]), $expected, 
    'Extra whitespace in the variable should not break things');

my @a = ({foo => 'bar'});

# this might break in the future.  For now, it *has* to work because any
# variable that begins with a dollar sigil will automatically be treated
# as a scalar.  If, in the future, we incorporate slices, this might break.
$expected = Data::Dumper->Dump([$a[0]],['$a[0]']);
is(Dumper($a[0]), $expected,
    'Indexing into a variable will force a reference');
