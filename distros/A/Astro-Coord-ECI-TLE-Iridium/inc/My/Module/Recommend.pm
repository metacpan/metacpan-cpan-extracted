package My::Module::Recommend;

use strict;
use warnings;

use Carp;
use My::Module::Recommend::All qw{ __all };

my @optionals = (
    __all( 'DateTime', 'DateTime::TimeZone'	=> <<'EOD' ),
      If you set the 'zone' attribute of Astro::Coord::ECI::TLE::Iridium
      to a zone name, these modules will be used to determine if a flare
      occurred before or after midnight. If not available, $ENV{TZ} will
      be set to the zone name in the hope that the localtime() built-in
      will respond to this. If the 'zone' attribute is undef (the
      default) or a numeric offset from GMT, this module is not used.
EOD
);

sub optionals {
    return ( map { $_->modules() } @optionals );
}

sub recommend {
    my $need_some;
    foreach my $mod ( @optionals ) {
	defined( my $msg = $mod->recommend() )
	    or next;
	$need_some++
	    or warn <<'EOD';

The following optional modules were not available:
EOD
	warn "\n$msg";
    }
    $need_some
	and warn <<'EOD';

It is not necessary to install these now. If you decide to install them
later, this software will make use of them when it finds them.

EOD

    return;
}

1;

=head1 NAME

My::Module::Recommend - Recommend modules to install. 

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Recommend;
 My::Module::Recommend->recommend();

=head1 DETAILS

This package generates the recommendations for optional modules. It is
intended to be called by the build system. The build system's own
mechanism is not used because we find its output on the Draconian side.

=head1 METHODS

This class supports the following public methods:

=head2 optionals

 say for My::Module::Recommend->optionals();

This static method simply returns the names of the optional modules.

=head2 recommend

 My::Module::Recommend->recommend();

This static method examines the current Perl to see which optional
modules are installed. If any are not installed, a message is printed to
standard error explaining the benefits to be gained from installing the
module, and any possible problems with installing it.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-Coord-ECI-TLE-Iridium>,
L<https://github.com/trwyant/perl-Astro-Coord-ECI-TLE-Iridium/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

__END__

# ex: set textwidth=72 :
