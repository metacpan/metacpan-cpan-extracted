package DBD::PO::dr; ## no critic (Capitalization)

use strict;
use warnings;

our $VERSION = '2.00';

use DBD::File;
use parent qw(-norequire DBD::File::dr);
use DBD::PO::Text::PO;

my $PV = 0;
my $IV = 1;
my $NV = 2;

## no critic (PackageVars)
our @PO_TYPES = (
    $IV, # SQL_TINYINT
    $IV, # SQL_BIGINT
    $PV, # SQL_LONGVARBINARY
    $PV, # SQL_VARBINARY
    $PV, # SQL_BINARY
    $PV, # SQL_LONGVARCHAR
    $PV, # SQL_ALL_TYPES
    $PV, # SQL_CHAR
    $NV, # SQL_NUMERIC
    $NV, # SQL_DECIMAL
    $IV, # SQL_INTEGER
    $IV, # SQL_SMALLINT
    $NV, # SQL_FLOAT
    $NV, # SQL_REAL
    $NV, # SQL_DOUBLE
);
our $imp_data_size = 0;
our $data_sources_attr = ();
## use critic (PackageVars)

sub connect { ## no critic (BuiltinHomonyms)
    my ($drh, $dbname, $user, $auth, $attr) = @_;

    my $dbh = $drh->SUPER::connect($dbname, $user, $auth, $attr);
    $dbh->{po_tables} ||= {};
    $dbh->{Active} = 1;

    return $dbh;
}

1;

__END__

=head1 NAME

DBD::PO::dr - driver class for DBD::PO

$Id: dr.pm 340 2009-03-01 16:22:05Z steffenw $

$HeadURL: https://dbd-po.svn.sourceforge.net/svnroot/dbd-po/trunk/DBD-PO/lib/DBD/PO/dr.pm $

=head1 VERSION

2.00

=head1 SYNOPSIS

do not use

=head1 DESCRIPTION

driver class for DBD::PO

=head1 SUBROUTINES/METHODS

=head2 method connect

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

parent

L<DBD::File>

L<DBD::PO::Text::PO>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2009,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut