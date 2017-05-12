#
# $Id: OracleLib.pm,v 1.1 2002/05/24 10:36:30 rsandberg Exp $
#

package DBIx::IO::OracleLib;

BEGIN
{
    use Exporter ();

    @ISA = qw(Exporter);

    @EXPORT = qw(
        $NORMAL_DATETIME_FORMAT
        $ROWID_COL_NAME
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
*DBIx::IO::OracleLib::NORMAL_DATETIME_FORMAT = \'YYYYMMDDHH24MISS';

# Pseudo columns
*DBIx::IO::OracleLib::ROWID_COL_NAME = \'ROWID';

=head1 NAME

DBIx::IO::OracleLib - General helper functions and constants to support the DBIx::IO Oracle driver

=head1 SYNOPSIS

 
 use DBIx::IO::OracleLib;
 use DBIx::IO::OracleLib ();                     # Don't import default symbols
 use DBIx::IO::OracleLib qw(:tag symbol...)      # Import selected symbols


=head1 DESCRIPTION

Oracle specific constants and helper functions.

=cut

1;

__END__

=head1 SEE ALSO

L<DBIx::IO::OracleIO>, L<DBIx::IO::GenLib>, L<DBIx::IO>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

