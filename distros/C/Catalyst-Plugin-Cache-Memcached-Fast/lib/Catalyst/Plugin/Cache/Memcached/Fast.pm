package Catalyst::Plugin::Cache::Memcached::Fast;

use strict;
use warnings;
use base 'Class::Data::Inheritable';

our $VERSION='0.14';

use Cache::Memcached::Fast;

__PACKAGE__->mk_classdata('cache');

=head2 EXTENDED METHODS

=head3 setup

=cut


sub setup {
	my $self = shift;

	my $params = {};

	if ( $self->config->{cache} ) {
		$params = { %{ $self->config->{cache} } };
	}

	if( ref $params->{servers} ne 'ARRAY' ){
		$params->{servers} = [$params->{servers}];
	}

	$self->cache( Cache::Memcached::Fast->new($params) );

	return $self->next::method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Cache::Memcached::Fast - Catalyst Plugin for Cache::Memcached::Fast

=head1 SYNOPSIS

	use Catalyst qw[Cache::Memcached::Fast];

	MyApp->config(
		cache => {
			servers => [
				'127.0.0.1:11211',
				'127.0.0.1:11212',
			],
			namespace => 'MyApp:',
		}
	);
	my $data;

	unless ( $data = $c->cache->get('data') ) {
		$data = $c->model('MyApp::MyData')->search();
		$c->cache->set( 'data', $data );
	}

	$c->response->body($data);


=head1 DESCRIPTION

Extends base class with a distributed cache.

=head1 METHODS

=over 4

=item cache

Returns an instance of C<Cache::Memcached::Fast>

=back

=head1 SEE ALSO

L<Cache::Memcached::Fast>, L<Catalyst>.

=head1 AUTHOR

S<Vasiliy Voloshin>, C<< <vasiliy.voloshin at gmail.com> >>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
