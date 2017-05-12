#!perl
# creates 1 EzDD, and alters it repeatedly, using both Set and AUTOLOAD
use strict;
use Test::More;
if ($] >= 5.006) { plan tests => 330 }
else		 { plan tests => 180 }

use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/Testdata.pm';

use_ok qw(Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good DDEz object");

pass "dump with default indent";
is ($ddez->($AR), $ARGold[0][2], "AR, with indent, terse defaults");
is ($ddez->($HR), $HRGold[0][2], "HR, with indent, terse defaults");

pass "test method chaining: ->Indent(\$i)->Terse(\$t)";
for my $t (0..1) {
    for my $i (0..3) {
	$ddez->Indent($i)->Terse($t);
	is ($ddez->($AR), $ARGold[$t][$i], "HR, with Indent($i)");
	is ($ddez->($HR), $HRGold[$t][$i], "HR, with Indent($i)");
    }
}

# methods: Values, Reset  cause failures in tests !

my @methods = qw( Indent Terse Seen Names Pad Varname Useqq 
		  Purity Freezer Toaster Deepcopy Bless );

push @methods, qw( Pair Maxdepth Useperl Sortkeys Deparse )
    if $] >= 5.006002;

pass "test that objects are returned from AUTOLOAD(), Set()";
for my $method (@methods) {
    isa_ok ($ddez->$method(), 'Data::Dumper::EasyOO', "\$ezdd->$method()\t");
}

pass "test that 2 method chains are ok";
for my $m1 (@methods) {
    for my $m2 (@methods) {
	isa_ok ( $ddez->$m1()->$m2(),
		 'Data::Dumper::EasyOO',
		 "\$ezdd -> $m1()\t-> $m2()\t" );
    }
}

__END__

for my $method (@methods) {
    print "$method returns: ", $ddez->$method(), "\n";
}

