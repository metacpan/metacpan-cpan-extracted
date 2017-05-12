#08-validate_undefined.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();
my $undefined = undef;

is($Validator->validate(undef()), 0, "Handles undef correctly");
is($Validator->validate($undefined), 0, "Handles \$undefined correctly");
