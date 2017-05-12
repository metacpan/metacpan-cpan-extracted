package DBIx::NoSQL::TypeMap;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::TypeMap::VERSION = '0.0021';
use strict;
use warnings;

use Moose;

has _map => qw/ is ro isa HashRef /, default => sub { {} };

sub BUILD {
    my $self = shift;

    $self->create( 'DateTime',
        inflate => sub { return DateTime->from_epoch( epoch => $_[0] ) },
        deflate => sub { return $_[0]->epoch },
    );
}

sub type {
    my $self = shift;
    my $name = shift;

    return $self->_map->{ $name };
}

#has _cache => qw/ is rw isa HashRef /, default => sub { {} };
#sub find {
    #my $self = shift;
    #my $package = shift;

    #my $type;
    #my $cache = $self->_cache;
    #while( ! $type ) {
    #}
#}

sub create {
    my $self = shift;
    my $name = shift;

    die "Already have type ($name)" if $self->_map->{ $name };

    my $type = $self->_map->{ $name } = DBIx::NoSQL::TypeMap::Type->new( name => $name, @_ );
    return $type;
}

package DBIx::NoSQL::TypeMap::Type;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::TypeMap::Type::VERSION = '0.0021';
use Moose;

has name => qw/ is ro required 1 isa Str /;

has inflate => qw/ accessor _inflate isa Maybe[CodeRef] /;
has deflate => qw/ accessor _deflate isa Maybe[CodeRef] /;
sub inflator { return shift->_inflate( @_ ) }
sub deflator { return shift->_deflate( @_ ) }

sub inflate { return $_[0]->_inflate->( $_[1] ) }
sub deflate { return $_[0]->_deflate->( $_[1] ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::TypeMap

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
