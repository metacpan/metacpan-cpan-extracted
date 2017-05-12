use Test::More tests => 268;

use strict;

sub listcmp
{
	my $a = shift;
	my $b = shift;

	cmp_ok($a->[$_], '==', $b->[$_], "integer at position $_ is " . ($b->[$_] ? 'true' : 'false')) for 0 .. 11;
}

use_ok('Date::MonthSet');

my $set = new Date::MonthSet;

isa_ok($set, 'Date::MonthSet');

eval { my @a = @$set };
is($@, '', 'Date::MonthSet is a blessed array reference');

cmp_ok(scalar(@$set), '==', 14, 'array reference has 14 objects');
cmp_ok(scalar grep({ $_ == 0 } @$set[0..11]), '==', 12, 'pristine Date::MonthSet');
cmp_ok($set->[-2], 'eq', '%M', 'default conjunction format');
cmp_ok($set->[-1], 'eq', '-', 'default complement format');

# test marking

$set->mark('january');
cmp_ok($set->[0], '==', 1, 'mark: lower case full name');
$set->mark('February');
cmp_ok($set->[1], '==', 1, 'mark: upper case full name');
$set->mark('Aug');
cmp_ok($set->[7], '==', 1, 'mark: upper case short name');
$set->mark('dec');
cmp_ok($set->[11], '==', 1, 'mark: lower case short name');

listcmp($set, [1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1]);

# test clearing

$set->clear('december');
cmp_ok($set->[11], '==', 0, 'clear: lower case full name');
$set->clear('November');
cmp_ok($set->[10], '==', 0, 'clear: upper case full name (no-op)');
$set->clear('Mar');
cmp_ok($set->[2], '==', 0, 'clear: upper case short name (no-op)');
$set->clear('jan');
cmp_ok($set->[0], '==', 0, 'clear: lower case short name');

listcmp($set, [0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0]);

# test adding

$set->add('june');
cmp_ok($set->[5], '==', 1, 'add: lower case full name');
$set->add('August');
cmp_ok($set->[7], '==', 1, 'add: upper case full name (no-op)');
$set->add('Feb');
cmp_ok($set->[1], '==', 1, 'add: upper case short name (no-op)');
$set->add('mar');
cmp_ok($set->[2], '==', 1, 'add: lower case short name');

listcmp($set, [0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0]);

# test removing

$set->remove('may');
cmp_ok($set->[4], '==', 0, 'remove: lower case full name (no-op)');
$set->remove('April');
cmp_ok($set->[3], '==', 0, 'remove: upper case full name (no-op)');
$set->remove('May');
cmp_ok($set->[4], '==', 0, 'remove: upper case short name (no-op)');
$set->remove('mar');
cmp_ok($set->[2], '==', 0, 'remove: lower case short name');

listcmp($set, [0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0]);

# test contains

cmp_ok($set->contains('jan'), '==', 0, 'contains: false single short lower case');
cmp_ok($set->contains('feb'), '==', 1, 'contains: true single short lower case');
cmp_ok($set->contains('May'), '==', 0, 'contains: false single short upper case');
cmp_ok($set->contains('Jun'), '==', 1, 'contains: true single short upper case');

cmp_ok($set->contains('january'), '==', 0, 'contains: false single long lower case');
cmp_ok($set->contains('february'), '==', 1, 'contains: true single long lower case');
cmp_ok($set->contains('September'), '==', 0, 'contains: false single long upper case');
cmp_ok($set->contains('August'), '==', 1, 'contains: true single long upper case');

cmp_ok($set->contains(qw(jan feb mar)), '==', 0, 'contains: false multi short lower case');
cmp_ok($set->contains(qw(feb jun aug)), '==', 1, 'contains: true multi short lower case');
cmp_ok($set->contains(qw(Jun Jul Aug)), '==', 0, 'contains: false multi short upper case');
cmp_ok($set->contains(qw(Aug Jun Feb)), '==', 1, 'contains: true multi short upper case');

cmp_ok($set->contains(qw(january february)), '==', 0, 'contains: false multi long lower case');
cmp_ok($set->contains(qw(february august)), '==', 1, 'contains: true multi long lower case');
cmp_ok($set->contains(qw(November December)), '==', 0, 'contains: false multi long upper case');
cmp_ok($set->contains(qw(June August)), '==', 1, 'contains: true multi long upper case');

cmp_ok($set->contains(1), '==', 0, 'contains: false single numerical');
cmp_ok($set->contains(2), '==', 1, 'contains: true single numerical');
cmp_ok($set->contains(1..6), '==', 0, 'contains: false multi numerical');
cmp_ok($set->contains(2, 6, 8), '==', 1, 'contains: true multi numerical');

cmp_ok($set->contains(qw(1 March august November)), '==', 0, 'contains: false mixed');
cmp_ok($set->contains(qw(February jun 6 august 2)), '==', 1, 'contains: true mixed');

# test formats and stringification

is("$set", '-F---J-A----', 'default stringification');

$set->format('<strong>%M</strong>', undef);
is("$set", '-<strong>F</strong>---<strong>J</strong>-<strong>A</strong>----', 'stringification with format_conjunction of <strong>%M</strong>');

