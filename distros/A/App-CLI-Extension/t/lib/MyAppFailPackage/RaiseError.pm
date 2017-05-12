package MyAppFailPackage::RaiseError;

use strict;
use base qw(App::CLI::Command);

sub options {

	return ("throw" => "throw");
}

sub run {

    my($self, @args) = @_;
	my $message = "dying message";
	if (defined $self->{'throw'}) {
    	$self->throw($message);
	} else {
		die $message;
	}
}

sub fail {
	
    my($self, @args) = @_;
	$main::RESULT = ref($self->e);
}

1;

