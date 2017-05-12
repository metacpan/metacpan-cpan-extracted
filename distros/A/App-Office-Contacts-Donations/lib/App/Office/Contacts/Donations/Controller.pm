package App::Office::Contacts::Donations::Controller;

use parent 'App::Office::Contacts';
use strict;
use warnings;

use App::Office::Contacts::Donations::Database;
use App::Office::Contacts::Donations::Util::Config;
use App::Office::Contacts::Donations::View;

use Log::Dispatch;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.10';

# -----------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;

	# Can't call, since logger not yet set up.
	#$self -> log(debug => 'Entered cgiapp_prerun');

	$self -> param(config => App::Office::Contacts::Donations::Util::Config -> new -> config);

	# Set up half the logger, but don't use it until the dbh is available.

	$self -> param(logger => Log::Dispatch -> new);

	# Set up the database.

	$self -> param(db => App::Office::Contacts::Donations::Database -> new);

	# Set up the things shared by:
	# o App::Office::Contacts
	# o App::Office::Contacts::Donations
	# o App::Office::Contacts::Import::vCards

	$self -> global_prerun;

	# Set up the view.

	$self -> param(view => App::Office::Contacts::Donations::View -> new
	(
		db          => $self -> param('db'),
		script_name => $self -> script_name,
		session     => $self -> param('session'),
		tmpl_path   => $self -> tmpl_path,
	) );

	if ($self -> validate_post == 0)
	{
		$self -> prerun_mode('Initialize');
	}

} # End of cgiapp_prerun.

# -----------------------------------------------

1;
