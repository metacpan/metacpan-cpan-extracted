package Class::DBI::DDL::Pg;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.01';

=head1 NAME

Class::DBI::DDL::Pg - Perform driver dependent work for PostgreSQL

=head1 DESCRIPTION

Do not use this package directly. Intead, it will automatically be imported
and used by L<Class::DBI::DDL> when the underlying database uses the L<DBD::Pg>
driver.

The only method here that works different from the default is
C<pre_create_table>. This method uses the PostgreSQL C<SERIAL> type to perform
auto-increment and sets the C<sequence> method since L<Class::DBI> doesn't
properly handle PostgreSQL auto-numbering.

=cut

sub pre_create_table {
	my ($class, $self) = @_;

	# For each column with an auto_increment property, drop that property and
	# change the type to serial and set sequence to reference this column--this
	# will only work for a single primary key column...
	for my $column (@{$self->column_definitions}) {
		if (grep /^auto_increment$/i, @{$column}[1 .. $#$column]) {
			$$column[1] = 'serial';
			@$column = grep !/^auto_increment$/i, @$column;
			$self->sequence($self->table."_$$column[0]_seq");
		}
	}
}

sub post_create_table { }

sub pre_drop_table { }

sub post_drop_table { }

=head1 SEE ALSO

L<Class::DBI>, L<DBI>, L<Class::DBI::DDL>, L<DBD::Pg>

=head1 AUTHOR

Andrew Sterling Hanenkamp <sterling@hanenkamp.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Andrew Sterling Hanenkamp. All Rights Reserved.

This module is free software and is distributed under the same license as Perl
itself.

=cut

1