$set->format(undef, '%M');
is("$set", 'J<strong>F</strong>MAM<strong>J</strong>J<strong>A</strong>SOND', 'stringification with format_complement of %M');

$set->format('[%M]', '');
is("$set", '[F][J][A]', 'stringification with format_complement of [%M] and empty format_conjunction');

# test numerification

cmp_ok(int $set, '==', 162, 'numerification');

# test parsing

eval { $set = new Date::MonthSet integer => 1 };
is($@, '', 'new Date::MonthSet integer => 1');
listcmp($set, [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

eval { $set = new Date::MonthSet integer => 3626 };
is($@, '', 'new Date::MonthSet integer => 3626');
listcmp($set, [0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1]);

eval { $set = new Date::MonthSet integer => 4095 };
is($@, '', 'new Date::MonthSet integer => 4095');
listcmp($set, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);

eval { $set = new Date::MonthSet string => 'JF-A--JAS---' };
is($@, '', 'new Date::MonthSet string => \'JF-A--JAS---\'');
listcmp($set, [1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0]);

eval { $set = new Date::MonthSet string => '001110100011' };
is($@, '', 'new Date::MonthSet string => \'001110100011\'');
listcmp($set, [0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1]);

eval { $set = new Date::MonthSet placeholder => '**', string => '****M**********S******' };
is($@, '', 'new Date::MonthSet placeholder => \'**\', string => \'****M**********S******\'');
listcmp($set, [0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0]);

eval { $set = new Date::MonthSet format_conjunction => '{%M}', string => '{J}{F}--{M}------{D}' };
is($@, '', 'new Date::MonthSet format_conjunction => \'{%M}\'');
listcmp($set, [1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1]);

eval { $set = new Date::MonthSet format_conjunction => '%M%M', format_complement => '.', string => '..MM.MM....OONNDD' };
is($@, '', 'new Date::MonthSet format_conjunction => \'{%M}\'');
listcmp($set, [0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1]);

eval { $set = new Date::MonthSet set => [ 1 .. 4, 9 ] };
is($@, '', 'new Date::MonthSet set => [ 1 .. 4, 9 ]');
listcmp($set, [1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0]);

eval { $set = new Date::MonthSet set => [ qw(dec jul), 4-2, 5..6 ] };
is($@, '', 'new Date::MonthSet set => [ qw(dec jul), 4-2, 5..6 ]');
listcmp($set, [0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1]);

eval { $set = new Date::MonthSet string => 'JFMASO' };
like($@, qr/unable to parse/, 'invalid string (too short)');

eval { $set = new Date::MonthSet string => 'JFM-T--A-O-D' };
like($@, qr/unable to parse/, 'invalid string (invalid identifier)');

eval { $set = new Date::MonthSet string => '1111111111111' };
like($@, qr/unable to parse/, 'invalid string (too many digits)');

eval { $set = new Date::MonthSet string => 'JFMAMJJASONDz' };
like($@, qr/unable to parse/, 'invalid string (too many characters)');

# test overloaded operators

my $a;
my $b;
my $c;

$a = new Date::MonthSet set => [ 1, 2, 3, 7, 10, 12 ];
$b = new Date::MonthSet set => [ qw(jan feb jul dec oct march) ];
ok($a == $b, 'overloaded equality operator (test AA)');
ok(($a <=> $b) == 0, 'overloaded comparison operator (test AB)');

$a = new Date::MonthSet string => '111000100101';
$b = new Date::MonthSet set => [ qw(december jan february jul march october) ];
ok($a == $b, 'overloaded equality operator (test BA)');
ok(($a <=> $b) == 0, 'overloaded comparison operator (test BB)');

$a = new Date::MonthSet string => 'JFM---JAS---';
$b = new Date::MonthSet integer => 1042;
ok($a != $b, 'overloaded inequality operator (test CA)');
ok(($a <=> $b) == -1, 'overloaded comparison operator (test CB)');

$a = new Date::MonthSet set => [ 12, 9 ];
$b = new Date::MonthSet set => [ 1, 3, 6 ];
ok($a != $b, 'overloaded inequality operator (test DA)');
ok(($a <=> $b) == 1, 'overloaded comparison operator (test DB)');

$a = new Date::MonthSet set => [ 12, 9, 8 ];
$b = new Date::MonthSet set => [ 1, 3, 6 ];
ok(($a <=> $b) == 1, 'overloaded comparison operator (test E)');

$a = new Date::MonthSet set => [ 2, 6, 11, 8, 3 ];
$b = new Date::MonthSet set => [ 8, 6, 3, 2, 11 ];
ok(($a <=> $b) == 0, 'overloaded comparison operator (test F)');

$a = new Date::MonthSet set => [ 2, 6, 11 ];
$b = new Date::MonthSet set => [ 12, 9, 2, 7 ];
$c = $a + $b;
isa_ok($c, 'Date::MonthSet', 'overloaded addition operator');
listcmp($c, [0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1]);

$a = new Date::MonthSet set => [ 2, 6, 11 ];
$b = new Date::MonthSet set => [ 12, 9, 2, 7 ];
$c = $a - $b;
isa_ok($c, 'Date::MonthSet', 'overloaded subtraction operator');
listcmp($c, [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0]);


