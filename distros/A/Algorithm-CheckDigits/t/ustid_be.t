use Test;
BEGIN {
	plan(tests => 4);
};
use Algorithm::CheckDigits;

my $ustid_be = CheckDigits('ustid_be');

#
ok($ustid_be->is_valid('BE0473700488'));
ok($ustid_be->complete('BE04737004'),'BE0473700488');
ok($ustid_be->basenumber('BE0473700488'),'04737004');
ok($ustid_be->checkdigit('BE0473700488'),'88');

# end of tests
