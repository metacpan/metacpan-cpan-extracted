package Class::DBI::MSAccess;

use warnings;
use strict;

use base qw(Class::DBI);

our $VERSION = '0.10.2';

sub _auto_increment_value {
    my ($self) = @_;
    my $dbh = $self->db_Main;

    my ($id) = $dbh->selectrow_array('SELECT @@IDENTITY');
    $self->_croak("Can't get last insert id") if !defined $id;
    return $id;
}

sub _insert_row {
    my ( $self, $data ) = @_;

    # delegate to Class::DBI for multiple column primary keys
    my @primary_columns = $self->primary_columns();
    return $self->SUPER::_insert_row($data) if @primary_columns > 1;

    # delegate to Class::DBI for explicitly specified primary keys
    my $primary_column = $primary_columns[0];
    return $self->SUPER::_insert_row($data)
        if defined $data->{$primary_column};

    # remove the name of the primary key column
    delete $data->{$primary_column};
    return $self->SUPER::_insert_row($data);
}

1;

__END__

=head1 NAME
 
Class::DBI::MSAccess - Extensions to Class::DBI for MS Access
 
 
=head1 VERSION
 
This documentation refers to Class::DBI::MSAccess version 0.01
 
=head1 SYNOPSIS
 
    package Film;
    use base 'Class::DBI::MSAccess';
    Film->connection('dbi:odbc:dbname', 'user', 'password');
    Film->table("film");
    ...

=head1 DESCRIPTION

This is a simple subclass of Class::DBI which makes Class::DBI work correctly
with Microsoft Access databases.  I've only tested this module when connecting
to the database with DBD::ODBC.  This module requires Microsoft Access 2000 or
newer (so that C<SELECT @@IDENTITY> is available).

The changes to Class::DBI are as follows:

=over 4

=item *

Use C<SELECT @@IDENTITY> to get the value of the AutoNumber primary key column
after inserting a new row.

=item *

If no value is provided for the primary key column when creating a new row,
this module removes the primary key column's name from the C<INSERT INTO> SQL
and tweaks the list of placeholders appropriately.  This causes Access to
autogenerate the new primary key value.

=back
 
=head1 CONFIGURATION AND ENVIRONMENT
 
If you connect to the Access database with ODBC, you'll need to establish the
correct ODBC settings.  Other than that, Class::DBI::MSAccess uses no
configuration files or environment variables.
 
=head1 DEPENDENCIES
 
=over 2

=item *

Class::DBI

=item *

Microsoft Access 2000 or newer

=back
 
=head1 INCOMPATIBILITIES
 
None known
 
=head1 BUGS AND LIMITATIONS

I've only tried this module with DBD::ODBC as the connection method.  If it
does or doesn't work with other connection methods, please let me know.

Please report any bugs or feature requests to
C<bug-class-dbi-msaccess at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-MSAccess>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::DBI::MSAccess

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-DBI-MSAccess>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-DBI-MSAccess>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-MSAccess>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-DBI-MSAccess>

=back

=head1 ACKNOWLEDGEMENTS

Ricardo Signes for writing L<Class::DBI::MSSQL>

=head1 AUTHOR

Michael Hendricks  <michael@palmcluster.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2005 Michael Hendricks (<michael@palmcluster.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
