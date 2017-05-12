#!/usr/bin/perl -w
# $Id: 2damn.t,v 1.1 2003-06-08 13:20:14 ian Exp $

# damn.t
#
# Ensure damn "does the right thing"

use strict;
use Test::More tests => 26;
use Test::Exception;

# load Acme::Damn
use Acme::Damn;

#
# make sure damn dies if not given a blessed reference
#

# define some argument types for damn
my	@array	= ();
my	%hash	= ();
my	$scalar	= 0;

dies_ok { eval "damn"   or die } "damn() dies with no arguments";
dies_ok { eval "damn()" or die } "damn() dies with no arguments";
dies_ok { damn 1               } "damn() dies with numerical argument";
dies_ok { damn '2'             } "damn() dies with string argument";
dies_ok { damn *STDOUT         } "damn() dies with glob argument";
dies_ok { damn \1              } "damn() dies with scalar reference argument";
dies_ok { damn []              } "damn() dies with array reference argument";
dies_ok { damn {}              } "damn() dies with hash reference argument";
dies_ok { damn sub {}          } "damn() dies with code reference argument";
dies_ok { damn @array          } "damn() dies with array argument";
dies_ok { damn %hash           } "damn() dies with hash argument";
dies_ok { damn $scalar         } "damn() dies with scalar argument";
dies_ok { damn undef           } "damn() dies with undefined argument";
dies_ok { damn \*STDOUT        } "damn() dies with glob reference argument";

#
# make sure damn lives when passed an object
#

# define blessed references for testing
my	$number	= 1;			$number	= bless \$number;
my	$string	= '2';			$string	= bless \$string;
	@array	= ();		my	$array	= bless \@array;
	%hash	= ();		my	$hash	= bless \%hash;
my	$code	= sub {};		$code	= bless $code;
my	$glob	= \*STDOUT;		$glob	= bless $glob;

lives_ok { damn $number } "damn() lives with numerical object argument";
lives_ok { damn $string } "damn() lives with string object argument"   ;
lives_ok { damn $array  } "damn() lives with array object argument"    ;
lives_ok { damn $hash   } "damn() lives with hash object argument"     ;
lives_ok { damn $code   } "damn() lives with code object argument"     ;
lives_ok { damn $glob   } "damn() lives with glob object argument"     ;

#
# make sure damn unblesses the objects
#

# define a routine for performing the comparison
my	$cmp	= sub {
		my	$ref	= shift;
		my	$string	= "$ref";
			damn bless $ref;

		# make sure the stringification is the same
		return $string eq "$ref";
	}; # $cmp()

	$number	= 1;
	$string	= '2';
	$code	= sub {};
	$glob	= \*STDOUT;

ok( $cmp->( \$number ) , "damned numerical references" );
ok( $cmp->( \$string ) , "damned string references"    );
ok( $cmp->( \@array  ) , "damned array references"     );
ok( $cmp->( \%hash   ) , "damned hash references"      );
ok( $cmp->(  $code   ) , "damned code references"      );
ok( $cmp->(  $glob   ) , "damned glob references"      );
