package DBIx::NoSQL::Storage;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::Storage::VERSION = '0.0021';
use Moose;
use Carp;

has store => qw/ is ro required 1 weak_ref 1 /;

has statement_caching => qw/ is rw isa Bool default 0 /;

has foreign_storage => qw/ is ro lazy_build 1 weak_ref 1 /;
sub _build_foreign_storage {
    my $self = shift;
    return $self->store->schema->storage;
}

sub do {
    my $self = shift;
    my $statement = shift;
    my @bind = @_;

    my $attributes;
    $attributes = shift @bind if @bind && ref $bind[0] eq 'HASH';

    $self->_query_start( $statement => @bind );
    $self->foreign_storage->dbh_do( sub {
        $_[1]->do( $statement, $attributes, @bind );
    } );
    $self->_query_end( $statement => @bind );
}

sub retrying_do {
    my $self = shift;
    my $code = shift;

    return $self->foreign_storage->dbh_do( $code, @_ );
}

sub select {
    my $self = shift;
    my $statement = shift;
    my $attributes = shift;
    my $bind = shift;

    $self->_query_start( $statement => @$bind );

    my $foreign = $self->foreign_storage;
    my $sth = $foreign->dbh_do( sub {
        my $dbh = $_[1];
        my $sth = $self->statement_caching ?
            $dbh->prepare_cached( $statement, $attributes || {}, 3 ) :
            $dbh->prepare( $statement, $attributes || {} )
        ;
        croak $dbh->errstr unless $sth;
        return $sth;
    } );

    my $rv = $sth->execute( @$bind );
    croak $sth->errstr || $sth->err || "Unknown error: \$sth->execute return false without setting an error flag" unless $rv;

    $self->_query_end( $statement, @$bind );

    return $sth;
}

sub cursor {
    my $self = shift;
    my $statement = shift;
    my $attributes;
    $attributes = shift if ref $_[0] eq 'HASH';
    my $bind = shift;

    return DBIx::NoSQL::Storage::Cursor->new( storage => $self, statement => $statement, attributes => $attributes, bind => $bind );
}

sub _query_start {
    my $self = shift;
    if ( $self->foreign_storage->debug ) {
        $self->foreign_storage->debugobj->query_start( @_ );
    }
}

sub _query_end {
    my $self = shift;
    if ( $self->foreign_storage->debug ) {
        $self->foreign_storage->debugobj->query_end( @_ );
    }
}

sub table_exists {
    my $self = shift;
    my $table_name = shift;

    my $statement = <<_END_;
SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?
_END_
    my @bind = ( $table_name );

    my $cursor = $self->cursor( $statement, \@bind );
    my $result = $cursor->next;
    return $result->[0] ? 1 : 0;
}

package DBIx::NoSQL::Storage::Cursor;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::Storage::Cursor::VERSION = '0.0021';
use Moose;
use Try::Tiny;

has storage => qw/ is ro required 1 /;

has statement => qw/ is ro required 1 /; 
has attributes => qw/ is ro /;
has bind => qw/ is ro required 1 isa ArrayRef /;

has sth => qw/ is rw /;
has finished => qw/ is rw isa Bool default 0 /;

sub _select {
    my $self = shift;
    return $self->storage->select( $self->statement, $self->attributes, $self->bind );
}

sub next {
    my $self = shift;

    return if $self->finished;

    unless ( $self->sth ) {
        $self->sth( $self->_select );
    }

    my $row = $self->sth->fetchrow_arrayref or do {
        $self->sth( undef );
        $self->finished( 0 );
    };

    return $row || [];
}

sub all {
    my $self = shift;

    $self->sth->finish if $self->sth && $self->sth->{Active};
    $self->sth( undef );
    my $sth;
    $self->storage->retrying_do( sub {
        $sth = $self->_select;
    } );
    my $all = $sth->fetchall_arrayref;
    return [] unless $all;
    return $all;
}

sub reset {
    my $self = shift;

    try { $self->sth->finish } if $self->sth && $self->sth->{Active};
    $self->_soft_reset;
}

sub _soft_reset {
    my $self = shift;

    $self->sth( undef );
    $self->finished( 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Storage

=head1 VERSION

version 0.0021

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
