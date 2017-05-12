#!perl
use strict;
use Test::More (tests => 12);

=head1 test Abstract

tests reuse of import in a package, verifying that existing
print-styles are replaced by new ones, by checking that newly
constructed objects use the new settings.

=cut

use vars qw ($AR $HR @ARGold @HRGold);
require 't/Testdata.pm';
# share imported pkgs via myvars to other pkgs in file
my ($ar,$hr) = ($AR, $HR);
my @argold = @ARGold;
my @hrgold = @HRGold;

my ($ddez, $ez2);

use Data::Dumper::EasyOO;

$ddez = Data::Dumper::EasyOO->new();
is ($ddez->($ar), $argold[0][2], "main default on arrayref");
is ($ddez->($hr), $hrgold[0][2], "main default on hashref");

Data::Dumper::EasyOO->import(indent=>1);
$ez2 = Data::Dumper::EasyOO->new;

is ($ez2->($ar), $argold[0][1], "reimport changes defaults of new obj");
is ($ez2->($hr), $hrgold[0][1], "reimport changes defaults of new obj");

is ($ddez->($ar), $argold[0][2], "leaves orig obj alone");
is ($ddez->($hr), $hrgold[0][2], "leaves orig obj alone");

#is (Data::Dumper::EasyOO->import(indent=>1), 1, "import via alias");

package Foo;
use Data::Dumper::EasyOO;
*is = \&Test::More::is;

$ddez = Data::Dumper::EasyOO->new();
is ($ddez->($ar), $argold[0][2], "Foo default on arrayref");
is ($ddez->($hr), $hrgold[0][2], "Foo default on hashref");

Data::Dumper::EasyOO->import(indent=>1);
$ez2 = Data::Dumper::EasyOO->new;

is ($ez2->($ar), $argold[0][1], "reimport changes defaults of new obj");
is ($ez2->($hr), $hrgold[0][1], "reimport changes defaults of new obj");

is ($ddez->($ar), $argold[0][2], "leaves orig obj alone");
is ($ddez->($hr), $hrgold[0][2], "leaves orig obj alone");

__END__

