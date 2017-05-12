package DataWarehouse::ETL;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use DBI;

sub new {
    my ( $class, %param ) = @_;

    croak "Error: One of 'dbh' or 'dsn' parameters is required" if !($param{dbh} xor $param{dsn});

    if ( $param{dsn} ) {
        $param{dbh} = DBI->connect( $param{dsn}, $param{db_user}, $param{db_password} );
    }

    bless \%param, $class;
}

sub dbh {
    my $self = shift;
    return $self->{dbh};
}

sub initialize_dimension {
    my ( $self, %param ) = @_;

    # mandatory
    my $TABLE       = delete $param{TABLE}       || croak "Missing parameter TABLE";
    my $NATURAL_KEY = delete $param{NATURAL_KEY} || croak "Missing parameter NATURAL_KEY";
    my $ATTRIBUTES  = delete $param{ATTRIBUTES}  || croak "Missing parameter ATTRIBUTES";

    $self->{$TABLE}->{NATURAL_KEY} = $NATURAL_KEY;
    $self->{$TABLE}->{ATTRIBUTES}  = $ATTRIBUTES;

    # optional
    $self->{$TABLE}->{TRANSFORM}    = delete $param{TRANSFORM};
    $self->{$TABLE}->{KEEP_HISTORY} = delete $param{KEEP_HISTORY};

    # build a (natural key => surrogate key) cache
    my $rows = $self->dbh->selectall_arrayref("SELECT $NATURAL_KEY, id FROM $TABLE");

    my %table_cache = map { $_->[0] => $_->[1] } @{$rows};

    $self->{$TABLE}{CACHE} = \%table_cache;
}

sub populate_fact {
    my ( $self, %param ) = @_;

    my $TABLE = delete $param{TABLE} || croak "Missing parameter TABLE";

    my $sql = qq{
        INSERT INTO $TABLE (
            @{[ join(',', keys %param) ]}
        ) VALUES (
            @{[ join(',', map { qq{'$param{$_}'} } keys %param) ]}
        );
    };

    my $rv = $self->dbh->do($sql);

    # we don't need to keep a cache of fact ids
    return 1;
}

sub populate_dimension {
    my ( $self, %param ) = @_;

    my $TABLE = delete $param{TABLE} || croak "Missing parameter TABLE";

    my $TRANSFORM = delete $param{TRANSFORM} || $self->{$TABLE}{TRANSFORM};    # optional
    if ( ref $TRANSFORM eq 'CODE' ) {
        %param = $TRANSFORM->(%param);
    }

    my $NATURAL_KEY =
         delete $param{NATURAL_KEY}
      || $self->{$TABLE}{NATURAL_KEY}
      || croak "Missing parameter NATURAL_KEY";

    my $SOURCE_SYSTEM_ID = $param{$NATURAL_KEY} || croak "Attribute '$NATURAL_KEY' can't be NULL";

    if ( my $cached = $self->{$TABLE}{CACHE}{$SOURCE_SYSTEM_ID} ) {
        return $cached;
    }

    my $sql = qq{
        INSERT INTO $TABLE (
            @{[ join(',', keys %param) ]}
        ) VALUES (
            @{[ join(',', map { qq{'$param{$_}'} } keys %param) ]}
        );
    };

    $self->dbh->do($sql);

    my $last_insert_id = $self->dbh->last_insert_id( undef, undef, $TABLE, 'id' );

    $self->{$TABLE}{CACHE}{$SOURCE_SYSTEM_ID} = $last_insert_id;

    return $last_insert_id;
}

sub drop_indexes {
    my ($self) = @_;

    # drop indexes, if exist
    #
    # DROP INDEX request_day;
    # DROP INDEX request_method;
    # DROP INDEX request_user;
    # and so on...

}

sub create_indexes {
    my ($self) = @_;

    # create indexes on fact table foreign keys:
    #
    # CREATE INDEX request_day ON request(day);
    # CREATE INDEX request_method ON request(method);
    # CREATE INDEX request_user ON request(user);
    # and so on...

}

1;

__END__

=head1 NAME

DataWarehouse::ETL - The great new DataWarehouse::ETL!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DataWarehouse::ETL;

    my $foo = DataWarehouse::ETL->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataWarehouse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DataWarehouse::ETL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DataWarehouse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DataWarehouse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DataWarehouse>

=item * Search CPAN

L<http://search.cpan.org/dist/DataWarehouse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Nelson Ferraz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
