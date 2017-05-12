#!/usr/bin/perl

package
BerkeleyDB::Manager::Test;

use strict;
use warnings;

use BerkeleyDB;

use Test::More;

use base qw(Exporter);

our @EXPORT = qw(sok);

sub import {
	my ($self, $version, @plan ) = @_;

	if ( $version ) {
		if ( $BerkeleyDB::db_version < $version ) {
			plan skip_all => "DB $version required for this test ($BerkeleyDB::db_version available)";
		} else {
			plan @plan;
		}
	}

	$self->export_to_level(1, $self);
}

sub sok ($;$) {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok( $_[0] == 0, ( @_ > 1 ? $_[1] : () ) ) || diag("$BerkeleyDB::Error (status == $_[0])");
}

__PACKAGE__

__END__
