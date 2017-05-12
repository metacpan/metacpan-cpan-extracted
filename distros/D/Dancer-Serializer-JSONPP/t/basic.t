use strict;
use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestApp;
use Dancer::Test;

# replace with the actual test
ok 1;

my $res = dancer_response('GET' => '/');
# diag(Dumper(\$res)); use Data::Dumper;

is $res->header('Content-Type'), 'application/json';
like $res->content, qr/\{\s*[\'\"]1[\'\"]\s*\:\s*4\s*\,\s*[\'\"]a[\'\"]\s*\:\s*1\s*\,\s*[\'\"]aa[\'\"]\s*\:\s*3\s*\,\s*[\'\"]b[\'\"]\s*\:\s*2/s;

done_testing;
