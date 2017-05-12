package Carp::Parse::Redact;

use warnings;
use strict;

use Carp;
use Carp::Parse;
use Carp::Parse::CallerInformation::Redacted;
use Data::Validate::Type;


=head1 NAME

Carp::Parse::Redact - Parse a Carp stack trace into an array of caller information, while redacting sensitive function parameters out.


=head1 DESCRIPTION

Carp produces a stacktrace that includes caller arguments; this module parses
each line of the stack trace to extract its arguments and redacts out the
sensitive information contained in the function arguments for each caller.


=head1 VERSION

Version 1.1.5

=cut

our $VERSION = '1.1.5';


=head1 DEFAULTS FOR REDACTING SENSITIVE DATA

=head2 Redacting using hash keys

By default, this module will redact values for which the argument name is:

=over 4

=item * password

=item * passwd

=item * cc_number

=item * cc_exp

=item * ccv

=back

You can easily change this list when parsing a stack trace by passing the
argument I<sensitive_argument_names> when calling C<parse_stack_trace()>.

=cut

my $DEFAULT_ARGUMENTS_REDACTED =
[
	qw(
		password
		passwd
		cc_number
		cc_exp
		ccv
	)
];


=head2 Redacting using regular expressions

By default, this module will redact subroutine arguments in the stack traces
that match the following patterns:

=over 4

=item * Credit card numbers (VISA, MasterCard, American Express, Diners Club, Discover, JCB)

=back

=cut

my $DEFAULT_REGEXP_REDACTED =
[
	# Credit card patterns.
	qr/
		\b
			(?:
				# VISA starts with 4         and has 13 or 16 digits
				4                            [0-9]{12}        (?:[0-9]{3})?
			|
				# MasterCard start with
				# 51 through 55              and has 16 digits
				5[1-5]                       [0-9]{14}
			|
				# American Express starts
				# with 34 or 37              and has 15 digits
				3[47]                        [0-9]{13}
			|
				# Diners Club starts with
				# 300 through 305
				# or 36 or 38                and has 14 digits in either case
				3 (?:0[0-5]|[68][0-9])       [0-9]{11}
			|
				# Discover starts with
				# 6011 or 65                 and has 16 digits
				6 (?:011|5[0-9]{2})          [0-9]{12}
			|
				# JCB starts with
				# 2131 or 1800               and has 15 digits
				# or starts with 35          and has 16 digits
				(?:2131|1800|35[0-9]{3})     [0-9]{11}
			)
		\b
	/x,
];


=head1 SYNOPSIS

	# Retrieve a Carp stack trace with longmess(). This is tedious, but you will
	# normally be using this module in a context where the stacktrace is already
	# generated for you and you want to parse it, so you won't have to go through
	# this step.
	sub test3 { return Carp::longmess("Test"); }
	sub test2 { return test3(); }
	sub test1 { return test2(); }
	my $stack_trace = test1();
	
	# Parse the Carp stack trace.
	# The call takes an optional list of arguments to redact, if you don't want
	# to use the default.
	use Carp::Parse::Redact;
	my $redacted_parsed_stack_trace = Carp::Parse::Redact::parse_stack_trace(
		$stack_trace,
		sensitive_argument_names  => #optional
		[
			'password',
			'passwd',
			'cc_number',
			'cc_exp',
			'ccv',
		],
		sensitive_regexp_patterns => #optional
		[
			qr/^\d{16}$/,
		]
	);
	
	use Data::Dump qw( dump );
	foreach my $caller_information ( @$parsed_stack_trace )
	{
		# Print the arguments for each caller.
		say dump( $caller->get_redacted_arguments_list() );
	}


=head1 FUNCTIONS

=head2 parse_stack_trace()

Parse a stack trace produced by C<Carp> into an arrayref of
C<Carp::Parse::CallerInformation::Redacted> objects and redact out the sensitive
information from each function caller arguments.

	my $redacted_parsed_stack_trace = Carp::Parse::Redact::parse_stack_trace( $stack_trace );
	
	my $redacted_parsed_stack_trace = Carp::Parse::Redact::parse_stack_trace(
		$stack_trace,
		sensitive_argument_names => #optional
		[
			password
			passwd
			cc_number
			cc_exp
			ccv
		],
		sensitive_regexp_patterns => #optional
		[
			qr/^\d{16}$/,
		]
	);

