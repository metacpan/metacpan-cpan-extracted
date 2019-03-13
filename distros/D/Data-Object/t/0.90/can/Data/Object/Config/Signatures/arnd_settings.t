use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

arnd_settings

=usage

  my $arnd_settings = arnd_settings();

=description

The arnd_settings function returns the around-keyword configuration.

=signature

arnd_settings(Str $arg1, Object $arg2) : (Str, HashRef)

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Signatures';

my $data = 'Data::Object::Config::Signatures';

can_ok $data, 'arnd_settings';

ok 1 and done_testing;
