package Carp::Parse::CallerInformation::Redacted;

use warnings;
use strict;

use Carp;
use Data::Dump;

use base 'Carp::Parse::CallerInformation';


=head1 NAME

Carp::Parse::CallerInformation::Redacted - Represent the parsed caller information for a line of the Carp stack trace.


=head1 DESCRIPTION

This module inherits from Carp::Parse::CallerInformation and adds the
get_redacted_arguments_list() method to it. See C<Carp::Parse::CallerInformation>
for the list of all the methods this module offers.

As a user, you should not have to create Carp::Parse::CallerInformation objects
yourself, they will get created for you by C<Carp::Parse::Redact>.


=head1 VERSION

Version 1.1.5

=cut

our $VERSION = '1.1.5';


=head1 SYNOPSIS

	# Retrieve the redacted arguments array.
	my $redacted_arguments_list = $caller_information->get_redacted_arguments_list();


=head1 METHODS

=head2 new()

Create a new C<Carp::Parse::CallerInformation::Redacted> object.

	my $redacted_caller_information = Carp::Parse::CallerInformation::Redacted->new(
		{
			arguments_string        => $arguments_string,
			arguments_list          => $arguments_list,
			redacted_arguments_list => $redacted_arguments_list,
			line                    => $line,
		}
	);

=cut

sub new
{
	my ( $class, $data ) = @_;
	
	# Verify parameters.
	croak 'The first argument must be a hashref with the data to set on the object.'
		unless defined( $data ) && UNIVERSAL::isa( $data, 'HASH' ); ## no critic (BuiltinFunctions::ProhibitUniversalIsa)
	my $line = delete( $data->{'line'} );
	my $arguments_string = delete( $data->{'arguments_string'} );
	my $arguments_list = delete( $data->{'arguments_list'} );
	my $redacted_arguments_list = delete( $data->{'redacted_arguments_list'} );
	croak "The data hashref must contain the 'line' key with the original stack line"
		unless defined( $line );
	croak "The following parameters are not supported: " . Data::Dump::dump( $data )
		if scalar( keys %$data ) != 0;
	
	return bless(
		{
			line                    => $line,
			arguments_string        => $arguments_string,
			arguments_list          => $arguments_list,
			redacted_arguments_list => $redacted_arguments_list,
		},
		$class,
	);
}


=head2 get_redacted_arguments_list()

Return an arrayref of the arguments parsed for this caller, with the sensitive
arguments redacted out.

	my $redacted_arguments_list = $caller_information->get_redacted_arguments_list();

=cut

sub get_redacted_arguments_list
{
	my ( $self ) = @_;
	
	return $self->{'redacted_arguments_list'};
}


=head2 get_redacted_line()

Return the redacted version of the original line from the stack trace.

	my $redacted_line = $caller_information->get_redacted_line();

=cut

sub get_redacted_line
{
	my ( $self ) = @_;
	
	my $line = $self->get_line();
	my $arguments_string = $self->get_arguments_string();
	
	if ( defined( $arguments_string ) )
	{
		my $redacted_arguments_list = $self->get_redacted_arguments_list() || [];
		
		# Data::Dump::dump() is really nice except that it treats arrays with
		# only one member as a string, so we need to make an exception for
		# formatting in that case.
		my $redacted_arguments_string = Data::Dump::dump( @$redacted_arguments_list );
		$redacted_arguments_string = "($redacted_arguments_string)"
			if scalar( @$redacted_arguments_list ) == 1;
		
		# Data::Dump::dump() may format the output on more than one line.
		# We make sure that the indentation of the original line is carried
		# here to the new lines.
		my ( $indentation ) = $line =~ /^(\s*)/;
		$redacted_arguments_string =~ s/(\r?\n)/$1$indentation/gs;
		
		$line =~ s/\(\Q$arguments_string\E\)/$redacted_arguments_string/x;
	}
	
	return $line
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

	perldoc Carp::Parse::CallerInformation::Redacted


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
