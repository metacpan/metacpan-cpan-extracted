package App::chkfacl;

# Created on: 2015-03-05 19:53:03
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION = 0.4;
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

1;

__END__

=head1 NAME

App::chkfacl - Uses the whole hierarchy of a file to check that it can be read by the specified user or group

=head1 VERSION

This documentation refers to chkfacl version 0.4.

=head1 SYNOPSIS

   chkfacl [option] ( dir | file )

 OPTIONS:
  -g --group=name Name of group to check
  -u --user=name  Name of user to check
  -r --recurse    Recurse into sub directories
  -w --write      Write facls to make user or group be able to access needed directories?
  -m --rule       One rule to rule them all?

  -v --verbose    Show more detailed option
     --VERSION    Prints the version information
     --help       Prints this help information
     --man        Prints the full documentation for chkfacl

=head1 DESCRIPTION

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
