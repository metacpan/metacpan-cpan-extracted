#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 5 }
use CORBA::IDLtree;

ok(push @CORBA::IDLtree::include_path, "t");
   # For future tests that use include files.

my $symroot;
$CORBA::IDLtree::support_module_reopening = 1;
ok($symroot = CORBA::IDLtree::Parse_File "t/orbit-everything.idl");
ok(CORBA::IDLtree::Dump_Symbols $symroot);
ok($symroot = CORBA::IDLtree::Parse_File "t/reopened_module.idl");
ok(CORBA::IDLtree::Dump_Symbols $symroot);

exit;
__END__

