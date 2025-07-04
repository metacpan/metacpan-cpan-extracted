package Date::Cmp;

# Compare two dates. Approximate dates are compared.
# TODO: handle when only months are known

use strict;
use warnings;

use DateTime::Format::Genealogy;
use Scalar::Util;
use Term::ANSIColor;

use Exporter qw(import);
our @EXPORT_OK = qw(datecmp);

our $dfg = DateTime::Format::Genealogy->new();

=head1 NAME

Date::Cmp - Compare two dates with approximate parsing support

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Date::Cmp qw(datecmp);

  my $date1 = '1914';
  my $date2 = '1918';
  my $cmp = datecmp($date1, $date2);

  # Optionally provide a complaint callback:
  $cmp = datecmp($date1, $date2, sub { warn @_ });

=head1 DESCRIPTION

This module provides a single function, C<datecmp>, which compares two date strings
or date-like objects, returning a numeric comparison similar to Perl's spaceship operator (C<< <=> >>).

The comparison is tolerant of approximate dates (e.g. "Abt. 1902", "BET 1830 AND 1832", "Oct/Nov/Dec 1950"),
partial dates (years only), and strings with common genealogy-style formats. It attempts to normalize
and parse these into comparable values using L<DateTime::Format::Genealogy>.

=head1 FUNCTIONS

=head2 datecmp

  my $result = datecmp($left, $right);
  my $result = datecmp($left, $right, \&complain);

Compares two date strings or date-like objects and returns:

=over 4

=item * -1 if C<$left> is earlier than C<$right>

=item * 0 if they are equivalent

=item * 1 if C<$left> is later than C<$right>

=back

Parameters:

=over 4

=item C<$left>, C<$right>

The values to compare. These may be strings in a variety of genealogical or ISO-style formats,
or blessed objects that implement a C<date()> method returning a date string.

=item C<$complain> (optional)

A coderef that will be called with diagnostic messages when ambiguous or unexpected conditions are encountered,
e.g. when comparing a range with equal endpoints.

=back

=head1 SUPPORTED FORMATS

The function supports a variety of partial or approximate formats including:

=over 4

=item * Exact dates (e.g. C<1941-08-02>, C<5/27/1872>)

=item * Years only (e.g. C<1828>)

=item * Approximate dates (e.g. C<Abt. 1802>, C<ca. 1802>, C<1802 ?>)

=item * Date ranges (e.g. C<1802-1803>, C<BET 1830 AND 1832>)

=item * Month ranges (e.g. C<Oct/Nov/Dec 1950>)

=item * Qualifiers like C<BEF>, C<AFT>

=back

=head1 ERROR HANDLING

In cases where a date cannot be parsed or compared meaningfully, diagnostic messages
will be printed to STDERR, and the function may die with an error. Callbacks and
stack traces are used to help identify parsing issues.

=cut

