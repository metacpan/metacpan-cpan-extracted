package Acme::Time::Asparagus;
use strict;

BEGIN {
    use Exporter();
    use vars qw (@ISA @EXPORT $times );
    use Acme::Time::FooClock;

    @ISA       = qw (Exporter Acme::Time::FooClock);
    @EXPORT = qw ( veggietime );

    # Got your own clock with different veggies?
    # See Acme::Time::FooClock for details about making arbitrary
    # picture clock modules.
    $times = [
        'Tomato',      'Eggplant',       'Carrot',     'Garlic',
        'Green Onion', 'Pumpkin',        'Asparagus',  'Onion',
        'Corn',        'Brussels Sprout', 'Red Pepper', 'Cabbage',
    ];
}

# Documentation {{{

=head1 NAME

Acme::Time::Asparagus - Time on the vegetable clock

=head1 SYNOPSIS

  use Acme::Time::Asparagus qw(veggietime);
  print veggietime('12:40');

  # In version 1.04, you could ask for a particular language, which
  # seemed like a good idea at the time, but was very restricting
  print veggietime('5:07', 'en_GB');
  # Note that this will generate a warning. So you probably don't want
  # to do this. But I didn't want to screw people up too badly.

=head1 DESCRIPTION

"And now it's time for silly songs with Larry."

Figures out time on the vegetable clock. See
http://www.DrBacchus.com/images/clock.jpg  See also the README for a URL
for a Sushi clock.

=head1 BUGS/ToDo

I suppose one could consider the very existence of this module to be a
bug. Also, I have never been quite sure if that thing was a brussels
sprout or a cauliflower.

The input checking could probably be improved.

Some way to convert back to "real" time from vegetable notation.

=head1 SUPPORT

You're kidding, right? Stop being so silly!

=head1 AUTHOR

	Rich 'DrBacchus' Bowen
	CPAN ID: RBOW
	rich@DrBacchus.com
    http://www.DrBacchus.com/

Kudos to Kate L Pugh for submitting a patch, and demonstrating that
there are other people in the world as silly as I am. That stuff has now
been moved out into Acme::Time::Aubergine.

See also C<Acme::Time::FooClock> for more information.

=head1 COPYRIGHT

Copyright (c) 2009 Rich Bowen. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# }}}

# sub veggietime {{{

=head1 veggietime

    print veggietime('5:17');
    print veggietime; # defaults to current time

Returns the veggie time equivalent of a 12-hour time expressed in the
format hh:mm. Will round to the nearest vegetable.

=cut

sub veggietime {
    
    # Warn folks that are trying to use the language argument
    if ($_[1]) {
        warn "\nWarning: Language argument is deprecated. You probably want to use Acme::Time::Aubergine\n";
        require Acme::Time::Aubergine;
        return Acme::Time::Aubergine::veggietime($_[0]);
    }
    return Acme::Time::FooClock::time(shift);
} # }}}

"Look. It's a cebu!";

