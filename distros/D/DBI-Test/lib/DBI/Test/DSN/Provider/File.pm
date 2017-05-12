package DBI::Test::DSN::Provider::File;

use strict;
use warnings;

use parent qw(DBI::Test::DSN::Provider::Base);

1;

=head1 NAME

DBI::Test::DSN::Provider::File - provide DSN in shared directory

=head1 DESCRIPTION

This DSN provider delivers a file name in a shared directory
for connection attributes.

=head1 AUTHOR

This module is a team-effort. The current team members are

  H.Merijn Brand   (Tux)
  Jens Rehsack     (Sno)
  Peter Rabbitson  (ribasushi)

=head1 COPYRIGHT AND LICENSE

Copyright (C)2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut
