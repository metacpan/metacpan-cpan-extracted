package App::filewatch;

# Created on: 2015-03-08 07:23:09
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.004');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

1;

__END__

=head1 NAME

App::filewatch - Watch files and directories for changes

=head1 VERSION

This documentation refers to App::filewatch version 0.004

=head1 SYNOPSIS

   file-watch [option] [file(s)]

 OPTIONS:
  -d --dir      Check directories
     --no-dir   Don't check directories
  -t --type[=]str
                Specify the type of file events to listen for, more than
                one event can be specified.
                 - IN_ACCESS
                 - IN_MODIFY
                 - IN_ATTRIB
                 - IN_CLOSE_WRITE
                 - IN_CLOSE_NOWRITE
                 - IN_OPEN
                 - IN_ALL_EVENTS
                 - IN_MOVED_FROM
                 - IN_MOVED_TO
                 - IN_CREATE
                 - IN_DELETE
                 - IN_DELETE_SELF
                 - IN_MOVE_SELF
                 - ALL - special pseudo event setting all events on so you can
                         see which ones are actually fired
  -r --report   When killed, a report will be generated of all files modified

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for file-watch

=head1 DESCRIPTION

C<file-watch> uses iNotify to track when files change. The types of changes
can be found in L<Linux::Inotify2>.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014-2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
