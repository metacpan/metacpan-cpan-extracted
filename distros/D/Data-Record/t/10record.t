#!/usr/bin/perl -w

use strict;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

my $RECORD;
BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $RECORD = "Data::Record";
	use_ok $RECORD or die "Cannot use $RECORD";
}

# gleefully stoled from Regexp::Common
my $quoted = qr/(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')|(?:\`)(?:[^\\\`]*(?:\\.[^\\\`]*)*)(?:\`))/;

can_ok $RECORD, 'new';
throws_ok { $RECORD->new({limit => 13, trim => 0}) }
    qr/^You may not specify 'trim' if 'limit' is specified/,
    'new() should croak if both limit and trim are specified';

my %attributes = (
    split  => '.',
    unless => $quoted,
);
ok my $record = $RECORD->new(\%attributes) , '... and calling it should suceed';
isa_ok $record, $RECORD, '... and the object it returns';

my @expected = (
    'loves("Mr. Poe", prolog)',
    'loves(ovid, perl)',
    'eq(ovid, "Mr. Poe")',
);
my $data = join '.', @expected;
$data .= '.';

can_ok $record, 'records';
ok my @records = $record->records($data), '... and it should return records';
is_deeply \@records, [@expected, ''], '... and they should be the correct ones';

can_ok $record, 'limit';
is $record->limit, -1, '... initial limit should pull all records';
throws_ok { $record->limit('none') }
    qr/^limit must be an integer value, not \(none\)/,
    '... but setting it a non-numeric value should fail';
throws_ok { $record->limit(3.2) }
    qr/^limit must be an integer value, not \(3.2\)/,
    '... and setting it a numeric non-integer value should fail';

$record->limit(0);
ok @records = $record->records($data), '... and it should return records';
is_deeply \@records, \@expected, '... and they should be the correct ones';

can_ok $record, 'chomp';
is $record->chomp, 1, '... and it should have a true default value';
$_ .= '.' foreach @expected;
$record->chomp(0);
ok @records = $record->records($data), '... and it should return records';
is_deeply \@records, \@expected, '... and they should be the correct ones';

$data = <<'END_DATA';
loves("Mr.
Poe", Language):-
    not(eq(Language, java)).
loves(ovid, perl).
eq(ovid, "Mr. Poe").
END_DATA

@expected = (
    qq'loves("Mr.\nPoe", Language):-\n    not(eq(Language, java)).\n',
    "loves(ovid, perl).\n",
    qq'eq(ovid, "Mr. Poe").\n',
);

$record->split(".\n")
       ->unless($quoted)
       ->chomp(0)
       ->trim(1);

@records = $record->records($data);
is_deeply \@records, \@expected,
    'We should be able to keep the split value and trim trailing nulls';

can_ok $record, 'token';
my $token = $record->token;
ok +(-1 eq index $data, $token), 
    '... and the token should not be present in the data';

ok $record->token('XXX'), 
    '... setting the token to a value that does not match split should succeed';
@records = $record->records($data);
is_deeply \@records, \@expected,
    '... and the result of $record->records should be unchanged';

throws_ok { $record->token(".\n") }
    qr/Token \(\.\n\) must not match the split value.*/,
    '... but it should fail if it matches the split value';

ok $record->token('ovid'), 
    'We should be able to set the token to a value in our target text';
throws_ok { $record->records($data) }
    qr/Current token \(ovid\) found in data/,
    '... but calling records should then croak()';

$data = join "\n", map { $_ x 6 } qw( ~ ` ? " { } ! @ $ % ^ & * - _ + = );
$record->token(undef);
throws_ok { $record->records($data) }
    qr/^Could not determine a unique token for data.*/,
    'Calling records() should fail if we cannot determine a unique token';

$data = 'xx33yyy999zzz0aaa2bbb';
$record = $RECORD->new({
    split  => qr/\d+/,
    unless => '999'
});
@records = $record->records($data);
@expected = (
  'xx',
  'yyy999zzz',
  'aaa',
  'bbb'
);
is_deeply \@records, \@expected,
    'We should be able to correctly split records even if their split is numeric';

$data = <<'END_DATA';
1,2,"programmer, perl",4,5
1,2,"programmer,
perl",4,5
1,2,3,4,5
END_DATA

$record = $RECORD->new({
    split  => "\n",
    unless => $quoted,
    trim   => 1,
    fields => {
        split  => ",",
        unless => $quoted,
    }
});
@records = $record->records($data);
@expected = (
    [ 1, 2, '"programmer, perl"',    4, 5 ],
    [ 1, 2, qq'"programmer,\nperl"', 4, 5 ],
    [ 1, 2, 3,                       4, 5 ],
);
is_deeply \@records, \@expected,
    'Specifiying how you want your fields created should succeed';
