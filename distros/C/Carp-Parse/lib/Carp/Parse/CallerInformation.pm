package Carp::Parse::CallerInformation;

use warnings;
use strict;

use Carp;
use Data::Dump;


=head1 NAME

Carp::Parse::CallerInformation - Represent the parsed caller information for a line of the Carp stack trace.


=head1 VERSION

Version 1.0.7

=cut

our $VERSION = '1.0.7';


=head1 SYNOPSIS

See the synopsis of C<Carp::Parse> for a full example that generates
Carp::Parse::CallerInformation objects. As a user, you should not have to
create Carp::Parse::CallerInformation objects yourself.

	# Retrieve the arguments string.
	my $arguments_string = $caller_information->get_arguments_string();
	
	# Retrieve the arguments array.
	my $arguments_list = $caller_information->get_arguments_list();
	
	# Retrieve the original line, pre-parsing.
	my $line = $caller_information->get_line();


=head1 METHODS

=head2 new()

Create a new C<Carp::Parse::CallerInformation> object.

	my $caller_information = Carp::Parse::CallerInformation->new(
		{
			arguments_string => $arguments_string,
			arguments_list   => $arguments_list,
			line             => $line,
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
	croak "The data hashref must contain the 'line' key with the original stack line"
		unless defined( $line );
	croak "The following parameters are not supported: " . Data::Dump::dump( $data )
		if scalar( keys %$data ) != 0;
	
	return bless(
		{
			line             => $line,
			arguments_string => $arguments_string,
			arguments_list   => $arguments_list,
		},
		$class,
	);
}


=head2 get_arguments_string()

Return a string of the arguments parsed for this caller.

	my $arguments_string = $caller_information->get_arguments_string();

=cut

sub get_arguments_string
{
	my ( $self ) = @_;
	
	return $self->{'arguments_string'};
}


=head2 get_arguments_list()

Return an arrayref of the arguments parsed for this caller.

	my $arguments_list = $caller_information->get_arguments_list();

=cut

sub get_arguments_list
{
	my ( $self ) = @_;
	
	return $self->{'arguments_list'};
}


=head2 get_line()

Return the original line from the stack trace.

	my $line = $caller_information->get_line();

=cut

sub get_line
{
	my ( $self ) = @_;
	
	return $self->{'line'};
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

	perldoc Carp::Parse::CallerInformation


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
