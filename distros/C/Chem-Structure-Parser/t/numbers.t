#!/usr/bin/env perl
# The number reader.  Coordinate fields are parsed by a fixed-point reader
# rather than strtod(), because strtod() was a fifth of the instructions in a
# whole-file parse, and the whole point of doing that is that it costs nothing
# in accuracy: for [+-]?digits[.digits] the two must return the same NV, bit
# for bit, on a double, a long double and a __float128 perl alike.
#
# That claim is what most of this file checks, by calling both C paths on the
# same string through _str2nv_paths().  It cannot be checked by comparing
# against Perl's own string-to-number conversion: the two paths are never both
# reached for a real field, and on an older -Duselongdouble perl Perl_my_atof
# is a hand-rolled decimal accumulator rather than strtod(), so it is not
# entitled to be the referee.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Chem::Structure::Parser;
use Test::More;

#--------
# every value below goes through columns 31-38, so the prefix has to be exactly
# thirty characters.  Checked against a record from parse.t before anything is
# built on it, because a prefix off by one would move every field and the
# comparisons would still agree with each other.
#--------
my $PREFIX = 'ATOM      1  N   MET A   1    ';
is(length $PREFIX, 30, 'the record prefix ends where the x column begins');
is($PREFIX . '  11.104  13.207  10.000  1.00 15.00',
   'ATOM      1  N   MET A   1      11.104  13.207  10.000  1.00 15.00',
   'and rebuilds a known record from parse.t byte for byte');

