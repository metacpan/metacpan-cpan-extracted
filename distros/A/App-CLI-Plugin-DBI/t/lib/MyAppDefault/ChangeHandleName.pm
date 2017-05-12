package MyAppDefault::ChangeHandleName;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
	$self->dbi_default_handle("new_name");

	$main::RESULT = $self->dbi_default_handle;
}

1;

