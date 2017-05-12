#!/usr/bin/perl -w
# $Id: 3aliases.t,v 1.3 2006-02-05 00:04:59 ian Exp $

# aliase.t
#
# Ensure the damn aliases damn-well work ;)

use strict;
use Test::More	tests => 33;
use Test::Exception;

# load Acme::Damn and the aliases (as defined in v0.02)
my	@aliases;
BEGIN { @aliases = qw( abjure anathematize condemn curse damn excommunicate
                       expel proscribe recant renounce unbless ); }

# load Acme::Damn
use Acme::Damn @aliases;

foreach my $alias ( @aliases ) {
	no strict 'refs';

	# create a reference, and strify it
	my	$ref	= [];
	my	$string	= "$ref";

	# bless the reference and the "unbless" it
		bless $ref;
		lives_ok  { $alias->( $ref ) } "$alias executes successfully";

	# make sure the stringification is correct
		ok( $ref eq $string , "$alias executes correctly" );
	
  # make sure the error message correctly reports the alias
		throws_ok { $alias->( $ref ) }
              "/can only $alias/" ,
		          "$alias exception thrown successfully";
}
