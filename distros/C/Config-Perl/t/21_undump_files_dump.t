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

use Test::More;
use Test::Fatal 'exception';
use File::Temp 'tempfile';

BEGIN {
	use_ok('Data::Undump::PPI','Undump','Dump');
}

## no critic (RequireCarping)

my $string = <<'END_EXAMPLE';
#!perl
$VAR1 = [ "foo", "bar" ];
$VAR2 = 334;
$VAR3 = { quz => "baz" };
1;
END_EXAMPLE
my $expected = [ ['foo','bar'], 334, {quz=>'baz'} ];
my ($tfh,$tfn) = tempfile(UNLINK=>1);
print $tfh $string;
close $tfh;

is_deeply [Undump($string)], $expected, 'Undump string';

is_deeply [Undump(file=>$tfn)], $expected, 'Undump filename';

open my $ifh, '<', $tfn or die $!;
is_deeply [Undump(fh=>$ifh)], $expected, 'Undump filehandle';
close $ifh;

my $gotstr = "#!perl\n".Dump($expected)."\n1;\n";
ok cmp_no_ws($gotstr, $string), 'Dump string'
	or diag explain $gotstr, $string;

my ($tfh2,$tfn2) = tempfile(UNLINK=>1);
close $tfh2;
Dump($expected,file=>$tfn2);
open my $ifh2, '<', $tfn2 or die $!;
my $gotfile = do { local $/=undef; <$ifh2> };
close $ifh2;
ok cmp_no_ws($gotfile, $string), 'Dump filename'
	or diag explain $gotfile, $string;

my ($tfh3,$tfn3) = tempfile(UNLINK=>1);
Dump($expected,fh=>$tfh3);
close $tfh3;
open $tfh3, '<', $tfn3 or die $!;
my $gotfh = do { local $/=undef; <$tfh3> };
close $tfh3;
$gotfh = "#!perl\n${gotfh}\n1;\n";
ok cmp_no_ws($gotfh, $string), 'Dump filehandle'
	or diag explain $gotfh, $string;


done_testing;

sub cmp_no_ws {
	my ($x,$y) = @_;
	$x=~s/\s+/ /g;
	$y=~s/\s+/ /g;
	return $x eq $y;
}

