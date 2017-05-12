#!/usr/bin/perl

package ContTestApp;

use strict;
use warnings;

use Catalyst qw/
    Session
    Session::Store::Dummy
    Session::State::Cookie

    Continuation
/;

__PACKAGE__->setup;

__PACKAGE__;

__END__

