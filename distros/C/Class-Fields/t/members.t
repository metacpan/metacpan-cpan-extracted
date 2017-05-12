#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;


package Foo;

use public      qw(Red Hate Airport);
use private     qw(_What _No _Meep);
use protected   qw(Northwest _puke _42 23);


package main;

# Check we got all the fields.
::is_deeply( [sort keys %Foo::FIELDS],
             [sort qw(Red Hate Airport
                      _What _No _Meep
                      Northwest _puke _42 23)]
);

use Class::Fields;

# Check public fields
::is_deeply( [sort &show_fields('Foo', 'Public')],
             [sort qw(Red Hate Airport)]
);

# Check private fields
::is_deeply( [sort &show_fields('Foo', 'Private')],
             [sort qw(_What _No _Meep)] 
);

# Check protected fields
::is_deeply( [sort &show_fields('Foo', 'Protected')],
             [sort qw(Northwest _puke _42 23)]
);


# Test inheritance of protected fields.
package Bar;

use base qw(Foo);
use fields qw(Hey _ar);


package main;

::is_deeply( [sort keys %Bar::FIELDS],
             [sort qw(Hey _ar Red Hate Airport Northwest _puke _42 23)] 
);


# Test warnings about poorly named data members.
my $w;
BEGIN {
    $SIG{__WARN__} = sub {
        if ($_[0] =~ /^Use of leading underscores to name public data fields is considered unwise/ or
            $_[0] =~ /^Private data fields should be named with a leading underscore/) {
            $w++;
        }
        else {
            print STDERR $_[0];
        }
    };
}

package Ick;

use public qw(Yo roo _uh_oh ok_ay);
use protected qw(Find _no_problem);
use private qw(_roof _PANTS 42 oops);

::is( $w, 3 );
