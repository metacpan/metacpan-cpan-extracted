use Test::More;
use DateTime::Ordinal;

test(1, '1st');
test(2, '2nd');
test("3", '3rd');
test('4', '4th');
test(q|31|, '31st');
test(q!105!, '105th');

done_testing();

sub test {
	my ($test, $expected) = @_;
	is(DateTime::Ordinal::_ordinal($test), $expected, "$test -> $expected"); 
}

