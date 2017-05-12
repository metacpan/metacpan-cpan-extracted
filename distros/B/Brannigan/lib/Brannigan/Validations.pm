package Brannigan::Validations;

our $VERSION = "1.100001";
$VERSION = eval $VERSION;

use strict;
use warnings;

=head1 NAME

Brannigan::Validations - Built-in validation methods for Brannigan.

=head1 DESCRIPTION

This module contains all built-in validation methods provided natively
by the L<Brannigan> input validation/parsing system.

=head1 GENERAL PURPOSE VALIDATION METHOD

All these methods receive the value of a parameter, and other values
that explicilty define the requirements. They return a true value if the
parameter's value passed the test, or a false value otherwise.

=head2 required( $value, $boolean )

If C<$boolean> has a true value, this method will check that a required
parameter was indeed provided; otherwise (i.e. if C<$boolean> is not true)
this method will simply return a true value to indicate success.

You should note that if a parameter is required, and a non-true value is
received (i.e. 0 or the empty string ""), this method considers the
requirement as fulfilled (i.e. it will return true). If you need to make sure
your parameters receive true values, take a look at the C<is_true()> validation
method.

Please note that if a parameter is not required and indeed isn't provided
with the input parameters, any other validation methods defined on the
parameter will not be checked.

=cut

sub required {
	my ($class, $value, $boolean) = @_;

	return !$boolean || defined $value;
}

=head2 forbidden( $value, $boolean )

If C<$boolean> has a true value, this method will check that a forbidden
parameter was indeed NOT provided; otherwise (i.e. if C<$boolean> has a
false value), this method will do nothing and simply return true.

=cut

sub forbidden {
	my ($class, $value, $boolean) = @_;

	return !$boolean || !defined $value;
}

=head2 is_true( $value, $boolean )

If C<$boolean> has a true value, this method will check that C<$value>
has a true value (so, C<$value> cannot be 0 or the empty string); otherwise
(i.e. if C<$boolean> has a false value), this method does nothing and
simply returns true.

=cut

sub is_true {
	my ($class, $value, $boolean) = @_;

	return !$boolean || $value;
}

=head2 length_between( $value, $min_length, $max_length )

Makes sure the value's length (stringwise) is inside the range of
C<$min_length>-C<$max_length>, or, if the value is an array reference,
makes sure it has between C<$min_length> and C<$max_length> items.

=cut

sub length_between {
	my ($class, $value, $min, $max) = @_;

	return $class->min_length($value, $min) && $class->max_length($value, $max);
}

=head2 min_length( $value, $min_length )

Makes sure the value's length (stringwise) is at least C<$min_length>, or,
if the value is an array reference, makes sure it has at least C<$min_length>
items.

=cut

sub min_length {
	my ($class, $value, $min) = @_;

	return _length($value) >= $min;
}

=head2 max_length( $value, $max_length )

Makes sure the value's length (stringwise) is no more than C<$max_length>,
or, if the value is an array reference, makes sure it has no more than
C<$max_length> items.

=cut

sub max_length {
	my ($class, $value, $max) = @_;

	return _length($value) <= $max;
}

=head2 exact_length( $value, $length )

Makes sure the value's length (stringwise) is exactly C<$length>, or,
if the value is an array reference, makes sure it has exactly C<$exact_length>
items.

=cut

sub exact_length {
	my ($class, $value, $exlength) = @_;

	return _length($value) == $exlength;
}

=head2 integer( $value, $boolean )

If boolean is true, makes sure the value is an integer.

=cut

sub integer {
	my ($class, $value, $boolean) = @_;

	return !$boolean || $value =~ m/^\d+$/;
}

=head2 value_between( $value, $min_value, $max_value )

Makes sure the value is between C<$min_value> and C<$max_value>.

=cut

sub value_between {
	my ($class, $value, $min, $max) = @_;

	return defined $value && $value >= $min && $value <= $max;
}

=head2 min_value( $value, $min_value )

Makes sure the value is at least C<$min_value>.

