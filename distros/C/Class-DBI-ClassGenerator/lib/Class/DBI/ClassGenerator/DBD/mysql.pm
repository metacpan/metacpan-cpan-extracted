# $Id: mysql.pm,v 1.3 2008-08-28 17:07:11 cantrelld Exp $

package Class::DBI::ClassGenerator::DBD::mysql;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.0';

=head1 NAME

Class::DBI::ClassGenerator::DBD::mysql - MySQL-specific helper module
for Class::DBI::ClassGenerator.

You should never have to use this module directly.  It is only of
interest if hacking on the main module, or  for those wishing to add
support for another type of database.

See Class::DBI::ClassGenerator::Extending for details.

=cut

sub _get_tables {
    my(undef, $dbh) = @_;

    return map { @{$_} } @{$dbh->selectall_arrayref("SHOW TABLES")};
}

sub _get_columns {
    my(undef, $dbh, $table) = @_;

    my $data = $dbh->selectall_hashref("DESCRIBE $table", 'Field');
    return map {
        $_ => {
            type    => $data->{$_}->{Type},
            null    => ($data->{$_}->{Null} eq 'YES'),
            pk      => !!$data->{$_}->{Key},
            default => $data->{$_}->{Default}
        }
    } keys %{$data}
}

=head1 BUGS and WARNINGS

This should be considered to be pre-production code.  It's probably chock
full of exciting bugs.

=head1 AUTHOR, COPYRIGHT and LICENCE

Written by David Cantrell E<lt>david@cantrell.org.ukE<gt>

Copyright 2008 Outcome Technologies Ltd

This software is free-as-in-speech software, and may be used, distributed,
and modified under the terms of either the GNU General Public Licence
version 2 or the Artistic Licence. It's up to you which one you use. The
full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=cut

1;
