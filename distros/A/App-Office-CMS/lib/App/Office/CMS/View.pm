package App::Office::CMS::View;

use strict;
use warnings;

use Moo;

use Types::Standard qw/Any/;

extends 'App::Office::CMS::View::Base';

use App::Office::CMS::View::Content;
use App::Office::CMS::View::Page;
use App::Office::CMS::View::Search;
use App::Office::CMS::View::Site;

has content =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::View::Content',
);

has page =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::View::Page',
);

has search =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::View::Search',
);

has site =>
(
	is  => 'rw',
	isa => Any, # 'App::Office::CMS::View::Site',
);

our $VERSION = '0.93';

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
	) );

	$self -> page(App::Office::CMS::View::Page -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	) );

	$self -> search(App::Office::CMS::View::Search -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	) );

	$self -> site(App::Office::CMS::View::Site -> new
	(
	 config      => $self -> config,
	 form_action => $self -> form_action,
	 db          => $self -> db,
	 session     => $self -> session,
	 templater   => $self -> templater,
	) );

}	# End of BUILD.

# --------------------------------------------------

1;
