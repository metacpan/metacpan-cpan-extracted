use Test;
BEGIN {
	plan(tests => 5);
};
use Algorithm::CheckDigits;

my $imei = CheckDigits('IMEI');

#
ok($imei->is_valid("260531793113837"));
ok(not $imei->is_valid("260531793113838"));
# you have to use method 'imeisv' if your number contains the software version
ok(not $imei->is_valid("26053179311383347"));

my $imeisv = CheckDigits('IMEISV');
ok($imeisv->is_valid("26053179311383127"));
ok($imeisv->is_valid("26053179311383347"));
