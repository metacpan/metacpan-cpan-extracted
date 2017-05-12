use strict;
use warnings;
use Test::More skip_all => 'deprecated, use Dancer::Plugin::Auth::RBAC instead';
__END__
use Test::Exception;

BEGIN { 
	use_ok 'Dancer', ':syntax';
	use_ok 'Dancer::Plugin::Authorize'; 
}
