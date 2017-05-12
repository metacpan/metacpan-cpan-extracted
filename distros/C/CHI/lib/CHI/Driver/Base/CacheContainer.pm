package CHI::Driver::Base::CacheContainer;
$CHI::Driver::Base::CacheContainer::VERSION = '0.60';
use Moo;
use List::MoreUtils qw( all );
use strict;
use warnings;

extends 'CHI::Driver';

has '_contained_cache' => ( is => 'ro' );

sub fetch {
    my ( $self, $key ) = @_;

    return scalar( $self->_contained_cache->get($key) );
}

sub store {
    my $self = shift;

    return $self->_contained_cache->set(@_);
}

sub remove {
    my ( $self, $key ) = @_;

    $self->_contained_cache->remove($key);
}

sub clear {
    my $self = shift;

    return $self->_contained_cache->clear(@_);
}

sub get_keys {
    my $self = shift;

    return $self->_contained_cache->get_keys(@_);
}

sub get_namespaces {
    my $self = shift;

    return $self->_contained_cache->get_namespaces(@_);
}

1;

__END__

=pod

=head1 NAME

CHI::Driver::Base::CacheContainer - Caches that delegate to a contained cache

=head1 VERSION

version 0.60

=head1 DESCRIPTION

Role for CHI drivers with an internal '_contained_cache' slot that itself
adheres to the Cache::Cache API, partially or completely.

=head1 SEE ALSO

L<CHI|CHI>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
