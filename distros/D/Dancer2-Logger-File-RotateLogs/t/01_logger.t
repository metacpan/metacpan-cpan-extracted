
use strict;
use warnings;
use Test::More;
use Dancer2;


#set engines => {
#    logger => {
#        'File::RotateLogs' => {
#            logfile  => 'test.%Y%m%d%H',
#            linkname => 'test',
#            rotationtime => '86400',
#            maxage       => '86400 * 7',
#        }   
#    }   
#};

set logger  => 'File::RotateLogs';

my $log_engine = engine('logger');

isa_ok($log_engine, 'Dancer2::Logger::File::RotateLogs');
can_ok($log_engine, 'debug');
can_ok($log_engine, 'info');
can_ok($log_engine, 'warning');
can_ok($log_engine, 'error');


done_testing;
