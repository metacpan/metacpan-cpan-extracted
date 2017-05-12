#!/usr/local/bin/perl

use strict;
use warnings;

use Acme::Locals qw(:all);

sub hi { # Using lexical variables.
    my $x = 10;
    my $y = 200;

    my $name = "George Constanza";

    sayx "x: %(x)d y: %(y)d name: %(name)s", locals();
}

sub moo { # Using global variables

    our $a = 13.54;
    our $b = "world";

    sayx "%(a)f: Hello %(b)s", globals();
}


hi();
moo();
