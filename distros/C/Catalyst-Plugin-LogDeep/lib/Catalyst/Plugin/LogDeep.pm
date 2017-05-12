package Catalyst::Plugin::LogDeep;

# Created on: 2009-05-20 04:09:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use List::Util qw/ first /;
use Log::Deep;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use Class::C3::Adopt::NEXT -no_warn;

our $VERSION = version->new('0.0.4');

my $first = 1;
sub setup {
	my $package = shift;
	my $pkgname = ref $package || $package;

	if ($first) {
		$first = 0;

		do {
			no strict 'refs';  ## no critic
			@{"${pkgname}::ISA"} = grep { $_ ne __PACKAGE__ } @{"${pkgname}::ISA"};
		};

		my $cfg = $package->config->{'Plugin::LogDeep'} || {};

		$package->log( Log::Deep->new( %{ $cfg } ) );
		$package->log->enable('debug');
		$package->log->debug("How do I set the level?");
	}

	$package->NEXT::setup(@_);
};

1;

__END__

=head1 NAME

Catalyst::Plugin::LogDeep - Sets up L<Log::Deep> for Catalyst logging

=head1 VERSION

This documentation refers to Catalyst::Plugin::LogDeep version 0.0.4.

=head1 SYNOPSIS

 use Catalyst qw/ ... LogDeep/;

 __PACKAGE__->config(
     'Plugin::LogDeep' => {
         -name  => __PACKAGE__,
         -level => [ qw/debug warn error fatal/ ],
    },
 );

 $c->log->debug( { var => $variable }, 'This is the value of variable );
 $c->log->error( 'You did not do something' );

=head1 DESCRIPTION

Allows Catalyst to use the L<Log::Deep> library for logging operations.

The values set in the Plugin::LogDeep configuration item are passed directly
on to the L<Log::Deep> new method so look there for all the options for
configuration.

Note: You currently need to tell add a call to $c->log->session in [every]
begin method if you want a per session log session id. Hopefully this wont
be required in future versions.

=head1 SUBROUTINES/METHODS

=head3 C<setup ()>

Description: Sets up the catalyst application to use L<Log::Deep> as it's log
object.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

This module has only two dependencies C<Log::Deep> and L<Catalyst>

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close Hornsby Heights, NSW, Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
