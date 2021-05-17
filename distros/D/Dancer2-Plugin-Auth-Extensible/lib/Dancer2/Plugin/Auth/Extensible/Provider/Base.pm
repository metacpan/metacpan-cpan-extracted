package    # hide from PAUSE
  Dancer2::Plugin::Auth::Extensible::Provider::Base;

use strict;
use warnings;
use Carp;

our $VERSION = '0.710';

croak "Your Dancer2::Plugin::Auth::Extensible provider needs to be upgraded.\nPlease upgrade to a provider that requires Dancer2::Plugin::Auth::Extensible v0.6 or greater.\n";

1;
