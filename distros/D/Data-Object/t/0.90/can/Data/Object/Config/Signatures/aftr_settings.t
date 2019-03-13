use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

aftr_settings

=usage

  my $aftr_settings = aftr_settings();

=description

The aftr_settings function returns the after-keyword configuration.

=signature

aftr_settings(Str $arg1, Object $arg2) : (Str, HashRef)

=type

function

=cut

# TESTING

use_ok 'Data::Object::Config::Signatures';

my $data = 'Data::Object::Config::Signatures';

can_ok $data, 'aftr_settings';

ok 1 and done_testing;
