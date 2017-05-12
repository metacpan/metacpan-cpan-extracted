#	$Id: 01-basic.t 61 2014-05-23 09:40:55Z adam $

use strict;
use Test;
BEGIN { plan tests => 4 }

use Config::Trivial;

ok(1);
ok($Config::Trivial::VERSION, "0.81");

my $config = Config::Trivial->new;
ok(defined $config);
ok($config->isa('Config::Trivial'));

exit;
__END__
