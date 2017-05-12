package Abbrev;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(string_key integer_key float_key object_key
		    string_list integer_list float_list object_list);

# use types using different abbreviations
%AUTODB=
  (collection=>Abbrev,
   keys=>qq(string_key stri, integer_key inte, float_key floa, object_key obje,
            string_list list(stri), integer_list list(inte), float_list list(floa), 
            object_list list(obje)));
Class::AutoClass::declare;

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=eval {new Class::AutoDB(database=>testdb)};
is($@,'','use with abbreviated type names');

done_testing();
