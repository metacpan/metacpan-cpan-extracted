#!perl
use strict;
use Test::More (tests => 5);

=head1 test Abstract

tests return vals of import into scalar and list contexts.

=cut


use vars qw ($AR $HR @ARGold @HRGold);
require 't/Testdata.pm';
# share imported pkgs via myvars to other pkgs in file
my ($ar,$hr) = ($AR, $HR);
my @argold = @ARGold;
my @hrgold = @HRGold;


#use_ok ( Data::Dumper::EasyOO => ());
use Data::Dumper::EasyOO ();
pass ("use w/o import");

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO');

is ($ddez->($AR), $ARGold[0][2], "new obj works on arrayref");
is ($ddez->($HR), $HRGold[0][2], "new obj works on hashref");

eval { ezdump ([1..4]) };

like ($@, qr/Undefined subroutine &main::ezdump called/,
      " &main::ezdump undefined, as expected");

__END__

