package ComplexWizardTestApp;

use strict;
use warnings;

use Catalyst qw/
    Session
    Session::Store::Dummy
    Session::State::Cookie
/;

use CatalystX::Wizarded;

__PACKAGE__->setup;

1;

__END__
