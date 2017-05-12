package Catalyst::Plugin::Cache::BerkeleyDB;
use strict;
use base qw/Class::Data::Inheritable/;
use Cache::BerkeleyDB;

our $VERSION= '0.01';

sub setup {
    my $self = shift;

    my $params = $self->config->{cache} || {};
    $params->{cache_root} = delete $params->{storage} if $params->{storage};
    $params->{default_expires_in} = delete $params->{expires} if $params->{expires};
    $params->{namespace} ||= $self;

    __PACKAGE__->mk_classdata(cache => Cache::BerkeleyDB->new($params));

    $self->NEXT::setup(@_);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Cache::BerkeleyDB

=head1 SYNOPSIS

    use Catalyst qw/Cache::BerkeleyDB/;

    MyApp->config->{cache}{storage} = '/tmp/cache';
    MyApp->config->{cache}{expires} = 3600;

    # somewhere in a controller
    my $data;
    
    unless ( $data = $c->cache->get('data') ) {
        $data = MyApp::Model::Data->retrieve('data');
        $c->cache->set( 'data', $data );
    }

    $c->response->body($data);

=head1 DESCRIPTION

Adds an accessor for a BerkeleyDB cache in your Catalyst application class.

=head1 METHODS

=over 4

=item cache

Returns an instance of L<Cache::BerkeleyDB>.

=back

=head1 OPTIONS

Options are specified under C<< MyApp->config->{cache} >>. Besides the options
given below, any other options present will be passed along to L<Cache::BerkeleyDB>.

=over 4

=item storage

Path to the directory to use for the cache.

=item expires

In seconds, passed to L<Cache::BerkeleyDB> as C<default_expires_in>. Default is
not to expire.

=item namespace

The namespace to use for the cache. Default is the name of your Catalyst application.

=back

=head1 SEE ALSO

L<Cache::BerkeleyDB>, L<Catalyst>.

=head1 AUTHOR

David Kamholz <dkamholz@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
