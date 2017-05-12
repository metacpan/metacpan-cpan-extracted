use strict;
use Test::More;
use Business::AT::SSN;

my $ssn = '1680250250';

my $ssn_object = Business::AT::SSN->new($ssn);

is($ssn, $ssn_object->ssn, 'Object created and ssn set');

is($ssn_object->is_valid, 1, sprintf("[%s] is a wellformed SSN", $ssn_object->ssn));

$ssn_object->ssn('168025025');
is($ssn_object->is_valid, 0, sprintf("[%s] is too short", $ssn_object->ssn));

$ssn_object->ssn('1689250230');
is($ssn_object->is_valid, 1, sprintf("[%s] is a wellformed SSN", $ssn_object->ssn));


$ssn_object->ssn('1688250208');
is($ssn_object->is_valid, 1, sprintf("[%s] is a wellformed SSN", $ssn_object->ssn));
is($ssn_object->date_of_birth->year, 2008, sprintf("[%s] guessed a year", $ssn_object->ssn));

$ssn_object->ssn('w688250208');
is($ssn_object->is_valid, 0, sprintf("[%s] contains invalid character", $ssn_object->ssn));
is($ssn_object->error_messages->[0], 'Invalid characters', sprintf("[%s] error message [%s]", $ssn_object->ssn, $ssn_object->error_messages->[0]));

$ssn_object->ssn('2686251308');
is($ssn_object->is_valid, 1, sprintf("[%s] is a wellformed SSN", $ssn_object->ssn));
is($ssn_object->date_of_birth, undef, sprintf("[%s] has no valid date", $ssn_object->ssn));

my $ssn_o = Business::AT::SSN->new(ssn => $ssn);
is($ssn_o->is_valid, 1, sprintf("[%s] is a wellformed SSN", $ssn_o->ssn));

done_testing;
