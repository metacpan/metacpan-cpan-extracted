use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use CGI::XMLApplication;
$loaded = 1;
ok(1);

my $p = CGI::XMLApplication->new('');
ok($p);
