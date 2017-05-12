#
# $Id$
#

package DBIx::IO::mysqlLib;

BEGIN
{
    use Exporter ();

    @ISA = qw(Exporter);

    @EXPORT = qw(
        $NORMAL_DATETIME_FORMAT
        $NORMAL_DATE_FORMAT
        $NORMAL_TIME_FORMAT
        $NORMAL_YEAR_FORMAT
    );

    %EXPORT_TAGS =
    (
        actions =>
        [qw(
        )],
    );

    Exporter::export_ok_tags qw(
        actions
    );
}

use strict;

# CONSTANTS

# CAUTION If this constant is changed, normalize_date and local_normal_sysdate must be changed accordingly
*DBIx::IO::mysqlLib::NORMAL_DATETIME_FORMAT = \'%Y%m%d%H%i%S';
*DBIx::IO::mysqlLib::NORMAL_DATE_FORMAT = \'%Y%m%d';
*DBIx::IO::mysqlLib::NORMAL_TIME_FORMAT = \'%H%i%S';
*DBIx::IO::mysqlLib::NORMAL_YEAR_FORMAT = \'%Y';

=head1 NAME

DBIx::IO::mysqlLib - General helper functions and constants to support the DBIx::IO MySQL driver

=head1 SYNOPSIS

 
 use DBIx::IO::mysqlLib;
 use DBIx::IO::mysqlLib ();                     # Don't import default symbols
 use DBIx::IO::mysqlLib qw(:tag symbol...)      # Import selected symbols


=head1 DESCRIPTION

MySQL specific constants and helper functions.

Table names by default are case-sensitive on Linux/UNIX OS's;
do yourself a favor and set lower_case_table_names=1 in /etc/my.cnf
and always use lower case names for tables.

=cut

1;

__END__

=head1 SEE ALSO

L<DBIx::IO::mysqlIO>, L<DBIx::IO::GenLib>, L<DBIx::IO>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

