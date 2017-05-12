package MyAppDefault::Main;

use strict;
use base qw(App::CLI::Command);
use Scalar::Util qw(refaddr);

sub run {

    my($self, @args) = @_;
	$main::DBI_DEFAULT_HANDLE = $self->dbi_default_handle;
	$main::DBI_OBJ1_ADDR = refaddr($self->dbh);
	$main::DBI_OBJ2_ADDR = refaddr($self->dbh($self->dbi_default_handle));
}

1;