=cut

sub min_value {
	my ($class, $value, $min) = @_;

	return defined $value && $value >= $min;
}

=head2 max_value( $value, $max )

Makes sure the value is no more than C<$max_value>.

=cut

sub max_value {
	my ($class, $value, $max) = @_;

	return defined $value && $value <= $max;
}

=head2 array( $value, $boolean )

If C<$boolean> is true, makes sure the value is actually an array reference.

=cut

sub array {
	my ($class, $value, $boolean) = @_;

	$boolean ? ref $value eq 'ARRAY' ? 1 : return : ref $value eq 'ARRAY' ? return : 1;
}

=head2 hash( $value, $boolean )

If C<$boolean> is true, makes sure the value is actually a hash reference.

=cut

sub hash {
	my ($class, $value, $boolean) = @_;

	$boolean ? ref $value eq 'HASH' ? 1 : return : ref $value eq 'HASH' ? return : 1;
}

=head2 one_of( $value, @values )

Makes sure a parameter's value is one of the provided acceptable values.

=cut

sub one_of {
	my ($class, $value, @values) = @_;

	foreach (@values) {
		return 1 if $value eq $_;
	}

	return;
}

=head2 matches( $value, $regex )

Returns true if C<$value> matches the regular express (C<qr//>) provided.
Will return false if C<$regex> is not a regular expression.

=cut

sub matches {
	my ($class, $value, $regex) = @_;

	return ref $regex eq 'Regexp' && $value =~ $regex;
}

=head1 USEFUL PASSPHRASE VALIDATION METHODS

The following validations are useful for passphrase strength validations:

=head2 min_alpha( $value, $integer )

Returns a true value if C<$value> is a string that has at least C<$integer>
alphabetic (C<A-Z> and C<a-z>) characters.

=cut

sub min_alpha {
	my ($class, $value, $integer) = @_;

	my @matches = ($value =~ m/[A-Za-z]/g);

	return scalar @matches >= $integer;
}

=head2 max_alpha( $value, $integer )

Returns a true value if C<$value> is a string that has at most C<$integer>
alphabetic (C<A-Z> and C<a-z>) characters.

=cut

sub max_alpha {
	my ($class, $value, $integer) = @_;

	my @matches = ($value =~ m/[A-Za-z]/g);

	return scalar @matches <= $integer;
}

=head2 min_digits( $value, $integer )

Returns a true value if C<$value> is a string that has at least
C<$integer> digits (C<0-9>).

=cut

sub min_digits {
	my ($class, $value, $integer) = @_;

	my @matches = ($value =~ m/[0-9]/g);

	return scalar @matches >= $integer;
}

=head2 max_digits( $value, $integer )

Returns a true value if C<$value> is a string that has at most
C<$integer> digits (C<0-9>).

=cut

sub max_digits {
	my ($class, $value, $integer) = @_;

	my @matches = ($value =~ m/[0-9]/g);

	return scalar @matches <= $integer;
}

=head2 min_signs( $value, $integer )

Returns a true value if C<$value> has at least C<$integer> special or
sign characters (e.g. C<%^&!@#>, or basically anything that isn't C<A-Za-z0-9>).

=cut

sub min_signs {
	my ($class, $value, $integer) = @_;

	my @matches = ($value =~ m/[^A-Za-z0-9]/g);

	return scalar @matches >= $integer;
}

=head2 max_signs( $value, $integer )

Returns a true value if C<$value> has at most C<$integer> special or
sign characters (e.g. C<%^&!@#>, or basically anything that isn't C<A-Za-z0-9>).

=cut

sub max_signs {
	my ($class, $value, $integer) = @_;

	my @matches = ($value =~ m/[^A-Za-z0-9]/g);

	return scalar @matches <= $integer;
}

=head2 max_consec( $value, $integer )

Returns a true value if C<$value> does not have a sequence of consecutive
characters longer than C<$integer>. Consequtive characters are either
alphabetic (e.g. C<abcd>) or numeric (e.g. C<1234>).

=cut

sub max_consec {
	my ($class, $value, $integer) = @_;

	# the idea here is to break the string intoto an array of characters,
	# go over each character in the array, starting at the first one,
	# and making sure that character does not begin a sequence longer
	# than allowed ($integer). This means we have recursive loops here,
	# because for every character, we compare it to the following character
	# and while they form a sequence, we move to the next pair and compare
	# them until the sequence is broken. To make it a tad faster, our
	# outer loop won't go over the entire characters array, but only
	# up to the last character that might possibly form an invalid
	# sequence. This character would be positioned $integer+1 characters
	# from the end.

	my @chars = split(//, $value);
	for (my $i = 0; $i <= scalar(@chars) - $integer - 1; $i++) {
		my $fc = $i; # first character for comparison
		my $sc = $i + 1; # second character for comparison
		my $sl = 1; # sequence length
		while ($sc <= $#chars && ord($chars[$sc]) - ord($chars[$fc]) == 1) {
			# characters are in sequence, increase counters
			# and compare next pair
			$sl++;
			$fc++;
			$sc++;
		}
		return if $sl > $integer;
	}

	return 1;
}

=head2 max_reps( $value, $integer )

Returns a true value if C<$value> does not contain a sequence of a repeated
character longer than C<$integer>. So, for example, if C<$integer> is 3,
then "aaa901" will return true (even though there's a repetition of the
'a' character it is not longer than three), while "9bbbb01" will return
false.

=cut

sub max_reps {
	my ($class, $value, $integer) = @_;

	# the idea here is pretty much the same as in max_consec but
	# we truely compare each pair of characters

	my @chars = split(//, $value);
	for (my $i = 0; $i <= scalar(@chars) - $integer - 1; $i++) {
		my $fc = $i; # first character for comparison
		my $sc = $i + 1; # second character for comparison
		my $sl = 1; # sequence length
		while ($sc <= $#chars && $chars[$sc] eq $chars[$fc]) {
			# characters are in sequence, increase counters
			# and compare next pair
			$sl++;
			$fc++;
			$sc++;
		}
		return if $sl > $integer;
	}

	return 1;
}

=head2 max_dict( $value, $integer, [ \@dict_files ] )

Returns a true value if C<$value> does not contain a dictionary word
longer than C<$integer>. By default, this method will look for the Unix
dict files C</usr/dict/words>, C</usr/share/dict/words> and C</usr/share/dict/linux.words>.
You can supply more dictionary files to look for with an array reference
of full paths.

So, for example, if C<$integer> is 3, then "a9dog51" will return true
(even though "dog" is a dictionary word, it is not longer than three),
but "a9punk51" will return false, as "punk" is longer.

WARNING: this method is known to not work properly when used in certain
environments such as C<PSGI>, I'm investigating the issue.

=cut

sub max_dict {
	my ($class, $value, $integer, $dict_files) = @_;

	# the following code was stolen from the CheckDict function of
	# Data::Password by Ariel Brosh (RIP) and Oded S. Resnik

	$dict_files ||= [];
	unshift(@$dict_files, qw!/usr/dict/words /usr/share/dict/words /usr/share/dict/linux.words!);

	foreach (@$dict_files) {
		open (DICT, $_) || next;
		while (my $dict_line = <DICT>) {
			chomp $dict_line;
			next if length($dict_line) <= $integer;
			if (index(lc($value), lc($dict_line)) > -1) {
				close(DICT);
				return;
			}
		}
		close(DICT);
	}

	return 1;
}

####################
# INTERNAL METHODS #
####################

sub _length {
	return ref $_[0] eq 'ARRAY' ? scalar(@{$_[0]}) : length($_[0]);
}

=head1 SEE ALSO

L<Brannigan>, L<Brannigan::Tree>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brannigan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brannigan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Brannigan::Validations

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Brannigan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Brannigan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Brannigan>

=item * Search CPAN

L<http://search.cpan.org/dist/Brannigan/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ido Perlmuter

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
