# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More import => ['!pass'];
BEGIN {
   eval 'use Log::Log4perl::Tiny qw( :subs )';
   plan skip_all => 'Log::Log4perl::Tiny required for basic testing' if $@;
}
# plan 'no_plan';
plan tests => 21;

use Dancer ':syntax';
use Dancer::Test;

my $logger = get_logger();
$logger->layout('[%p] %m%n');
$logger->level('TRACE');

ok(open(my $fh, '>', \my $collector), "open()");
$logger->fh($fh);

setting log => 'core';
setting log4perl => {
   tiny   => 1,
   no_init => 1,
};
setting logger => 'log4perl';

# Set up routes
ok(get('/debug' => sub { DEBUG 'debug-whatever'; return 'whatever' }),
   'route addition');
ok(get('/core' => sub { Dancer::Logger::core 'core-whatever'; return 'whatever' }),
   'route addition');
ok(get('/info' => sub { INFO 'info-whatever'; return 'whatever' }),
   'route addition');
ok(get('/warning' => sub { WARN 'warning-whatever'; return 'whatever' }),
   'route addition');
ok(get('/error' => sub { ERROR 'error-whatever'; return 'whatever' }),
   'route addition');

# Verify routes are working and generate log output
for my $level (qw( debug core info warning error )) {
   my $route = "/$level";
   route_exists [GET => $route];
   response_content_is([GET => $route], 'whatever');
   like($collector, qr{$level-whatever}, 'log line is correct');
}

# Verify that core messages are filtered when Dancer's 'log' setting isn't 'core'
# setting log => 'debug';
# $collector="";
# response_content_is([GET => "/core"], 'whatever');
# unlike($collector, qr{core-whatever}, 'log line is correct');
