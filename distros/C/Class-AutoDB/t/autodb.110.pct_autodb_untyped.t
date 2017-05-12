# Regression test: %AUTODB with keys that are implicitly typed

package PctAUTODB_Keys_String_SomeTyped;
use Test::More;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',keys=>'name, sex, id integer');  
eval {Class::AutoClass::declare;};
ok(!$@,'string');

package PctAUTODB_Keys_Hash_SomeTyped;
use Test::More;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',keys=>{name=>'', sex=>'', id=>'integer'});  
eval {Class::AutoClass::declare;};
ok(!$@,'hash');

package PctAUTODB_Keys_Array;
use Test::More;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person_Strings',keys=>[qw(name sex id)]);  
eval {Class::AutoClass::declare;};
ok(!$@,'array');

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

done_testing();
