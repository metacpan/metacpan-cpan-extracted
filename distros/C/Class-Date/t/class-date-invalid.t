use strict;
use warnings;

use Test::More tests => 2;

use Test::Warnings;

use Class::Date::Invalid;

my $self = [ 1, 123 ];
bless $self, 'Class::Date::Invalid';

# that used to warn - GH#9
like $self->errmsg, qr'Invalid';




