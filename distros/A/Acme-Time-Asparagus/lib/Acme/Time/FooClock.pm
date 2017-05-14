package Acme::Time::FooClock;
use strict;

BEGIN {
}

# Documentation {{{

=head1 NAME

Acme::Time::FooClock - Base class for picture clocks

=head1 SYNOPSIS

Used for making arbitrary picture-clock classes.

 use Acme::Time::FooClock;
 $times = [
        'Tomato',      'Eggplant',       'Carrot',     'Garlic',
        'Green Onion', 'Pumpkin',        'Asparagus',  'Onion',
        'Corn',        'Brussels Sprout', 'Red Pepper', 'Cabbage',
    ];

 sub footime() {
     return Acme::Time::FooClock::time(shift);
 }

=head1 DESCRIPTION

"And now it's time for silly songs with Larry."

Figures out time on the vegetable clock. See
http://DrBacchus.com/images/clock.jpg

=head1 BUGS/ToDo

I suppose one could consider the very existence of this module to be a
bug. Also, I have never been quite sure if that thing was a brussel
sprout or a cauliflower.

The input checking could probably be improved.

Make it easier to extend for use with other varieties of clocks. I am
considering having a more generic Acme::Time::Food, of which this would
be a subclass. Subclasses would just pass in a listref of foods. This
would make the module more useful to the sushi crowd, for example.

Some way to convert back to "real" time from vegetable notation.

=head1 SUPPORT

You're kidding, right? Stop being so silly!

=head1 AUTHOR

	Rich 'DrBacchus' Bowen
	CPAN ID: RBOW
	rbowen@rcbowen.com
    http://www.DrBacchus.com/

Kudos to Kate L Pugh for submitting a patch, and demonstrating that
there are other people in the world as silly as I am.

=head1 COPYRIGHT

Copyright (c) 2010 Rich Bowen. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 veggietime

    print veggietime('5:17'); 
    print veggietime; # defaults to current time 

Returns the veggie time equivalent of a 12-hour time expressed in the
format hh:mm. Will round to the nearest vegetable.

=cut

# }}}

# sub time {{{

sub time {
    my $time = shift;
    my $class =caller();

    my $times;
    {
        no strict 'refs';
        $times = ${ $class . '::times' };
    }

    my ($h, $m);

    if ($time) {
        ($h, $m) = split /:/, $time;
    } else {
        my @t = localtime;
        $h=$t[2];
        $m=$t[1];
    }

    # o/~ We are the pirates who don't do anything o/~
    my $v = ( int( $m / 5 + 0.5 ) );
    if ( $v == 12 ) {
        $v = 0;
        $h += 1;
    }

    $h-=12 if $h>12;

    if ($v == 0) {
        return $times->[$h - 1];
    } elsif ($v > 6) { # Won't you join me in my irritating little song?
        $h++;
        $h=1 if $h==13;
        return $times->[$v - 1] . ' before ' . $times->[$h - 1];
    } else { # It would be an honor!
        return $times->[$v - 1] . ' past ' . $times->[$h - 1];
    }
} # }}}

"Look. It's a cebu!";

