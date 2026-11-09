use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k55): every refusal names a case, and the
# answered table version is a number. The cases themselves run in
# t/80-conformance-ddl-live.t.

my $class = 'DBIO::Firebird::Test::Conformance';

is_deeply [ $class->check_declarations('DDL') ], [],
  'the conformance declarations are whole';

# Not an exact count (ADR 0060 section 6): core adds cases with a higher
# `since`, and a released driver must not turn red for a case it never claimed
# to answer. The cases of the table version this driver answered through are
# the ones it is held to; there were twenty at table version 2 (nineteen at version 1).
my $through = $class->conformance_answered_through->{DDL};
my @cases   = @{ $class->cases('DDL') };
my @answered = grep { $_->{since} <= $through } @cases;

cmp_ok scalar(@answered), '>=', 20,
  "the DDL cases of table version $through are at least the twenty this driver was written against";

my %refused = %{ $class->conformance_refusals };
my %by_name = map { $_->{name} => $_ } @cases;
is_deeply [ sort grep { /^ddl-/ and (!$by_name{$_} || $by_name{$_}{since} > $through) } keys %refused ], [],
  'every declared refusal names a case of the table version the driver answered through';

ok $through <= $class->table_version('DDL'),
  'the driver does not claim a table version newer than core has';

done_testing;
