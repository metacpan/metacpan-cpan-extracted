package TestApp;

use strict;
use warnings;

use Catalyst qw(Authentication Authorization::Roles);

use base 'Catalyst';

__PACKAGE__->config(
	authentication => {
		default_realm => 'default',
		realms => {
			default => {
				credential => {
					class => 'Upstream::Headers'
				}
			}
		}
	}
);
__PACKAGE__->setup;

1;
