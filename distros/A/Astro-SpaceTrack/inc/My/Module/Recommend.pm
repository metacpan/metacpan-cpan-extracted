package My::Module::Recommend;

use strict;
use warnings;

use Carp;
use Config;

use My::Module::Recommend::Any qw{ __any };

my ( $is_5_010, $is_5_012 );

if ( $] ge '5.012' ) {
    $is_5_012 = $is_5_010 = 1;
} elsif ( $] ge '5.010' ) {
    $is_5_010 = 1;
};

my %misbehaving_os = map { $_ => 1 } qw{ MSWin32 cygwin };

my @optionals = (
    __any( 'Config::Identity'		=> <<'EOD' ),
      This module is used to parse the user's identity file, which
      provides default attribute values, and which can be encrypted with
      gpg2. If you do not intend to make use of the identity file,
      Config::Identity is not needed.
EOD
    __any( 'Browser::Open'		=> <<'EOD' ),
      This module is being phased in as the only supported way to
      display web-based help. If you intend to leave the 'webcmd'
      attribute false, this module is not needed.
EOD
    __any( 'Time::HiRes'		=> <<'EOD' ),
      This module is used for more precise throttling of Space Track
      requests. The code will work without it, but the less precise
      timing may result in retrieval failures.
EOD
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
standard out explaining the benefits to be gained from installing the
module, and any possible problems with installing it.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2024 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
