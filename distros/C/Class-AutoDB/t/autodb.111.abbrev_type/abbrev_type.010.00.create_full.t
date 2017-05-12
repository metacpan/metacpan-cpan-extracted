package Abbrev;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(string_key integer_key float_key object_key
		    string_list integer_list float_list object_list);

# define types using full name
%AUTODB=
  (collection=>Abbrev,
   keys=>qq(string_key string, integer_key integer, float_key float, object_key object,
            string_list list(string), integer_list list(integer), float_list list(float), 
            object_list list(object)));
Class::AutoClass::declare;

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=eval {new Class::AutoDB(database=>testdb,create=>1)};
is($@,'','create with full type names');

done_testing();
