package Class::DBI::ViewLoader::Pg;

use strict;
use warnings;

our $VERSION = '0.05';

=head1 NAME

Class::DBI::ViewLoader::Pg - Class::DBI::Viewloader implementation for Postgresql.

=head1 SYNOPSIS

    use Class::DBI::ViewLoader;

    $loader = Class::DBI::ViewLoader dsn => 'dbi:Pg:dbname=mydb';

    # load views from mydb
    @classes = $loader->load_views

=head1 DESCRIPTION

This is the postgresql driver for L<Class::DBI::ViewLoader>, 

=head1 METHODS

=cut

use Class::DBI::Pg;

use base qw( Class::DBI::ViewLoader );

=head2 base_class

Returns 'Class::DBI::Pg'. This class will be used as the main base class for all
classes generated using this driver.

=cut

sub base_class { 'Class::DBI::Pg' };

=head2 get_views

    @views = $obj->get_views

Returns a list of the names of the views in the current database.

=cut

sub get_views {
    my $self = shift;
    my $dbh = $self->_get_dbi_handle;

    return $dbh->tables(
	    undef,	# catalog
	    "public",	# schema
	    "",		# name
	    "view",	# type
	    { noprefix => 1, pg_noprefix => 1 }
	);
}

=head2 get_view_cols

    @cols = $obj->get_view_cols($view)

Returns the columns contained in the given view.

=cut

sub get_view_cols {
    my($self, $view) = @_;
    my $sth = $self->_get_cols_sth;

    $sth->execute($view);

    my @columns = map {$_->[0]} @{$sth->fetchall_arrayref};

    $sth->finish;

    return grep { !/^\.+pg\.dropped\.\d+\.+$/ } @columns;
}

# SQL to get columns cribbed from Class::DBI::Pg->set_up_table
my $col_sql = <<END_SQL;
SELECT a.attname
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_attribute a on a.attrelid = c.oid
WHERE c.relname = ?
  AND a.attnum > 0
ORDER BY a.attnum
END_SQL

# cache the statement handle 
sub _get_cols_sth {
    my $self = shift;

    if (defined $self->{__col_sth}) {
	return $self->{__col_sth};
    }
    else {
	my $dbh = $self->_get_dbi_handle;

	return $self->{__col_sth} = $dbh->prepare($col_sql);
    }
}

# make sure the cache is cleared when the dbi handle is cleaned up
sub _clear_dbi_handle {
    my $self = shift;

    # Should be no need to explicitly finish this..
    delete $self->{__col_sth};

    $self->SUPER::_clear_dbi_handle(@_);
}

1;

__END__

=head1 SEE ALSO

L<Class::DBI::ViewLoader>, L<Class::DBI::Loader>, L<Class::DBI>, L<http://www.postgresql.org/>

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 Matt Lawrence, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

vim: ts=8 sts=4 sw=4
