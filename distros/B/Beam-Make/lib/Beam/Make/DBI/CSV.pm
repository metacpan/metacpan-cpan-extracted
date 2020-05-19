package Beam::Make::DBI::CSV;
our $VERSION = '0.003';
# ABSTRACT: A Beam::Make recipe 

#pod =head1 SYNOPSIS
#pod
#pod     ### container.yml
#pod     # A Beam::Wire container to configure a database connection to use
#pod     sqlite:
#pod         $class: DBI
#pod         $method: connect
#pod         $args:
#pod             - dbi:SQLite:conversion.db
#pod
#pod     ### Beamfile
#pod     load_data:
#pod         $class: Beam::Wire::DBI
#pod         dbh: { $ref: 'container.yml:sqlite' }
#pod         table: cpan_recent
#pod         file: cpan_recent.csv
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Beam::Make> recipe class loads data into a database from a CSV file.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>, L<Beam::Wire>, L<DBI>
#pod
#pod =cut

use v5.20;
use warnings;
use autodie;
use Moo;
use Time::Piece;
use Text::CSV;
use Digest::SHA qw( sha1_base64 );
use experimental qw( signatures postderef );
use Log::Any qw( $LOG );

extends 'Beam::Make::Recipe';

#pod =attr dbh
#pod
#pod Required. The L<DBI> database handle to use. Can be a reference to a service
#pod in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.
#pod
#pod =cut

has dbh => ( is => 'ro', required => 1 );

#pod =attr table
#pod
#pod Required. The table to load data to.
#pod
#pod =cut

has table => ( is => 'ro', required => 1 );

#pod =attr file
#pod
#pod Required. The path to the CSV file to load.
#pod
#pod =cut

has file => ( is => 'ro', required => 1 );

#pod =attr csv
#pod
#pod The configured L<Text::CSV> object to use. Can be a reference to a service
#pod in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.
#pod Defaults to a new, blank C<Text::CSV> object.
#pod
#pod     ### container.yml
#pod     # Configure a CSV parser for pipe-separated values
#pod     psv:
#pod         $class: Text::CSV
#pod         $args:
#pod             - binary: 1
#pod               sep_char: '|'
#pod               quote_char: ~
#pod               escape_char: ~
#pod
#pod     ### Beamfile
#pod     # Load a PSV into the database
#pod     load_psv:
#pod         $class: Beam::Make::DBI::CSV
#pod         dbh: { $ref: 'container.yml:sqlite' }
#pod         csv: { $ref: 'container.yml:psv' }
#pod         file: accounts.psv
#pod         table: accounts
#pod
#pod =cut

has csv => ( is => 'ro', default => sub { Text::CSV->new } );

sub make( $self, %vars ) {
    my $dbh = $self->dbh;
    open my $fh, '<', $self->file;
    my $csv = $self->csv;
    my @fields = $csv->getline( $fh )->@*;
    my $sth = $dbh->prepare(
        sprintf 'INSERT INTO %s ( %s ) VALUES ( %s )',
        $dbh->quote_identifier( $self->table ),
        join( ', ', map { $dbh->quote_identifier( $_ ) } @fields ),
        join( ', ', ('?')x@fields ),
    );
    while ( my $row = $csv->getline( $fh ) ) {
        $sth->execute( @$row );
    }
    $self->cache->set( $self->name, $self->_cache_hash );
    return 0;
}

sub _cache_hash( $self ) {
    my $content = join ';',
        map { join ',', @$_ }
        $self->dbh->selectall_arrayref( 'SELECT * FROM ' . $self->table )->@*;
    return sha1_base64( $content );
}

sub last_modified( $self ) {
    return $self->cache->last_modified( $self->name, $self->_cache_hash );
}

1;

__END__

=pod

=head1 NAME

Beam::Make::DBI::CSV - A Beam::Make recipe 

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ### container.yml
    # A Beam::Wire container to configure a database connection to use
    sqlite:
        $class: DBI
        $method: connect
        $args:
            - dbi:SQLite:conversion.db

    ### Beamfile
    load_data:
        $class: Beam::Wire::DBI
        dbh: { $ref: 'container.yml:sqlite' }
        table: cpan_recent
        file: cpan_recent.csv

=head1 DESCRIPTION

This L<Beam::Make> recipe class loads data into a database from a CSV file.

=head1 ATTRIBUTES

=head2 dbh

Required. The L<DBI> database handle to use. Can be a reference to a service
in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.

=head2 table

Required. The table to load data to.

=head2 file

Required. The path to the CSV file to load.

=head2 csv

The configured L<Text::CSV> object to use. Can be a reference to a service
in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.
Defaults to a new, blank C<Text::CSV> object.

    ### container.yml
    # Configure a CSV parser for pipe-separated values
    psv:
        $class: Text::CSV
        $args:
            - binary: 1
              sep_char: '|'
              quote_char: ~
              escape_char: ~

    ### Beamfile
    # Load a PSV into the database
    load_psv:
        $class: Beam::Make::DBI::CSV
        dbh: { $ref: 'container.yml:sqlite' }
        csv: { $ref: 'container.yml:psv' }
        file: accounts.psv
        table: accounts

=head1 SEE ALSO

L<Beam::Make>, L<Beam::Wire>, L<DBI>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
