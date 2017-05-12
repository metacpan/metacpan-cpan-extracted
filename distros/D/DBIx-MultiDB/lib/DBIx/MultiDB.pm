package DBIx::MultiDB;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use DBI;

our $VERSION = '0.06';

sub new {
    my ( $class, %param ) = @_;

    bless { base => {%param}, left_join => [] }, $class;
}

*attach = \&left_join;
*join   = \&left_join;

sub left_join {
    my ( $self, %param ) = @_;

    my $dbh = $param{dbh}
      || DBI->connect( $param{dsn}, $param{user}, $param{password}, { RaiseError => 1 } );

    # the preferred approach is to list the primary key on this table ("key")
    # and the foreign key in the base table ("referenced_by").

    # alternatively, we can specify the foreign key in the base table ("key")
    # and which key it "references" in this table ("references"):
    if ( $param{references} and $param{key} ) {
        $param{referenced_by} = delete $param{key};
        $param{key}           = delete $param{references};
    }

    warn "Retrieving left_join data ($param{key} referenced by $param{referenced_by})...\n" if $param{VERBOSE};

    # put everything in memory
    my $data = $dbh->selectall_hashref( $param{sql}, $param{key}, );

    push @{ $self->{left_join} }, { %param, data => $data };

    if ( $param{VERBOSE} and $param{VERBOSE} >= 2 ) {
        require Devel::Size;
        warn "Calculating memory usage...\n";
        my $memory_usage = sprintf( '%1.2f', ( Devel::Size::total_size($data) / ( 1024 * 1024 ) ) );    # MB
        warn "Memory usage: $memory_usage MB\n\n";
    }

    return;
}

sub prepare {
    my ( $self, $sql, $attr ) = @_;

    my $dbh = $self->{base}->{dbh}
      || DBI->connect( @{ $self->{base} }{ 'dsn', 'user', 'password' }, { RaiseError => 1 } );

    my $sth = $dbh->prepare($sql);

    if ( defined $attr ) {
        $self->{base}->{$_} = $attr->{$_} for keys %{$attr};
    }

    $self->{base}->{sth} = $sth;

    return $self;
}

sub execute {
    my $self = shift;

    if ( !$self->{base}->{sth} ) {
        $self->prepare( $self->{base}->{sql} );
    }

    $self->{base}->{sth}->execute();

    return $self;
}

sub fetchrow_hashref {
    my $self = shift;

    # get the base row
    my $row = $self->{base}->{sth}->fetchrow_hashref();

    return if !$row;

    # now we are going to attach the left_join data

    my %row = %{$row};

    for my $join ( @{ $self->{left_join} } ) {
        my $base_key   = $join->{referenced_by};
        my $base_value = $row{$base_key};

        # now, look up the base value in the cached join data...
        for my $joined_key ( keys %{ $join->{data}->{$base_value} } ) {
            my $joined_value = $join->{data}->{$base_value}->{$joined_key};
            $row{$joined_key} = $joined_value;
        }
    }

    return \%row;
}

1;

__END__

=head1 NAME

DBIx::MultiDB - join data from multiple databases

=head1 SYNOPSIS

    use DBIx::MultiDB;

    # Example 1

    my $query = DBIx::MultiDB->new(
        dsn => 'dbi:SQLite:dbname=/tmp/db1.db',
        sql => 'SELECT id, name, company_id FROM employee',
    );
    
    $query->left_join(
        dsn           => 'dbi:SQLite:dbname=/tmp/db2.db',
        sql           => 'SELECT id, name AS company_name FROM company',
        key           => 'id',          # in this table
        referenced_by => 'company_id',  # in base table
    );
    
    $query->execute();

    # Example 2

    my $query = DBIx::MultiDB->new(
        dsn => 'dbi:SQLite:dbname=/tmp/db1.db',
    );

    $query->left_join(
        dsn           => 'dbi:SQLite:dbname=/tmp/db2.db',
        sql           => 'SELECT id, name AS company_name FROM company',
        key           => 'company_id', # in base table
        references    => 'id',         # in this table
    );

    $query->prepare('SELECT id, name, company_id FROM employee');
    $query->execute();

    while ( my $row = $query->fetchrow_hashref ) {
        # ...
    }

=head1 DESCRIPTION

DBIx::MultiDB provides a simple way to join data from different sources.

You are not limited to a single database engine: in fact, you can join data
from any source for which you have a DBI driver (MySQL, PostgreSQL, SQLite, 
etc). You can even mix them!

=head1 METHODS

=head2 new

Constructor. You can provide a dsn and sql, which is your base query.

=head2 left_join

=head2 attach

=head2 join

Once you have a base query, you can attach multiple queries that will be
joined to it. For each one, you must provide a dsn, sql, and the relationship
information (key and referenced_by).

Please note that this will also load the attached query into memory.

=head2 inner_join

Not yet implemented.

=head2 prepare

If you didn't provide the sql to the constructor, you can do it here.
Example:

    $query->prepare('SELECT id, name, company_id FROM employee');
    $query->execute();

=head2 execute

Execute the base query.

=head2 fetchrow_hashref

Return a hashref, containing field names and values. The keys pointing to
attached queries will be expanded into the attached queries' fields.

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 CAVEATS

While the base query is processed row by row, the joined tables must be
previously stored in memory.

That means you can easily process hundreds of millions rows in the
base query; but you must watch how much information you retrieve in
the joins.

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-multidb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-MultiDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::MultiDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-MultiDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-MultiDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-MultiDB>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-MultiDB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Nelson Ferraz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
