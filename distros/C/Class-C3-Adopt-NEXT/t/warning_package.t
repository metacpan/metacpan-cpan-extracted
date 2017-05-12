use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';

use Class::C3::Adopt::NEXT;

our @warnings;

BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ } }

use C3NT;

my $child = C3NT::Child->new;
@warnings = ();
$child->basic;
like($warnings[0], qr/C3NT::Quux uses NEXT/, 'warning for the class NEXT is used by');
like($warnings[1], qr/C3NT::Bar uses NEXT/,  'warning for the class NEXT is used by');
like($warnings[2], qr/C3NT::Baz uses NEXT/,  'warning for the class NEXT is used by');
