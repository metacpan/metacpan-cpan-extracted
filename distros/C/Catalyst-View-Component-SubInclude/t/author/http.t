use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Catalyst::Test 'ESITest';

my $res_content = get('/http_cpan');
like $res_content, qr{CPAN Directory};
like $res_content, qr{WREIS};

$res_content = get('/http_github');
like $res_content, qr{GitHub};
like $res_content, qr{Wallace Reis};

done_testing;
