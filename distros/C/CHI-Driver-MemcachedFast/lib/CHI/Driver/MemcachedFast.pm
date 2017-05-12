package CHI::Driver::MemcachedFast;
use Moose;
use Cache::Memcached::Fast;
our $VERSION = '0.02';

extends 'CHI::Driver::Memcached';

override '_build_contained_cache' => sub {
    my ($self) = @_;
    return Cache::Memcached::Fast->new( $self->{mc_params} );
};

__PACKAGE__->meta->make_immutable();
no Moose;

1;

__END__

=pod

=head1 NAME

CHI::Driver::MemcachedFast -- Distributed cache via memcached (memory cache daemon)

=head1 SYNOPSIS

    use CHI;

    my $cache = CHI->new(
        driver => 'MemcachedFast',
        servers => [ "10.0.0.15:11211", "10.0.0.15:11212", "/var/sock/memcached",
        "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
        debug => 0,
        compress_threshold => 10_000,
    );

=head1 DESCRIPTION

This cache driver uses Cache::Memcached to store data in the specified memcached server(s).

=head1 CONSTRUCTOR OPTIONS

When using this driver, the following options can be passed to CHI->new() in addition to the
L<CHI|general constructor options/constructor>.
    
=over

=item cache_size

=item page_size

=item num_pages

=item init_file

These options are passed directly to L<Cache::Memcached::Fast>.

=back

=head1 METHODS

=over

=item memd

Returns a handle to the underlying Cache::Memcached::Fast object. You can use this to call memcached-specific methods that
are not supported by the general API, e.g.

    $self->memd->incr("key");
    my $stats = $self->memd->stats();

=back

=head1 SEE ALSO

Cache::Memcached
CHI

=head1 AUTHOR

Takatoshi Kitano <kitano.tk at gmail.com> 

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 Dann

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
