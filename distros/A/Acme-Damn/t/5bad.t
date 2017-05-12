#!/usr/bin/perl -w
# $Id: 5bad.t,v 1.2 2006-02-05 00:06:42 ian Exp $

# bad.t
#
# Ensure Acme::Damn dies when an invalid alias name is given for import.

use strict;
use Test::More	tests => 3;
use Test::Exception;

# load Acme::Damn
use Acme::Damn;

# make sure Acme::Damn::import() dies if the unknown symbol has "bad"
# characters in it (i.e. non-word characters, such as ':')
foreach my $name ( qw( foo::bar foo-bar foo.bar ) ) {
  throws_ok { Acme::Damn->import( $name ) }
            "/Bad choice of symbol/" ,
            "$name exception thrown successfully";
}
