#!usr/bin/perl

package t::TestUTX_TBX;
use Test::Base -base;

1;

package t::TestUTX_TBX::Filter;
use Test::Base::Filter -base;
use strict;
use warnings;
use Convert::TBX::UTX qw(utx2min min2utx);

sub convert_utx {
	my ($self, $data) = @_;
	my $converted = utx2min(\$data);
	return $$converted;
}

sub convert_tbx {
	my ($self, $data) = @_;
	my $converted = min2utx(\$data);
	return $$converted;
}
