package Carp::Parse;

use 5.010;

use warnings;
use strict;

use Carp;
use Carp::Parse::CallerInformation;


=head1 NAME

Carp::Parse - Parse a Carp stack trace into an array of caller information with parsed arguments.


=head1 DESCRIPTION

Carp produces a stacktrace that includes caller arguments; this module parses
each line of the stack trace to extract its arguments, which allows rewriting
the stack trace (for example, to redact sensitive information).


=head1 VERSION

Version 1.0.7

=cut

our $VERSION = '1.0.7';

our $MAX_ARGUMENTS_PER_CALL = 1000;


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
	use Carp::Parse;
	my $parsed_stack_trace = Carp::Parse::parse_stack_trace( $stack_trace );
	
	use Data::Dump qw( dump );
	foreach my $caller_information ( @$parsed_stack_trace )
	{
		# Print the arguments for each caller.
		say dump( $caller->get_arguments_list() );
	}


=head1 FUNCTIONS

=head2 parse_stack_trace()

Parse a stack trace produced by C<Carp> into an arrayref of
C<Carp::Parse::CallerInformation> objects.

	my $parsed_stack_trace = Carp::Parse::parse_stack_trace( $stack_trace );

=cut

sub parse_stack_trace
{
	my ( $stack_trace ) = @_;
	
	# Verify parameters.
	croak 'Specify a stack trace to parse as first argument'
		if !defined( $stack_trace ) || ( $stack_trace eq '' );
	
	my $parsed_stack_trace = [];
	
	# The first part of the stack trace holds the message logged, which may
	# include newlines so we need to parse it separately.
	my ( $first_caller ) = $stack_trace =~ /^(.*?at.*?line\s*\d*\n)/sx;
	$first_caller //= '';
	$stack_trace =~ s/\Q$first_caller\E//;

	push(
		@$parsed_stack_trace,
		Carp::Parse::CallerInformation->new(
			{
				line => $first_caller,
			}
		),
	);
	
	# Parse the other lines, which is straightforward as Carp replaces newlines
	# in the function arguments with \\x{a}.
	foreach my $line ( split( /\n/, $stack_trace ) )
	{
		my ( $subroutine_arguments ) = $line =~ /\((.*)\)/;
		next unless defined( $subroutine_arguments );
		
		# Why don't we eval() the string here into an array? This looks so simple!
		# Unfortunately, subroutine arguments are not quoted correct by Carp in
		# cases like the following:
		# main::test_trace('password', 'thereisnotry', 'planet', 'degobah', 'ship_zip', 01138, 'username', 'yoda') called at test/lib/Sphorb/Utils/Logger/40-redacted.t line 47
		# This would fail trying to eval 01138 as an octal due to the lack of quotes,
		# but 8 is not a valid digit for that.
		my @arguments = ();
		my $parse_arguments = $subroutine_arguments;
		my $arguments_count = 0;
		my $incorrect_arguments_format_detected = 0;
		while (
			defined( $parse_arguments )
			&& ( $parse_arguments ne '' )
			&& ( $arguments_count < $MAX_ARGUMENTS_PER_CALL )
			&& !$incorrect_arguments_format_detected
		)
		{
			my ( $value );
			# Note: we need to account for both single and double quotes here
			# as Carp has changed its internals over time and the quoting style
			# depends on the version of Carp.
			my $first_character = substr( $parse_arguments, 0, 1 );
			if ( $first_character eq '"' || $first_character eq "'" )
			{
				# If it starts with a quote, we use a negative lookbehind to find the
				# matching closing quote, which should be a quote not preceded by a backslash
				# (which would indicate an escaped quote that's part of the data).
				( $value ) = $parse_arguments =~ /^$first_character(.*?)(?<!\\)$first_character/;
				if ( defined( $value ) )
				{
					$parse_arguments =~ s/\Q$first_character$value$first_character\E//;
				}
				else
				{
					$incorrect_arguments_format_detected = 1;
				}
			}
			else
			{
				# If it doesn't start with a quote, we just take all the following
				# characters as long as they're not commas.
				( $value ) = $parse_arguments =~ /^([^,]*)/;
				if ( defined( $value ) )
				{
					$parse_arguments =~ s/\Q$value\E//;
				}
				else
				{
					$incorrect_arguments_format_detected = 1;
				}
			}
			
			if ( !$incorrect_arguments_format_detected )
			{
				push( @arguments, $value );
				
				# Remove the comma that followed the argument (if it's not the last one).
				$parse_arguments =~ s/^\s*,\s*//;
			
				# Make sure we never get into an infinite loop, in case the format of the
				# stacktrace is somehow broken.
				$arguments_count++;
				carp "Max limit of arguments per call reached, showing the first $MAX_ARGUMENTS_PER_CALL only."
					if $arguments_count == $MAX_ARGUMENTS_PER_CALL;
			}
			else
			{
				@arguments = ( '[incorrect arguments format]' );
			}
		}
		
		push(
			@$parsed_stack_trace,
			Carp::Parse::CallerInformation->new(
				{
					line             => $line,
					arguments_list   => \@arguments,
					arguments_string => $subroutine_arguments,
				}
			),
		);
	}
	
	return $parsed_stack_trace;
}


=head1 AUTHOR

Kate Kirby, C<< <kate at cpan.org> >>.

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-carp-parse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-Parse>. 
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Carp::Parse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Parse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carp-Parse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Carp-Parse>

=item * Search CPAN

L<http://search.cpan.org/dist/Carp-Parse/>

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
