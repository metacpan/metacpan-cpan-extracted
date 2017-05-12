# $Id: 2holy.t,v 1.2 2003/06/16 02:09:01 ian Exp $

# holy.t
#
# Ensure holy "does the right thing"

use strict;
use Test::More tests => 17;
use Test::Exception;

# load Acme::Holy
use Acme::Holy;


#
# make sure holy returns the package name when given a blessed reference
#

# define blessed references for testing
my	$number	= 1;			$number	= bless \$number;
my	$string	= '2';			$string	= bless \$string;
my	@array	= ();		my	$array	= bless \@array;
my	%hash	= ();		my	$hash	= bless \%hash;
my	$code	= sub {};		$code	= bless $code;
my	$glob	= \*STDOUT;		$glob	= bless $glob;

ok( holy $number eq __PACKAGE__ , "holy() ok with numerical object" );
ok( holy $string eq __PACKAGE__ , "holy() ok with string object"    );
ok( holy $array  eq __PACKAGE__ , "holy() ok with array object"     );
ok( holy $hash   eq __PACKAGE__ , "holy() ok with hash object"      );
ok( holy $code   eq __PACKAGE__ , "holy() ok with code object"      );
ok( holy $glob   eq __PACKAGE__ , "holy() ok with glob object"      );

#
# make sure holy returns undef for all unblessed references
#

	$number	= \1;
	$string	= \'2';
	$array	= [];
	$hash	= {};
	$code	= sub {};
	$glob	= \*STDIN;

ok( ! defined holy $number , "holy() not defined with numerical reference" );
ok( ! defined holy $string , "holy() not defined with string reference"    );
ok( ! defined holy $array  , "holy() not defined with array reference"     );
ok( ! defined holy $hash   , "holy() not defined with hash reference"      );
ok( ! defined holy $code   , "holy() not defined with code reference"      );
ok( ! defined holy $glob   , "holy() not defined with glob reference"      );

#
# make sure holy returns undef for all non-references
#

	$number	= 1;
	$string	= '2';
	@array	= ();
	%hash	= ();

ok( ! defined holy undef   , "holy() not defined with undefined argument" );
ok( ! defined holy $number , "holy() not defined with numerical argument" );
ok( ! defined holy $string , "holy() not defined with string argument"    );
ok( ! defined holy @array  , "holy() not defined with array argument"     );
ok( ! defined holy %hash   , "holy() not defined with hash argument"      );
