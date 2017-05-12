use strict;
use lib '../lib';

use Test::More;
    
    pass('*' x 10);
    use_ok('CCCP::LiveMX');
    $CCCP::LiveMX::timeout = 2;
    
    can_ok('CCCP::LiveMX', 'check_host');
    my $lmx = CCCP::LiveMX->check_host('example.org');
    isa_ok($lmx, 'CCCP::LiveMX');
    can_ok($lmx, 'success');
    is($lmx->success, 0, 'example.org have not live mx');
    can_ok($lmx, 'error');
    is($lmx->error, 'Not found live ip for: example.org', 'valid error: "Not found live ip for: example.org"');
    
    pass('*' x 10);
    print "\n";
    done_testing;
