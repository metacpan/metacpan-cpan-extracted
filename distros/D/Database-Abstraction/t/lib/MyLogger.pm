package MyLogger;

use strict;
use warnings;

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

# sub error {
	# my $self = shift;
	# my $message = shift;
#
	# ::diag($message);
# }

sub warn {
	my $self = shift;
	my $message = shift;

	::diag($message);
}

# sub info {
	# my $self = shift;
	# my $message = shift;
#
	# ::diag($message);
# }

sub trace {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub debug {
	my $self = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag(@_);
	}
}

sub AUTOLOAD {
	our $AUTOLOAD;
	my $param = $AUTOLOAD;

	if($param ne 'MyLogger::DESTROY') {
		::diag("Need to define $param");
	}
}

1;
