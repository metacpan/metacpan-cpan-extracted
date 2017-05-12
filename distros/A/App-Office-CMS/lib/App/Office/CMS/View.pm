package App::Office::CMS::View;

use Any::Moose;
use common::sense;

extends 'App::Office::CMS::View::Base';

use App::Office::CMS::View::Content;
use App::Office::CMS::View::Page;
use App::Office::CMS::View::Search;
use App::Office::CMS::View::Site;

has content =>
(
	is  => 'rw',
	isa => 'App::Office::CMS::View::Content',
);

has page =>
(
	is  => 'rw',
	isa => 'App::Office::CMS::View::Page',
);

has search =>
(
	is  => 'rw',
	isa => 'App::Office::CMS::View::Search',
);

has site =>
(
	is  => 'rw',
	isa => 'App::Office::CMS::View::Site',
);

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> content(App::Office::CMS::View::Content -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	 tmpl_path   => $self -> tmpl_path,
	) );

	$self -> page(App::Office::CMS::View::Page -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	 tmpl_path   => $self -> tmpl_path,
	) );

	$self -> search(App::Office::CMS::View::Search -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	 tmpl_path   => $self -> tmpl_path,
	) );

	$self -> site(App::Office::CMS::View::Site -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	 tmpl_path   => $self -> tmpl_path,
	) );

}	# End of BUILD.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
