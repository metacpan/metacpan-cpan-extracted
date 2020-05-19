package Beam::Make::DBI;
our $VERSION = '0.003';
# ABSTRACT: A Beam::Make recipe for executing SQL queries

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
#pod     convert:
#pod         $class: Beam::Wire::DBI
#pod         dbh: { $ref: 'container.yml:sqlite' }
#pod         query:
#pod             - |
#pod                 INSERT INTO accounts ( account_id, address )
#pod                 SELECT
#pod                     acct_no,
#pod                     CONCAT( street, "\n", city, " ", state, " ", zip )
#pod                 FROM OLD_ACCTS
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Beam::Make> recipe class executes one or more SQL queries against
#pod the given L<DBI> database handle.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>, L<Beam::Wire>, L<DBI>
#pod
#pod =cut

use v5.20;
use warnings;
use Moo;
use Time::Piece;
use Digest::SHA qw( sha1_base64 );
use List::Util qw( pairs );
use experimental qw( signatures postderef );

extends 'Beam::Make::Recipe';

#pod =attr dbh
#pod
#pod Required. The L<DBI> database handle to use. Can be a reference to a service
#pod in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.
#pod
#pod =cut

has dbh => ( is => 'ro', required => 1 );

#pod =attr query
#pod
#pod An array of SQL queries to execute.
#pod
#pod =cut

has query => ( is => 'ro', required => 1 );

sub make( $self, %vars ) {
    my $dbh = $self->dbh;
    for my $sql ( $self->query->@* ) {
        $dbh->do( $sql );
    }
    $self->cache->set( $self->name, $self->_cache_hash );
    return 0;
}

sub _cache_hash( $self ) {
    # If our write query changed, we should update
    my $content = sha1_base64( join "\0", $self->query->@* );
    return $content;
}

sub last_modified( $self ) {
    my $last_modified = $self->cache->last_modified( $self->name, $self->_cache_hash );
    return $last_modified;
}

1;

__END__

=pod

=head1 NAME

Beam::Make::DBI - A Beam::Make recipe for executing SQL queries

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
    convert:
        $class: Beam::Wire::DBI
        dbh: { $ref: 'container.yml:sqlite' }
        query:
            - |
                INSERT INTO accounts ( account_id, address )
                SELECT
                    acct_no,
                    CONCAT( street, "\n", city, " ", state, " ", zip )
                FROM OLD_ACCTS

=head1 DESCRIPTION

This L<Beam::Make> recipe class executes one or more SQL queries against
the given L<DBI> database handle.

=head1 ATTRIBUTES

=head2 dbh

Required. The L<DBI> database handle to use. Can be a reference to a service
in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.

=head2 query

An array of SQL queries to execute.

=head1 SEE ALSO

L<Beam::Make>, L<Beam::Wire>, L<DBI>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