# x, y, z are eight columns each; occupancy and B-factor six
sub record {
	my ($x, $y, $z, $occ, $b) = @_;
	return $PREFIX . sprintf('%8s%8s%8s%6s%6s',
		$x, $y // '0.000', $z // '0.000', $occ // '1.00', $b // '0.00');
}

#--------
# the two readers agree.  Anything shaped like a PDB number must be taken by
# the fixed-point path -- if it quietly fell through to strtod() the rest of
# this file would still pass while the fast path went untested -- and must come
# back identical to what strtod() made of the same bytes.
#--------
my @fixed_shape;
for my $mag (0, 1, 7, 9, 10, 42, 99, 100, 123, 999, 1000, 4321, 9999, 12345, 99999999) {
	for my $dp (0 .. 6) {
		my $body = sprintf('%.*f', $dp, $mag);
		push @fixed_shape, $body, "-$body", "+$body";
	}
}
# the shapes that are legal but not what a formatter would emit
push @fixed_shape, '.5', '-.5', '+.25', '5.', '-5.', '007.5', '0.0', '-0.0',
	'0', '-0', '00000000', '0.00000000000001',
	'123456789012345',      # fifteen digits: the most the reader will take
	'99999.9999999999';     # fifteen digits with ten of them fractional

{
	my (@declined, @mismatch, @slow_failed);
	for my $s (@fixed_shape) {
		my ($ok_fast, $fast, $ok_slow, $slow) = Chem::Structure::Parser::_str2nv_paths($s);
		if (!$ok_fast)   { push @declined, $s;    next }
		if (!$ok_slow)   { push @slow_failed, $s; next }
		# == is the strict test: a one-ULP disagreement fails it
		push @mismatch, "'$s': fixed=$fast strtod=$slow"
			unless $fast == $slow && "$fast" eq "$slow";
	}
	is(scalar @fixed_shape, 329, 'a few hundred fixed-point shapes to check');
	is(scalar @declined, 0, 'the fixed-point reader takes every one of them')
		or diag("declined: @declined");
	is(scalar @slow_failed, 0, 'and strtod() reads them too')
		or diag("strtod declined: @slow_failed");
	is(scalar @mismatch, 0, 'and the two agree to the last bit')
		or diag(join "\n", @mismatch);
}

#--------
# what the fixed-point reader must refuse.  Refusing is not a failure: the
# field falls through to strtod() and keeps whatever meaning it had before, so
# the test is that the reader declines and that the value still arrives.
#--------
{
	my @exponent = ('1e5', '1E5', '1.5e2', '1.0e+05', '2.5e-3', '-1e3');
	my (@taken, @wrong);
	for my $s (@exponent) {
		my ($ok_fast, $fast, $ok_slow, $slow) = Chem::Structure::Parser::_str2nv_paths($s);
		push @taken, $s if $ok_fast;
		push @wrong, "'$s': strtod=$slow perl=" . (0 + $s)
			unless $ok_slow && $slow == 0 + $s;
	}
	is(scalar @taken, 0, 'an exponent is left to strtod()')
		or diag("taken: @taken");
	is(scalar @wrong, 0, 'which still reads it correctly')
		or diag(join "\n", @wrong);
}

{
	# sixteen digits is past the point where an NV holds the mantissa exactly,
	# so the reader gives up rather than return something almost right
	my ($ok_fast) = Chem::Structure::Parser::_str2nv_paths('1234567890123456');
	is($ok_fast, 0, 'sixteen digits is past the exact-mantissa cap, so strtod() takes it');
	my ($ok15) = Chem::Structure::Parser::_str2nv_paths('123456789012345');
	is($ok15, 1, 'fifteen is not');

	# leading zeros count against the cap.  Conservative -- they add no
	# magnitude -- but it is what keeps the fractional digit count inside the
	# power-of-ten table, so it is deliberate and worth pinning down.
	my ($ok_lz) = Chem::Structure::Parser::_str2nv_paths('0.000000000000001');
	is($ok_lz, 0, 'leading zeros count against the cap, keeping frac in the table');
}

{
	# no digits at all, and the '*****' a field becomes when it overflows
	my @nothing = ('', '-', '+', '.', '-.', '+.', '*****', '**.**', 'abc', ' ');
	my (@taken, @slow_ok);
	for my $s (@nothing) {
		my ($ok_fast, undef, $ok_slow) = Chem::Structure::Parser::_str2nv_paths($s);
		push @taken, "'$s'"   if $ok_fast;
		push @slow_ok, "'$s'" if $ok_slow;
	}
	is(scalar @taken, 0, 'a field with no number in it is not read as one')
		or diag("taken: @taken");
	is(scalar @slow_ok, 0, 'and strtod() will not have it either')
		or diag("strtod took: @slow_ok");
}

{
	# a number with rubbish after it: strtod() takes the prefix, and did
	# before this reader existed, so that behaviour has to survive
	my ($ok_fast, undef, $ok_slow, $slow)
		= Chem::Structure::Parser::_str2nv_paths('11.104xy');
	is($ok_fast, 0, 'a number with rubbish after it is left to strtod()');
	ok($ok_slow && $slow == 11.104, 'which reads the part that is a number');
}

#--------
# end to end, out of the columns of a real record.  The values that exposed the
# widened-double bug are here by name: on a long double or __float128 perl a
# coordinate parsed as a double and widened prints as 0.599999999999999978, so
# these compare stringified as well as numerically.
#--------
{
	my $p = Chem::Structure::Parser::_parse_string(
		record('  11.104', '  13.207', '  10.000', '  0.60', ' 15.00'), {});
	is($p->{n_atoms}, 1, 'the built record parses as one atom');
	is($p->{x}[0], 11.104, 'x prints as it was written');
	is($p->{y}[0], 13.207, 'y prints as it was written');
	is($p->{z}[0], 10.000, 'z prints as it was written');
	is($p->{occupancy}[0], 0.6, 'occupancy prints as it was written');
	is($p->{bfactor}[0], 15.00, 'B-factor prints as it was written');
	cmp_ok($p->{x}[0], '==', 11.104, 'and x is numerically equal to the literal');
	cmp_ok($p->{occupancy}[0], '==', 0.6, 'and so is occupancy');
}

{
	# the negative and field-filling cases, which are where a reader that
	# scans for a number instead of slicing columns goes wrong
	my $p = Chem::Structure::Parser::_parse_string(
		record(' -12.500', ' 111.000', ' -10.500', '  0.40', ' 16.00'), {});
	is($p->{x}[0], -12.5,   'a negative x that fills its field');
	is($p->{y}[0], 111,     'a y wide enough to touch the field beside it');
	is($p->{z}[0], -10.5,   'a negative z immediately after a wide y');
	is($p->{occupancy}[0], 0.4, 'occupancy, six columns');
}

{
	# every coordinate the format can hold, through the columns rather than
	# through _str2nv_paths, so the column slicing is in the loop too
	my @bad;
	for my $mag (0, 5, 99, 999, 9999) {
		for my $dp (0 .. 3) {
			for my $sign ('', '-') {
				my $v = sprintf('%s%.*f', $sign, $dp, $mag);
				next if length $v > 8;
				my $p = Chem::Structure::Parser::_parse_string(record($v), {});
				push @bad, "'$v' came back as $p->{x}[0]"
					unless defined $p->{x}[0] && $p->{x}[0] == 0 + $v;
			}
		}
	}
	is(scalar @bad, 0, 'every width of coordinate the columns can hold reads back')
		or diag(join "\n", @bad);
}

{
	# '*****' is what a coordinate becomes in a file written by something that
	# overflowed the field; it has to be undef, not zero
	my $p = Chem::Structure::Parser::_parse_string(record('*****   '), {});
	is($p->{x}[0], undef, 'an overflowed coordinate field is undef, not zero');
}

done_testing();
