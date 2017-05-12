#!perl
use strict;
use Test::More (tests => 13);

=head1 test Abstract

tests reuse of $alias->import in a package, verifies that existing
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

use Data::Dumper::EasyOO (alias => 'EzDD');

$ddez = EzDD->new();
is ($ddez->($ar), $argold[0][2], "main default on arrayref");
is ($ddez->($hr), $hrgold[0][2], "main default on hashref");

# called for side effect only.
(undef) = ezdump([EzDD->import(indent=>1)]);
$ez2 = EzDD->new();

is ($ez2->($ar), $argold[0][1], "reimport changes defaults of new obj");
is ($ez2->($hr), $hrgold[0][1], "reimport changes defaults of new obj");

is ($ddez->($ar), $argold[0][2], "leaves orig obj alone");
is ($ddez->($hr), $hrgold[0][2], "leaves orig obj alone");


my $ez3 = Data::Dumper::EasyOO->new();
is ($ez3->($ar), $argold[0][1], "but changes defaults of unaliased name");


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

$ddez = Data::Dumper::EasyOO->new(indent=>1);
is ($ddez->($ar), $argold[0][1], "alias into Bar, with indent=1");
is ($ddez->($hr), $hrgold[0][1], "alias into Bar, with indent=1");


package Double;
use Data::Dumper::EasyOO (alias => 'Alias1', alias => 'Alias2');
*is = \&Test::More::is;

$ddez = Alias1->new(terse=>1);
is ($ddez->($ar), $argold[1][2], "2 aliases, use 1st, w terse=1");
is ($ddez->($hr), $hrgold[1][2], "2 aliases, use 1st, w terse=1");

$ddez  = Alias2->new();
is ($ddez->($ar), $argold[0][2], "2 aliases, use 2nd");
is ($ddez->($hr), $hrgold[0][2], "2 aliases, use 2nd");


eval {
    $ddez = Bar->new();
};
print $@;

# qr/Can\'t locate object method "new" via package "Foo"/,
#     "no alias leaks between 2 (declared) pkgs in same file");


package Late;
use Data::Dumper::EasyOO;
import Data::Dumper::EasyOO (alias => ImportedAlias);
*is = \&Test::More::is;

$ddez = ImportedAlias->new(indent=>1);
is ($ddez->($ar), $argold[0][1], "imported (late) alias");
is ($ddez->($hr), $hrgold[0][1], "imported (late) alias");