The first argument, a stack trace, is required. Optional parameters:

=over 4

=item * sensitive_argument_names

An arrayref of argument names to redact, when they are found in hashes of
arguments in the stack trace. If not set, see the list of defaults used at the
top of this documentation.

=item * sensitive_regexp_patterns

An arrayref of regular expressions. If an argument in the list of subroutine
calls in the stack trace matches any of the patterns, it will be redacted.
If not set, see the list of defaults used at the top of this documentation.

=back

=cut

sub parse_stack_trace
{
	my ( $stack_trace, %args ) = @_;
	
	# Verify parameters.
	my $sensitive_argument_names = delete( $args{'sensitive_argument_names'} ) || $DEFAULT_ARGUMENTS_REDACTED;
	croak "'sensitive_argument_names' must be an arrayref"
		if !Data::Validate::Type::is_arrayref( $sensitive_argument_names );
	
	my $sensitive_regexp_patterns = delete( $args{'sensitive_regexp_patterns'} ) || $DEFAULT_REGEXP_REDACTED;
	croak "'sensitive_regexp_patterns' must be an arrayref"
		if !Data::Validate::Type::is_arrayref( $sensitive_regexp_patterns );
	
	croak "The following parameters are not supported: " . Data::Dump::dump( %args )
		if scalar( keys %args ) != 0;
	
	# Make a hash of arguments to redact.
	my $arguments_redacted =
	{
		map { $_ => 1 }
		@$sensitive_argument_names
	};
	
	# Get the parsed stack trace from Carp::Parse.
	my $parsed_stack_trace = Carp::Parse::parse_stack_trace( $stack_trace );
	
	# Redact sensitive information.
	my $redacted_parsed_stack_trace = [];
	foreach my $caller_information ( @{ $parsed_stack_trace || [] } )
	{
		# Scan for hash keys matching our list of sensitive argument names.
		my $redact_next = 0;
		my $redacted_arguments_list = [];
		foreach my $argument ( @{ $caller_information->get_arguments_list() || [] } )
		{
			if ( $redact_next )
			{
				push( @$redacted_arguments_list, '[redacted]' );
				$redact_next = 0;
			}
			else
			{
				push( @$redacted_arguments_list, $argument );
				$redact_next = 1 if defined( $argument ) && $arguments_redacted->{ $argument };
			}
		}
		
		# Scan all arguments against patterns to redact sensitive information
		# that wouldn't have been passed in a hash.
		foreach my $argument ( @$redacted_arguments_list )
		{
			next unless defined( $argument );
			next if $argument eq '[redacted]';
			
			my $matches_pattern = 0;
			foreach my $regexp ( @$DEFAULT_REGEXP_REDACTED )
			{
				next unless $argument =~ $regexp;
				$matches_pattern = 1;
				last;
			}
			
			$argument = '[redacted]'
				if $matches_pattern;
		}
		
		push(
			@$redacted_parsed_stack_trace,
			Carp::Parse::CallerInformation::Redacted->new(
				{
					arguments_string        => $caller_information->get_arguments_string(),
					arguments_list          => $caller_information->get_arguments_list(),
					redacted_arguments_list => $redacted_arguments_list,
					line                    => $caller_information->get_line(),
				},
			),
		);
	}
	
	return $redacted_parsed_stack_trace;
}


=head1 AUTHOR

Kate Kirby, C<< <kate at cpan.org> >>.

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-carp-parse-redact at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-Parse-Redact>. 
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Carp::Parse::Redact


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Parse-Redact>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carp-Parse-Redact>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Carp-Parse-Redact>

=item * Search CPAN

L<http://search.cpan.org/dist/Carp-Parse-Redact/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while we eat pizza
and write code for them!


=head1 COPYRIGHT & LICENSE

Copyright 2012 Kate Kirby & Guillaume Aubert.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/

=cut

1;
