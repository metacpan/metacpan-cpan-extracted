#!perl
# test emulation of DD methods that should resolve to Set

use strict;
use Test::More (tests => 8);
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
use vars qw(@arr);
require 't/Testdata.pm';

use_ok qw( Data::Dumper::EasyOO );

my $ddez = Data::Dumper::EasyOO->new(indent=>1);
isa_ok ($ddez, 'Data::Dumper::EasyOO', "new() retval");

is ($ddez->($AR), $ARGold[0][1], "AR, with indent=1, terse defaults");
is ($ddez->($HR), $HRGold[0][1], "HR, with indent=1, terse defaults");

$ddez->Terse(1);
is ($ddez->($AR), $ARGold[1][1], "AR, with indent=1, terse=1");
is ($ddez->($HR), $HRGold[1][1], "HR, with indent=1, terse=1");

$ddez->Indent(2);
is ($ddez->($AR), $ARGold[1][2], "AR, with indent=2, terse=1");
is ($ddez->($HR), $HRGold[1][2], "HR, with indent=2, terse=1");


(@arr) = $ddez->Indent();

print "@arr\n";
__END__

