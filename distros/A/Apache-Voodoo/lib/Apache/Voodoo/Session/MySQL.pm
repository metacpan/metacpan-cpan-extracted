package Apache::Voodoo::Session::MySQL;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache::Session::MySQL;

use Apache::Voodoo::Session::Instance;

sub new {
	my $class = shift;
	my $conf  = shift;

	my $self = {};

	bless $self,$class;

	$self->{session_table} = $conf->{'session_table'};

	return $self;
}

sub attach {
	my $self = shift;
	my $id   = shift;
	my $dbh  = shift;

	my %opts = @_;

	my %session;
	my $obj;

	$opts{'TableName'}  = $self->{'session_table'};
	$opts{'Handle'}     = $dbh;
	$opts{'LockHandle'} = $dbh;

	if (defined($id) && $id !~ /^([0-9a-z]+)$/) {
		$id = undef;
	}

	eval {
		$obj = tie(%session,'Apache::Session::MySQL',$id, \%opts) || die "Tieing to session failed: $!";
	};
	if ($@) {
		undef $id;
		$obj = tie(%session,'Apache::Session::MySQL',$id, \%opts) || die "Tieing to session failed: $!";
	}

	return Apache::Voodoo::Session::Instance->new($obj,\%session);
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
