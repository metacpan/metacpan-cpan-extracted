# $Id: 3aliases.t,v 1.2 2003/06/16 02:09:02 ian Exp $

# aliases.t
#
# Ensure the holy aliases work.

use strict;
use Test::More	tests => 12;
use Test::Exception;

# load Acme::Damn and the aliases
my	@aliases;
BEGIN {
	@aliases = qw( blessed consecrated divine hallowed sacred sacrosanct );
}

# load Acme::Holy
use Acme::Holy @aliases;

foreach my $alias ( @aliases ) {
	no strict 'refs';

	# create a reference, and strify it
	my	$ref	= [];
	my	$string	= "$ref";

	# bless the reference and the "unbless" it
		bless $ref;
		lives_ok { $alias->( $ref ) } "$alias executes successfully";
	
	# make sure the stringification is correct
		ok( $alias->( $ref ) eq __PACKAGE__ , "$alias executes correctly" );
}
