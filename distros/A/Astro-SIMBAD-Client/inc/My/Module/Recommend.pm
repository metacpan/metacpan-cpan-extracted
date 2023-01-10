package My::Module::Recommend;

use strict;
use warnings;

use Carp;
use My::Module::Recommend::Any qw{ __any };
use My::Module::Recommend::None qw{ __none };

my @optionals = (
    __any( 'LWP::Protocol::https' => <<'EOD' ),
      This module is required if you want to use the https: URL scheme
      to access SIMBAD. If you intend to use only the default http:
      scheme this module is not needed.
EOD
    __any( 'SOAP::Lite'	=> <<'EOD' ),
      This module is required for the query() method. If you do not
      intend to use this method, SOAP::Lite is not needed.
EOD
    __any( 'XML::DoubleEncodedEntities' => <<'EOD' ),
      This module is not normally required. But at one point the SIMBAD
      service was double-encoding XML entities, and anything that has
      gone wrong once can go wrong again. If you find you need this
      module you cam install it and it will be used.
EOD
    __any( qw{ XML::Parser XML::Parser::Lite }	=> <<'EOD' ),
      One of these module is required to process the results of
      VO-format queries. If you do not intend to make VO-format queries,
      they are not needed.
EOD
    __any( 'Time::HiRes'	=> <<'EOD' ),
      This module can be used for more accurate control of query delay.
EOD
    __none( YAML	=> '' ),
);

my %core = map { $_ => 1 } qw{ Time::HiRes };

sub optionals {
    # As of Test::Builder 1.302190 (March 2 2022) Time::HiRes is needed
    # by Test::Builder, which is used by Test::More. It's a core module,
    # so it OUGHT to be available, though there are known downstream
    # packagers who strip core modules. Sigh. This is the reason I'm
    # stripping it here rather than removing it completely.
    return ( grep { ! $core{$_} } map { $_->modules() } @optionals );
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

__END__

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
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SIMBAD-Client>,
L<https://github.com/trwyant/perl-Astro-SIMBAD-Client/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
