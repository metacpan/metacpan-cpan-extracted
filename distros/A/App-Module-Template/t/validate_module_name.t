#!perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

use_ok( 'App::Module::Template', '_validate_module_name' );

ok(my $module_name = 'Valid::Module', 'set valid module name');

ok(_validate_module_name($module_name), 'valid module name');

ok($module_name = 'Valid::Module::With::Levels', 'set valid module name');

ok(_validate_module_name($module_name), 'valid module name with many levels');

ok($module_name = 'ALL::CAPS', 'set valid module name');

ok(_validate_module_name($module_name), 'valid module name with all caps');

ok($module_name = 'TopLevel', 'set top-level module name');

throws_ok{ _validate_module_name($module_name) } qr/'$module_name' is a top-level namespace/, 'top-level namespace';

ok($module_name = 'lower::case', 'set lower-case module name');

throws_ok{ _validate_module_name($module_name) } qr/'$module_name' is an all lower-case namespace/, 'lower-case namespace';

ok($module_name = 'all::lower::case', 'set multiple lower case namespaces');

throws_ok{ _validate_module_name($module_name) } qr/'$module_name' is an all lower-case namespace/, 'multiple lower-case namespaces';

ok($module_name = 'Invalid::lowercase', 'set module name with mixed lower-case');

throws_ok{ _validate_module_name($module_name) } qr/'$module_name' does not meet naming requirements/, 'Mixed namespaces with lower-case';

ok($module_name = 'Not:Enough', 'set module name without enough colons');

throws_ok{ _validate_module_name($module_name) } qr/'$module_name' does not meet naming requirements/, 'Module with one colon';
