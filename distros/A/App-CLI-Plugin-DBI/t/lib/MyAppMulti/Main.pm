package MyAppMulti::Main;

use strict;
use base qw(App::CLI::Command);
use Scalar::Util qw(refaddr);

sub run {

    my($self, @args) = @_;

	$main::DBI_OBJ1_ADDR = refaddr($self->dbh("other1"));
	$main::DBI_OBJ2_ADDR = refaddr($self->dbh("other2"));
}

1;

