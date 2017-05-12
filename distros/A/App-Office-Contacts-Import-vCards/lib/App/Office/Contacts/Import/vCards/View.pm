package App::Office::Contacts::Import::vCards::View;

use App::Office::Contacts::Import::vCards::View::vCards;
use App::Office::Contacts::View::Person;

use Moose;

extends 'App::Office::Contacts::View::Base';

# Warning: import is a reserved word, so we use viewer.
# Error msg: Can't use string ("App::Office::Contacts::Import::v") as a HASH ref...

has person => (is => 'rw', isa => 'App::Office::Contacts::View::Person');
has viewer => (is => 'rw', isa => 'App::Office::Contacts::Import::vCards::View::vCards');

use namespace::autoclean;

our $VERSION = '1.12';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> person(App::Office::Contacts::View::Person -> new
	(
		db          => $self -> db,
		script_name => $self -> script_name,
		session     => $self -> session,
		tmpl_path   => $self -> tmpl_path,
	) );

	$self -> viewer(App::Office::Contacts::Import::vCards::View::vCards -> new
	(
		db          => $self -> db,
		script_name => $self -> script_name,
		session     => $self -> session,
		tmpl_path   => $self -> tmpl_path,
	) );

}	# End of BUILD.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
