package TestChained;
use strict;
use warnings;
use Mock::UserObject;

use Catalyst;

my $user = bless {}, 'Mock::UserObject';

sub user { $user }


__PACKAGE__->setup;

1;
