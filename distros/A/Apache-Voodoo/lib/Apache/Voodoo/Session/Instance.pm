package Apache::Voodoo::Session::Instance;

$VERSION = "3.0200";

use strict;
use warnings;

sub new {
	my $class   = shift;
	my $obj     = shift;
	my $session = shift;

	my $self = {};

	bless $self,$class;

	$self->{obj}     = $obj;
	$self->{session} = $session;

	$self->{id} = $session->{_session_id};

	$self->{connected} = 1;

	return $self;
}

sub id      { return $_[0]->{id};      }
sub session { return $_[0]->{session}; }
sub obj     { return $_[0]->{obj};     }

sub has_expired {
	my $self    = shift;
	my $timeout = shift;

	if ($timeout > 0 && $self->{session}->{_session_timestamp} < (time - ($timeout*60))) {
		return 1;
	}
	else {
		return 0;
	}
}

sub touch {
	my $self = shift;

	$self->{session}->{_session_timestamp} = time;
}

sub disconnect {
	my $self = shift;

	if ($self->{connected}) {
		# this produces an unavoidable warning.
		{
			no warnings;
			untie(%{$self->{session}});
		}
		$self->{connected} = 0;
	}
}

sub destroy {
	my $self = shift;

	$self->{obj}->delete;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
