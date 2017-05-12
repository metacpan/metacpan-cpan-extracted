use strict;
use warnings;
use Test::More tests => 2;

use Class::C3::Adopt::NEXT;

use lib 't/lib';

use C3NT_nowarn;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

my $quux_obj = C3NT::Quux->new;
is($quux_obj->basic, 42, 'Basic inherited method returns correct value');
is(scalar @warnings, 0, 'no warnings when disabled');
