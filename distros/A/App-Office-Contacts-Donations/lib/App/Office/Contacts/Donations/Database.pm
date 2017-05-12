package App::Office::Contacts::Donations::Database;

use App::Office::Contacts::Donations::Database::Donations;
use App::Office::Contacts::Donations::Database::Util;

use Moose;

extends 'App::Office::Contacts::Database';

has donations => (is => 'rw', isa => 'App::Office::Contacts::Donations::Database::Donations');

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> donations(App::Office::Contacts::Donations::Database::Donations -> new
	(
		db => $self,
	) );

}	# End of BUILD.

# --------------------------------------------------

sub init
{
	my($self) = @_;

	$self -> util(App::Office::Contacts::Donations::Database::Util -> new
	(
		db => $self,
	) );

} # End of init.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
