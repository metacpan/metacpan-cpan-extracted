package WizardTestApp;

use strict;
use warnings;

use Catalyst qw/
    Session
    Session::Store::Dummy
    Session::State::Cookie
/;

use CatalystX::Wizarded;

__PACKAGE__->config({ wizard => { autostash => 1, autoactivate => 1 }});

__PACKAGE__->setup;

1;

__END__
