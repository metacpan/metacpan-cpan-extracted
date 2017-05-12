package Catalyst::Plugin::Cache::Memcached;

use strict;
use base 'Class::Data::Inheritable';

our $VERSION='0.8';

use Cache::Memcached;

__PACKAGE__->mk_classdata('cache');

{
    package Cache::Memcached;
    *remove = \&delete;
}

sub setup {
    my $self = shift;

    my $params = {};

    if ( $self->config->{cache} ) {
        $params = { %{ $self->config->{cache} } };
    }

    $self->cache( Cache::Memcached->new($params) );

    return $self->NEXT::setup(@_);
}

1;


__END__

=head1 NAME

Catalyst::Plugin::Cache::Memcached - [DEPRECATED] Distributed cache

=head1 SYNOPSIS

    use Catalyst qw[Cache::Memcached];

    MyApp->config->{cache}->{servers} = [ '10.0.0.15:11211', 
                                          '10.0.0.15:11212' ];

    my $data;

    unless ( $data = $c->cache->get('data') ) {
        $data = MyApp::Model::Data->retrieve('data');
        $c->cache->set( 'data', $data );
    }

    $c->response->body($data);


=head1 DESCRIPTION

Extends base class with a distributed cache.

Note: This plugin is deprecated and is just maintained for backwards
compatibility. You should configure C<Catalyst::Plugin::Cache> directly
as documented, rather than using this module.

=head1 METHODS

=over 4

=item cache

Returns an instance of C<Cache::Memcached>

=item setup

Wraps Catalyst's setup method to setup the L<Cache::Memcached> instance.

=back

=head1 SEE ALSO

L<Cache::Memcached>, L<Catalyst>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>
Sebastian Riedel C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
