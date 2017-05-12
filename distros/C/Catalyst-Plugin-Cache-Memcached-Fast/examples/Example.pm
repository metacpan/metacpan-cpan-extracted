package 
	Example;
# vim600: noet ts=4 fdm=marker cms=#%s enc=utf-8

use strict; use warnings;

use utf8;
use Moose;
use Catalyst;
extends qw/Catalyst/;

__PACKAGE__->config(
	cache => {
		servers => [
			'127.0.0.1:11211',
			'127.0.0.1:11212',
		],
		namespace => 'MyApp:',
	}
);


__PACKAGE__->setup(
	qw/
		-Debug
		ConfigLoader
		Cache::Memcached::Fast
	/
);

1;

#=====================================================================
package 
	Example::Controller;

use Moose;
BEGIN { extends 'Catalyst::Controller' };

sub index : Local {
	my ($self, $c) = @_;

	my $data;

	unless ( $data = $c->cache->get('data') ) {
		$data = $c->model('MyApp::MyData')->search('...');
		$c->cache->set( 'data', $data );
		}

	$c->response->body($data);
}

1;

