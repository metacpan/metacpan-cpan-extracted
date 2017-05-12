package Bio::Protease::Role::WithCache;
{
  $Bio::Protease::Role::WithCache::VERSION = '1.112980';
}

# ABSTRACT: A role that adds optional memoization of ProteaseI methods

use Moose::Role;
use MooseX::Types::Moose 'Bool';
use namespace::autoclean;

has use_cache => ( is => 'ro', isa => Bool, default => 0 );

has cache => (
    is        => 'ro',
    lazy      => 1,
    does      => 'Cache::Ref::Role::API',
    predicate => '_has_cache',
    default =>
      sub { require Cache::Ref::LRU; Cache::Ref::LRU->new( size => 5000 ) },
);

foreach my $method (qw(digest is_substrate cleavage_sites)) {
    around $method => sub {
        my ($orig, $self, $substrate) = @_;

        return $self->$orig($substrate) if ( !$self->use_cache or !$substrate );

        my $computed = $self->cache->get("$method-$substrate");

        if ($computed) {
            return @$computed;
        }
        else {
            my @result = $self->$orig($substrate);
            $self->cache->set( "$method-$substrate" => \@result );
            return @result;
        }
    };
}


1;

__END__
=pod

=head1 NAME

Bio::Protease::Role::WithCache - A role that adds optional memoization of ProteaseI methods

=head1 VERSION

version 1.112980

=head1 SYNOPSIS

    package My::Protease;
    use Moose;
    with qw(Bio::ProteaseI Bio::Protease::Role::WithCache);

    sub _cuts { ... }

    # Done, all ProteaseI methods now support optional caching
    # through the 'has_cache' and 'cache' attributes

    1;

=head1 ATTRIBUTES

=head2 use_cache

Turn caching on, trading memory for speed. Defaults to 0 (no caching).
Useful when any method is being called several times with the same
argument.

    my $p = Bio::Protease->new( specificity => 'trypsin', use_cache => 0 );
    my $c = Bio::Protease->new( specificity => 'trypsin', use_cache => 1 );

    my $substrate = 'MAAEELRKVIKPR' x 10;

    $p->digest( $substrate ) for (1..1000); # time: 5.11s
    $c->digest( $substrate ) for (1..1000); # time: 0.12s

=head2 cache

The cache object, which has to do the L<Cache::Ref::Role::API> role.
Uses L<Cache::Ref::LRU> by default with a cache size of 5000, but you
can set this to your liking at construction time:

    my $p = Bio::Protease->new(
        use_cache   => 1,
        cache       => Cache::Ref::Random->new( size => 50 ),
        specificity => 'trypsin'
    );

=head1 AUTHOR

Bruno Vecchi <vecchi.b gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Bruno Vecchi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

