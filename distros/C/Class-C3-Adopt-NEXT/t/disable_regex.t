use strict;
use warnings;
use Test::More tests => 2;

use Class::C3::Adopt::NEXT;

use lib 't/lib';

use C3NT;

no Class::C3::Adopt::NEXT qr/^C3NT::/;

my $obj = C3NT::Quux->new;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

is($obj->basic, 42);

is(scalar @warnings, 0, 'no warnings after disabling NEXT adoption');
