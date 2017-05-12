use Test;
BEGIN {
	plan(tests => 11);
};
use Algorithm::CheckDigits;

my $nip = CheckDigits('nip');

#
my $number = '768000246';
ok(not $nip->is_valid($number . '0'));
ok(not $nip->is_valid($number . '1'));
ok(not $nip->is_valid($number . '2'));
ok(not $nip->is_valid($number . '3'));
ok(not $nip->is_valid($number . '4'));
ok(not $nip->is_valid($number . '5'));
ok($nip->is_valid($number . '6'));
ok(not $nip->is_valid($number . '7'));
ok(not $nip->is_valid($number . '8'));
ok(not $nip->is_valid($number . '9'));
ok($number . '6' eq $nip->complete($number));
