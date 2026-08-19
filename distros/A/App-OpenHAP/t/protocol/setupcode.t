#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;

use_ok('Protocol::HAP::SetupCode');

# Test normalize_setup_code: basic operation
{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('1234-5678');
	is($code, '12345678',
	    '[HAP-Pairing §2.2] 8-digit setup code accepted with dashes');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('12345678');
	is($code, '12345678', 'Normalize a setup code without dashes');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('1234 5678');
	is($code, '12345678', 'Normalize a setup code with a space');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('12-34-56-78');
	is($code, '12345678', 'Normalize a setup code with several dashes');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('1 2 3 4 - 5 6 7 8');
	is($code, '12345678', 'Normalize a setup code with spaces and dashes');
}

# Test normalize_setup_code: invalid formats
{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('123-4567');
	is($code, undef,
	    '[HAP-Pairing §2.2] reject a 7-digit setup code (a setup code is 8 digits)');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('1234-56789');
	is($code, undef, 'Reject a 9-digit setup code');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('abcd-efgh');
	is($code, undef, 'Reject a setup code with letters');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('1234-567a');
	is($code, undef, 'Reject a setup code with letters and digits');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('');
	is($code, undef, 'Reject empty string');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code(undef);
	is($code, undef, 'Handle undefined input');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('1234-');
	is($code, undef, 'Reject an incomplete setup code');
}

# Test validate_setup_code: valid setup codes
{
	ok(Protocol::HAP::SetupCode::validate_setup_code('9876-5432'), 'A valid setup code with a dash');
}

{
	ok(Protocol::HAP::SetupCode::validate_setup_code('98765432'), 'A valid setup code without a dash');
}

{
	ok(Protocol::HAP::SetupCode::validate_setup_code('1111-2222'), 'A valid setup code with repeated digits');
}

{
	ok(Protocol::HAP::SetupCode::validate_setup_code('0000-0001'), 'A valid setup code that starts with zeros');
}

# Test validate_setup_code: HAP disallows trivial setup codes (Apple HAP R2
# 5.3). The trivial-code blacklist is not in spec/.
{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('00000000'), 'Reject 00000000');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('11111111'), 'Reject 11111111');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('22222222'), 'Reject 22222222');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('33333333'), 'Reject 33333333');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('44444444'), 'Reject 44444444');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('55555555'), 'Reject 55555555');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('66666666'), 'Reject 66666666');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('77777777'), 'Reject 77777777');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('88888888'), 'Reject 88888888');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('99999999'), 'Reject 99999999');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('12345678'), 'Reject 12345678');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('87654321'), 'Reject 87654321');
}

# Test validate_setup_code: it must also reject invalid codes with dashes
{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('0000-0000'), 'Reject 0000-0000');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('1111-1111'), 'Reject 1111-1111');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('1234-5678'), 'Reject 1234-5678 (sequential)');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('8765-4321'), 'Reject 8765-4321 (reverse sequential)');
}

# Test validate_setup_code: malformed input
{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('123-4567'), 'Reject a malformed setup code (7 digits)');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code('abcd-efgh'), 'Reject a non-numeric setup code');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code(''), 'Reject empty string');
}

{
	ok(!Protocol::HAP::SetupCode::validate_setup_code(undef), 'Reject undefined input');
}

# Test edge cases
{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('----1234----5678----');
	is($code, '12345678', 'Handle excessive dashes');
}

{
	my $code = Protocol::HAP::SetupCode::normalize_setup_code('   1234   5678   ');
	is($code, '12345678', 'Handle excessive spaces');
}

# Test that normalization is idempotent
{
	my $once = Protocol::HAP::SetupCode::normalize_setup_code('1234-5678');
	my $twice = Protocol::HAP::SetupCode::normalize_setup_code($once);
	is($once, $twice, 'Normalization is idempotent');
}

done_testing();
