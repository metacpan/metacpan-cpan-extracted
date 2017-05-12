use Test;
BEGIN {
	plan(tests => 2);
};
use Algorithm::CheckDigits;

my $esr5 = CheckDigits('esr5_ch');

#
my $number = '0001000012000 241170032660178 10304';
ok($esr5->is_valid('05' . $number));
ok('05' . $number eq $esr5->complete($number));
