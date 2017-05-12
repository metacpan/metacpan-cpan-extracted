package DBIx::NinjaORM::Utils;

use 5.010;

use strict;
use warnings;

use Carp;
use Data::Dumper ();
use Data::Validate::Type;

use base 'Exporter';

our @EXPORT_OK = qw(
	dumper
);


=head1 NAME

DBIx::NinjaORM::Utils - Utility functions for L<DBIX::NinjaORM>.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 DESCRIPTION

Collection of utility functions used by L<DBIX::NinjaORM> to perform various
ancillary tasks.


=head1 SYNOPSIS

	use DBIx::NinjaORM::Utils qw( dumper );

	my $string = dumper( $data_structure );


=head1 FUNCTIONS

=head2 dumper()

Utility to stringify data structures.

	my $string = DBIx::NinjaORM::Utils::dumper( @data );

Internally, this uses Data::Dumper::Dumper, but you can switch it to a custom
dumper with the following code:

	local $DBIx::NinjaORM::Utils::DUMPER = sub
	{
		my ( @refs ) = @_;

		# Create a stringified version.

		return $string;
	};

=cut

our $DUMPER = undef;

sub dumper
{
	my ( @data ) = @_;

	if ( defined( $DUMPER ) )
	{
		carp "The custom dumper function is not a valid code reference"
			if !Data::Validate::Type::is_coderef( $DUMPER );

		return $DUMPER->( @data );
	}
	else
	{
		return Data::Dumper::Dumper( @data );
	}
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc DBIx::NinjaORM::Utils


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-NinjaORM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-NinjaORM>

=item * MetaCPAN

L<https://metacpan.org/release/DBIx-NinjaORM>

=back


=head1 AUTHOR

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;

