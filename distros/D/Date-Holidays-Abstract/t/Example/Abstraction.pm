package Example::Abstraction;

use strict;
use warnings;

use lib ('lib');

use Date::Holidays::Abstract;
use base qw(Date::Holidays::Abstract);

sub holidays {}

sub is_holiday {}

1;