sub datecmp
{
	my ($left, $right, $complain) = @_;

	if((!defined($left)) || !defined($right)) {
		print STDERR "\n";
		if(!defined($left)) {
			print STDERR "left not defined\n";
		}
		if(!defined($right)) {
			print STDERR "right not defined\n";
		}
		my $i = 0;
		while((my @call_details = caller($i++))) {
			print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
		}
		return 0;
	}

	if(Scalar::Util::blessed($left) && $left->can('date')) {
		$left = $left->date();
	}
	if(Scalar::Util::blessed($right) && $right->can('date')) {
		$right = $right->date();
	}

	return 0 if($left eq $right);

	if((!ref($left)) && (!ref($right)) && ($left =~ /\d{3,4}/) && ($right =~ /\d{3,4}/) && ($left !~ /^bet/i) && ($right !~ /^bet/i)) {
		if($left =~ /(\d{4})/) {
			my $lyear = $1;
			if($right =~ /(\d{4})/) {
				my $ryear = $1;

				if($lyear != $ryear) {
					return $lyear <=> $ryear;
				}
			}
		}
	}

	if((!ref($left)) && (!ref($right)) && ($left =~ /(\d{3,4})$/) && ($left !~ /^bet/i) && ($right !~ /^bet/i)) {
		# Simple year test for fast comparison
		my $yol = $1;
		if($right =~ /(\d{3,4})$/) {
			my $yor = $1;
			if($yol != $yor) {
				return $yol <=> $yor;
			}
		}
	}

	if(!ref($left)) {
		if((!ref($right)) && ($left =~ /(^|[\s\/])\d{4}$/) && ($left !~ /^bet/i) && ($right !~ /^bet/i) && ($right =~ /(^|[\s\/,])(\d{4})$/)) {
			my $ryear = $2;
			$left =~ /(^|[\s\/])(\d{4})$/;
			my $lyear = $2;
			if($lyear != $ryear) {
				# Easy comparison for different years
				return $lyear <=> $ryear;
			}
		}
		if($left =~ /^(bef|aft)/i) {
			if($right =~ /^\d+$/) {
				# For example, comparing bef 1 Jun 1965 <=> 1969
				if($left =~ /\s(\d+)$/) {
					# Easy comparison for different years
					if($1 < $right) {
						return -1;
					}
				}
			}
			if($right =~ /(\d{4})/) {
				# BEF. 1932 <=> 2005-06-16
				my $ryear = $1;
				if($left =~ /^bef/i) {
					if($left =~ /(\d{4})/) {
						if($1 < $ryear) {
							return -1;
						}
					}
				}
			}
			print STDERR "$left <=> $right: not handled yet\n";
			my $i = 0;
			while((my @call_details = caller($i++))) {
				print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
			}
			return 0;
		}
		if($left =~ /^(Abt|ca?)\.?\s+(.+)/i) {
			$left = $2;
		} elsif($left =~ /(.+?)\s?\?$/) {
			# "1828 ?"
			$left = $1;
		} elsif(($left =~ /\//) && ($left =~ /^[a-z\/]+\s+(.+)/i)) {
			# e.g. "Oct/Nov/Dec 1950"
			$left = $1;
		}

		if(($left =~ /^\d{3,4}/) && ($right =~ /^\d{3,4}/)) {
			# e.g. 1929/06/26 <=> 1939
			$left =~ /^(\d{3,4})/;
			my $start = $1;
			$right =~ /^(\d{3,4})/;
			my $end = $1;
			if($start != $end) {
				return $start <=> $end;
			}
		}

		if($left =~ /(\d{3,4})/) {
			my $start = $1;
			if(($left !~ /^bet/i) && ($right =~ /^bet/)) {
				if($right =~ /(\d{3,4})/) {
					# e.g. 26 Aug 1744 <=> 1673-02-22T00:00:00
					my $end = $1;
					if($start != $end) {
						return $start <=> $end;
					}
				}
			}
		}

		if($left =~ /^(\d{3,4})\sor\s(\d{3,4})$/) {
			# e.g. "1802 or 1803"
			my($start, $end) = ($1, $2);
			if($start == $end) {
				$complain->("the years are the same '$left'") if($complain);
			}
			$left = $start
		} elsif(($left =~ /^(\d{3,4})\-(\d{3,4})$/) || ($left =~ /^Bet (\d{3,4})\sand\s(\d{3,4})$/i)) {
			# Comparing with a date range, e.g. "BET 1830 AND 1832 <=> 1830-02-06"
			my ($from, $to) = ($1, $2);
			if($from == $to) {
				$complain->("from == to, $from") if($complain);
				$left = $from;
			} elsif($from > $to) {
				print STDERR "datecmp(): $from > $to in daterange '$left'\n";
				my $i = 0;
				while((my @call_details = caller($i++))) {
					print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
				}
				return 0;
			} else {
				if(ref($right)) {
					$right = $right->year();
				} elsif($right !~ /^\d{4}$/) {
					my @r = $dfg->parse_datetime({ date => $right, quiet => 1 });
					if(!defined($r[0])) {
						if($right =~ /[\s\/](\d{4})$/) {
							# e.g. cmp "1891 <=> Oct/Nov/Dec 1892"
							# or 5/27/1872
							my $year = $1;
							if(ref($left)) {
								if($left->year() != $year) {
									return $left->year() <=> $year;
								}
							} else {
								if($left != $year) {
									return $left <=> $year;
								}
							}
						}
						# TODO: throw an error that we can catch
						my $i = 0;
						while((my @call_details = caller($i++))) {
							print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
						}
						die "Date parse failure: right = '$right' ($left <=> $right)";
					}
					$right = $r[0]->year();
				}
				if($right < $from) {
					return 1;
				}
				if($right > $to) {
					return -1;
				}
				if($right == $from) {
					return 0;
				}
				if(($right > $from) && ($right < $to)) {
					# E.g. "BET 1900 AND 1902" <=> 1901
					return 0;
				}
				print STDERR "datecmp(): Can't compare $left with $right\n";
				my $i = 0;
				while((my @call_details = caller($i++))) {
					print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
				}
				return 0;
			}
		} elsif($left !~ /^\d{3,4}$/) {
			if($left =~ /^\d{4}\-\d{2}\-\d{2}$/) {
				# e.g. 1941-08-02
			} elsif(($left !~ /[a-z]/i) || ($left =~ /[a-z]$/)) {
				my $i = 0;
				while((my @call_details = caller($i++))) {
					print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
				}
				die "Date parse failure: left = '$left' ($left <=> $right)";
			}

			my @l = $dfg->parse_datetime({ date => $left, quiet => 1 });
			my $rc = $l[1] || $l[0];
			if(!defined($rc)) {
				my $i = 0;
				while((my @call_details = caller($i++))) {
					print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
				}
				die "Date parse failure: left = '$left' ($left <=> $right)";
			}
			$left = $rc;
		}
	}
	if(!ref($right)) {
		if($right =~ /^bef/i) {
			if($left =~ /^\d+$/) {
				# For example, comparing 1939 <=> bef 1 Jun 1965
				if($right =~ /\s(\d+)$/) {
					return $left <=> $1;
				}
			}
			print STDERR "$left <=> $right: Before not handled\n";
			my $i = 0;
			while((my @call_details = caller($i++))) {
				print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
			}
			return 0;
		}
		if($right =~ /^(Abt|ca?)\.?\s+(.+)/i) {
			$right = $2;
		} elsif(($right =~ /\//) && ($right =~ /^[a-z\/]+\s+(.+)/i)) {
			# e.g. "Oct/Nov/Dec 1950"
			$right = $1;
		}

		if($right =~ /^\d{3,4}$/) {
			if(ref($left)) {
				return $left->year() <=> $right;
			}
			return $left <=> $right;
		}

		if(($right =~ /^(\d{3,4})\-(\d{3,4})$/) || ($right =~ /^Bet (\d{3,4})\sand\s(\d{3,4})$/i)) {
			# Comparing with a date range
			my ($from, $to) = ($1, $2);
			if($from == $to) {
				$complain->("from == to, $from") if($complain);
				$right = $from;
			} elsif($from > $to) {
				print STDERR "datecmp(): $from > $to in daterange '$right'\n";
				my $i = 0;
				while((my @call_details = caller($i++))) {
					print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
				}
				return 0;
			} else {
				if(ref($left)) {
					$left = $left->year();
				}
				if($left < $from) {
					return -1;
				}
				if($left > $to) {
					return 1;
				}
				if($left == $from) {
					return 0;
				}
				if(($left > $from) && ($left < $to)) {
					# E.g. 1901 <=> "BET 1900 AND 1902"
					return 0;
				}
				print STDERR "datecmp(): Can't compare $left with $right\n";
				my $i = 0;
				while((my @call_details = caller($i++))) {
					print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
				}
				return 0;
			}
		}

		if($left =~ /(\d{3,4})/) {
			my $start = $1;
			if($right =~ /(\d{3,4})/) {
				# e.g. 26 Aug 1744 <=> 1673-02-22T00:00:00
				my $end = $1;
				if($start != $end) {
					return $start <=> $end;
				}
			}
		}

		# if(!$dfg->parse_datetime($right)) {
			# my $i = 0;
			# while((my @call_details = caller($i++))) {
				# print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
			# }
			# die join('<=>', @_);
		# }
		my @r = $dfg->parse_datetime({ date => $right, quiet => 1 });
		if(!defined($r[0])) {
			if($right =~ /[\s\/](\d{4})$/) {
				# e.g. cmp "1891 <=> Oct/Nov/Dec 1892"
				# or 5/27/1872
				my $year = $1;
				if(ref($left)) {
					if($left->year() != $year) {
						return $left->year() <=> $year;
					}
				} else {
					if($left != $year) {
						return $left <=> $year;
					}
				}
			}
			# TODO: throw an error that we can catch
			my $i = 0;
			while((my @call_details = caller($i++))) {
				print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
			}
			die "Date parse failure: right = '$right' ($left <=> $right)";
		}
		$right = $r[0];
	}
	if((!ref($left)) && ref($right)) {
		return $left <=> $right->year();
	}
	if(ref($left) && (!ref($right))) {
		return $left->year() <=> $right;
	}

	return $left <=> $right;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

L<Sort::Key::DateTime>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-date-cmp at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Cmp>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Date::Cmp

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
