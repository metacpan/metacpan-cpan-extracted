use Test::More;
use DateTime::Ordinal;

sub test {
	my ($test, $expected) = @_;
	is(DateTime::Ordinal::_num2text($test), $expected, "$test -> $expected"); 
}

sub testo {
	my ($test, $expected) = @_;
	is(DateTime::Ordinal::_num2text($test, 1), $expected, "$test -> $expected"); 
}

test(1, 'one', 'one');
test(5, 'five', 'five');
test(17, 'seventeen', 'seventeen');
test(20, 'twenty', 'twenty');
test(25, 'twenty-five', 'twenty-five');
test(36, 'thirty-six', 'thirty-six');
test(47, 'forty-seven', 'forty-seven');
test(88, 'eighty-eight', 'eighty-eight');
test(92, 'ninety-two', 'ninety-two');
test(102, 'one hundred and two', 'one hundred and two');
test(919, 'nine hundred and nineteen', 'one hundred and nineteen');
test(1001, 'one thousand and one', 'one thousand and one');
test(10001, 'ten thousand and one', 'ten thousand and one');
test(100021, 'one hundred thousand and twenty-one', 'one hundred thousand and twenty-one');
test(1100021, 'one million, one hundred thousand and twenty-one', 'one million, one hundred thousand and twenty-one');
test(1001100021, 'one billion, one million, one hundred thousand and twenty-one', 'one billion, one million, one hundred thousand and twenty-one');
testo(1, 'first', 'first');
testo(5, 'fifth', 'fifth');
testo(17, 'seventeenth', 'seventeenth');
testo(20, 'twentieth', 'twentieth');
testo(25, 'twenty-fifth', 'twenty-fifth');
testo(36, 'thirty-sixth', 'thirty-sixth');
testo(47, 'forty-seventh', 'forty-seventh');
testo(88, 'eighty-eighth', 'eighty-eighth');
testo(92, 'ninety-second', 'ninety-second');
testo(102, 'one hundred and second', 'one hundred and second');
testo(919, 'nine hundred and nineteenth', 'one hundred and nineteenth');
testo(1001, 'one thousand and first', 'one thousand and first');
testo(10001, 'ten thousand and first', 'ten thousand and first');
testo(100021, 'one hundred thousand and twenty-first', 'one hundred thousand and twenty-first');
testo(1100021, 'one million, one hundred thousand and twenty-first', 'one million, one hundred thousand and twenty-first');
testo(1001100021, 'one billion, one million, one hundred thousand and twenty-first', 'one billion, one million, one hundred thousand and twenty-first');
testo(1000000, 'one millionth', 'one millionth');
testo(9001000000, 'nine billion and one millionth', 'nine billion and one millionth');
testo(9000000000, 'nine billionth', 'nine billionth');
testo(9876543321972, 'nine trillion, eight hundred and seventy-six billion, five hundred and forty-three million, three hundred and twenty-one thousand, nine hundred and seventy-second', 'nine trillion, eight hundred and seventy-six billion, five hundred and forty-three million, three hundred and twenty-one thousand, nine hundred and seventy-second');
done_testing();

