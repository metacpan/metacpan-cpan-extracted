package Abbrev;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(string_key integer_key float_key object_key
		    string_list integer_list float_list object_list);

# alter types using abbreviations
%AUTODB=
  (collection=>Abbrev,
   keys=>qq(string_key str, integer_key int, float_key flo, object_key obj,
            string_list list(str), integer_list list(int), float_list list(flo), 
            object_list list(obj)));
Class::AutoClass::declare;

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=eval {new Class::AutoDB(database=>testdb,alter=>1)};
is($@,'','alter with abbreviated type names');

done_testing();
