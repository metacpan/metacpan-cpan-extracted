#!/usr/bin/perl
######################################################

use strict;

package Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object;
use Authen::PluggableCaptcha::KeyManagerDB::RoseDB ();
use Rose::DB::Object ();
use base qw(Rose::DB::Object);

sub init_db { Authen::PluggableCaptcha::KeyManagerDB::RoseDB->new };

sub found {
	my 	( $self )= @_;
	return $self->not_found ? 0 : 1 ;
}

1;