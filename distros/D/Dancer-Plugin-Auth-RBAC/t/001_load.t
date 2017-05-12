use strict;
use warnings;
use Test::More tests => 2, import => ['!pass'];

BEGIN { 
	use_ok 'Dancer', ':syntax';
	use_ok 'Dancer::Plugin::Auth::RBAC'; 
}
