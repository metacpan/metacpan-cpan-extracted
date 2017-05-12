#!/usr/bin/perl -w
# $Id: 4name.t,v 1.2 2003-06-10 18:08:34 ian Exp $

# name.t
#
# Ensure the damn reports the correct alias name in error messages.

use strict;
use Test::More	tests => 11;
use Test::Exception;

# load Acme::Damn and the aliases
my	@aliases;
BEGIN { @aliases = qw( abjure anathematize condemn curse damn excommunicate
                       expel proscribe recant renounce unbless ); }

# load Acme::Damn
use Acme::Damn @aliases;

foreach my $alias ( @aliases ) {
	no strict 'refs';

	# attempt to unbless a normal reference so that we can test the error
	# messages
		throws_ok { $alias->( [] ) } "/can only $alias/" ,
		                             "$alias exception thrown successfully";
}
