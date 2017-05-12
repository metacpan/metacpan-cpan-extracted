package MyAppFail::Plugin::Fail;

use strict;

sub fail {

    my($self, @argv) = @_;
    $main::RESULT = $self->e->text; 
	$self->exit_value(1);
	#$self->maybe::next::method(@argv);
}

1;
