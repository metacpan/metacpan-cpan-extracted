package MyAppFinish::Finished;

use strict;
use base qw(App::CLI::Command);

sub options {

	return ("finished" => "finished");
}


sub prepare {

    my($self, @args) = @_;
	if (defined $self->{'finished'}) {
		$self->finished(1);
	}
}

sub run {

    my($self, @args) = @_;
	$main::RESULT = "RUN";
}

1;

