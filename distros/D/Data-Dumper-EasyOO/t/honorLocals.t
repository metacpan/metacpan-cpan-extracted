
=head1 Commentary

theres almost nothing to test here.

The locals in question are DD::Indent and friends, which are
internalized into a DD object when its created, not checked later when
its printed.  IOW, theres no current localized value to honor, the
choice has already been made (by DD).

=cut


use Test::More (tests => 7);
use vars qw($AR  $HR  @ARGold  @HRGold  @Arrays  @ArraysGold  @LArraysGold);
require 't/Testdata.pm';


use_ok (Data::Dumper::EasyOO);

my $ez1 = Data::Dumper::EasyOO->new();
my $ez2 = Data::Dumper::EasyOO->new(indent=>0);

isa_ok ($ez1, 'Data::Dumper::EasyOO', "1st DDEz object");
isa_ok ($ez2, 'Data::Dumper::EasyOO', "2nd DDEz object");

is ($ez1->($HR), $HRGold[0][2], "HR, with default indent");
is ($ez2->($HR), $HRGold[0][0], "HR, ctor overridden indent");

$Data::Dumper::Indent = $Data::Dumper::Indent = 1; #2x

$ez1 = Data::Dumper::EasyOO->new();
$ez2 = Data::Dumper::EasyOO->new(indent=>0);

is ($ez1->($HR), $HRGold[0][1], "HR, ctor used localized indent");
is ($ez2->($HR), $HRGold[0][0], "HR, ctor overridden indent");
