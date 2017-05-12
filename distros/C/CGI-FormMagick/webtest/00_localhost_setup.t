#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Inline 'WebChat';

ok(localhost(), "Localhost is set up for FM web testing");

__END__

__WebChat__

sub localhost {
    GET http://localhost/formmagick/
    EXPECT OK && /examples/
}
