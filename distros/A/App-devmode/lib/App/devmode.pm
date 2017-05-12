package App::devmode;

# Created on: 2013-07-21 07:09:58
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.0.8');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

1;

__END__

=head1 NAME

App::devmode - Simple wrapper for screen that permits running of multiple screen configs for different tasks.

=head1 VERSION

This documentation refers to App::devmode version 0.0.8

=head1 SYNOPSIS

   use App::devmode;

   say $App::devmode::VERSION;

=head1 DESCRIPTION

See L<devmode> for details.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
