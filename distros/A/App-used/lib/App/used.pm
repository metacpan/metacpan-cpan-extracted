package App::used;

# Created on: 2015-03-05 19:53:14
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

our $VERSION     = version->new('0.0.7');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

1;

__END__

=head1 NAME

App::used - Find modules used or required in perl files or directories of perl files

=head1 VERSION

This documentation refers to App::used version 0.0.7


=head1 SYNOPSIS

   used [option]

 OPTIONS:
  -n --name       Order by module name (Default order)
  -I --lib[=]dir  Add the directory to the list of local library paths. This
                  stops reporting of modules that are part of the project
                  being marked as not added to the Build.PL file. The default
                  list includes lib/ and t/lib/
  -u --used       Order by the number of times a module is used/required
  -U --update     Update the requires section of the Build.PL file
  -d --decending  Reverse the sort order

  -p --perl-version
                  Show files that require the highest version of Perl to be used
  -v --verbose    Show more detailed option
                    Specified once shows module verion numbers verses required
                    versions.
                    Specified twice also shows modules that are local to the
                    project and modules that are part of the default perl
                    version.
     --version    Prints the version information
     --help       Prints this help information
     --man        Prints the full documentation for used

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

Copyright (c) 2009-2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
