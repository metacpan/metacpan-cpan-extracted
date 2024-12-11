# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 3;
    use_ok('Test::Pound');
}

my $pnd = new Test::Pound;
isa_ok($pnd, 'Config::Proxy::Impl::pound');

my $cfg = <<'EOT'
Service
 Not Host "localhost"
End
Service
 Not Not Host "localhost"
End
Service
 Not Match
  Host "localhost"
 End
End
Service
 Not Not Match
  Host "localhost"
 End
End
EOT
;

$pnd->write(\my $s, indent => 1);
is($s, $cfg);

__DATA__
Service
	Not Host "localhost"
End
Service
	Not Not Host "localhost"
End
Service
	Not Match
		Host "localhost"
	End
End
Service
	Not Not Match
		Host "localhost"
	End
End
