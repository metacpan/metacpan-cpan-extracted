#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module Config::Perl
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Config_Perl_Testlib;

use Test::More tests=>4+4*2+1;

BEGIN {
	use_ok 'Config::Perl' or BAIL_OUT("failed to use Config::Perl");
	use_ok 'Data::Undump::PPI' or BAIL_OUT("failed to use Data::Undump::PPI");
}
is $Config::Perl::VERSION, '0.06', 'version matches tests';
is $Data::Undump::PPI::VERSION, '0.06', 'version matches tests';

test_ppconf <<'END1'
$foo = 1;
$bar = "blah";
$quz = { a=>1, b=>2 };
END1
, {
	'$foo'=>1,
	'$bar'=>"blah",
	'$quz'=>{ a=>1, b=>2 },
	}, 'simple config file, multiple vars';

test_ppconf <<'END2'
{
	foo => 1,
	'bar' => "blah",
	quz => { a=>1, b=>2 },
}
END2
, { _=>[ {
	foo => 1,
	'bar' => "blah",
	quz => { a=>1, b=>2 },
	} ] }, 'simple config file, single structure';

test_ppconf <<'END3'
$VAR1 = 'foo';
$VAR2 = 123;
$VAR3 = {
          'z' => 3,
          'x' => 'y'
        };
END3
, {
	'$VAR1' => 'foo',
	'$VAR2' => 123,
	'$VAR3' => { x => 'y', z => 3 },
	}, 'parsing Data::Dumper output';

test_ppconf <<'END4'
("foo", 123, { x => "y", z => 3 })
END4
, { _=>[
	"foo", 123, { x => 'y', z => 3 }
	] }, 'parsing Data::Dump output';

is_deeply
	[ Undump(q{ $VAR1 = { foo => "bar" }; $VAR2 = 345; $VAR3 = [qw/a b c/] }) ],
	[ { foo => "bar" }, 345, ['a','b','c'] ], 'basic Undump test';

