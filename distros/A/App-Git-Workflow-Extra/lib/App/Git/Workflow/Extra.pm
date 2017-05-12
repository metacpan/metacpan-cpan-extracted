package App::Git::Workflow::Extra;

# Created on: 2015-04-12 10:03:52
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION = 0.3;

1;

__END__

=head1 NAME

App::Git::Workflow::Extra - A collection of extra Group::Git commands

=head1 VERSION

This documentation refers to App::Git::Workflow::Extra version 0.0.3

=head1 SYNOPSIS

   use App::Git::Workflow::Extra;

   # Does nothing

=head1 DESCRIPTION

This builds on L<App::Git::Workflow> to add more commands which may have less
broad appeal. It does this by depending on all the seperate extra commands
which get installed along with this module.

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

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
