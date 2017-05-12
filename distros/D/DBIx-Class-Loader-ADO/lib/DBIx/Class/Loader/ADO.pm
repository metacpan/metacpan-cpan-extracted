package DBIx::Class::Loader::ADO;

use strict;
use base qw( DBIx::Class::Loader::Generic );

use Carp;

our $VERSION = '0.07';

=head1 NAME

DBIx::Class::Loader::ADO - DBIx::Class::Loader ADO Implementation.

=head1 SYNOPSIS

    use DBIx::Class::Loader;

    # $loader is a DBIx::Class::Loader::ADO
    my $loader = DBIx::Class::Loader->new(
        dsn       => "dbi:ADO:$DSN",
        namespace => "Data",
    );
    my $class = $loader->find_class('film'); # $class => Data::Film
    my $obj = $class->retrieve(1);

=head1 DESCRIPTION

See L<DBIx::Class::Loader>.

=head1 INSTALLATION

To install this module via Module::Build:

    perl Build.PL
    ./Build         # or `perl Build`
    ./Build test    # or `perl Build test`
    ./Build install # or `perl Build install`

To install this module via ExtUtils::MakeMaker:

    perl Makefile.PL
    make
    make test
    make install

=cut

sub _db_classes{
    return qw( DBIx::Class::PK::Auto::MSSQL );
}

sub _relationships {
    my $self   = shift;
    my @tables = $self->tables;
    my $dbh    = $self->find_class( $tables[ 0 ] )->storage->dbh;
    my $sth    = $dbh->foreign_key_info( undef, undef, undef, undef, undef, undef );

    # needs testing and a way to detect relationships
    # other than one to many
    while ( my $row = $sth->fetch ) {
        my( @args ) = ( lc $row->[ 2 ], $row->[ 3 ], lc $row->[ 6 ], $row->[ 7 ] );
        eval { $self->_belongs_to_many( @args ) };
        warn qq/\# belongs_to_many failed "$@"\n\n/ if $@ && $self->debug;
    }
}

sub _tables {
    my $self = shift;
    my $dbh  = $self->{ storage }->dbh;
    my $sth  = $dbh->table_info( undef, undef, undef, "TABLE" );

    my @tables;
    while ( my $row = $sth->fetch ) {
        push @tables, $row->[ 2 ];
    }

    return @tables;
}

sub _table_info {
    my( $self, $table ) = @_;
    my $dbh = $self->{ storage }->dbh;
    my $sth = $dbh->column_info( undef, undef, $table, undef );

    my( @cols, @pri );
    while( my $row = $sth->fetch ) {
        push @cols, $row->[ 3 ];
    }

    $sth = $dbh->primary_key_info( undef, undef, $table );
    while( my $row = $sth->fetch ) {
        push @pri, $row->[ 3 ];
    }

    croak("$table has no primary key") unless @pri;

    return( \@cols, \@pri );
}

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::Loader>

=item * L<DBD::ADO>

=back

=head1 AUTHOR

=over 4

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
