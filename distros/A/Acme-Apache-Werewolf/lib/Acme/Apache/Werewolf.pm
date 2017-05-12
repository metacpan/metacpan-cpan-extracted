package Acme::Apache::Werewolf;
use strict;
use Astro::MoonPhase;
use Apache::Constants qw(:common);

use vars qw($VERSION);
$VERSION = '1.05';

sub handler {
    my $r = shift;
    my $moonlength = $r->dir_config('MoonLength');
    warn "Moon length is $moonlength";

    my ( $MoonPhase,
          $MoonIllum,
          $MoonAge,
          $MoonDist,
          $MoonAng,
          $SunDist,
          $SunAng ) = phase(time);

    # If you hear him howling around your kitchen door
    # Better not let him in
    return FORBIDDEN unless abs(14 - $MoonAge) > ($moonlength/2);
    return OK;
}

=head1 NAME

Acme::Apache::Werewolf

=head1 SYNOPSIS

    <Directory /fullmoon>
        PerlAccessHandler Acme::Apache::Werewolf
        PerlSetVar MoonLength 4
    </Directory>

=head1 DESCRIPTION

This mod_perl handler performs the important function of keeping
werewolves out of a directory during the full moon.

    Better stay away from him
    He'll rip your lungs out, Jim

=head1 USAGE

In your configuration file, put the following configuration

    <Directory /fullmoon>
        PerlAccessHandler Acme::Apache::Werewolf
        PerlSetVar MoonLength 4
    </directory>

The MoonLength variable indicates how long a period you want to consider
to be the full moon. In the above configuration, the full moon is 4
days, which would be from day 12 through day 16 of the lunar cycle. It
is wise to err on the side of caution and make this too large, rather
than make it too small, and risk the wrath of werewolves.

=head1 AUTHOR

    Rich Bowen
	rbowen@rcbowen.com
	http://rcbowen.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Garlic sold separately. No warranty of werewolf protection implied. May
be prohibited in some states. Lon Chaney and Warren Zevon references
provided free of charge.

=head1 CAVEATS

I've not tested this with Apache 2.x. I don't have much idea whether or
not it will work there. Reports welcome.

=head1 SEE ALSO

Astro::MoonPhase

I'd like to meet his tailor.

=cut

'His hair was perfect'; 

