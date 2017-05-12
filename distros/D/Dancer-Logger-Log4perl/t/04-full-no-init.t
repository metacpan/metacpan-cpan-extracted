# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More import => ['!pass'];
eval 'use Log::Log4perl';
plan skip_all => 'Log::Log4perl required for full testing' if $@;
# plan 'no_plan';
plan tests => 21;

my $logfile = __FILE__ . '.log';
my $config = "
log4perl.rootLogger              = ALL, LOG1
log4perl.appender.LOG1           = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename  = $logfile
log4perl.appender.LOG1.mode      = append
log4perl.appender.LOG1.layout    = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern = %d %p %m %n
";
Log::Log4perl::init(\$config);

use Dancer ':syntax';
use Dancer::Test;

setting log => 'core';
setting log4perl => {
   tiny   => 0,
   no_init => 1,
};
setting logger => 'log4perl';

# Set up routes
ok(get('/debug' => sub { debug 'debug-whatever'; return 'whatever' }),
   'route addition');
ok(get('/core' => sub { Dancer::Logger::core 'core-whatever'; return 'whatever' }),
   'route addition');
ok(get('/info' => sub { info 'info-whatever'; return 'whatever' }),
   'route addition');
ok(get('/warning' => sub { warning 'warning-whatever'; return 'whatever' }),
   'route addition');
ok(get('/error' => sub { error 'error-whatever'; return 'whatever' }),
   'route addition');

# Verify routes are working and generate log output
for my $level (qw( debug core info warning error )) {
   my $route = "/$level";
   route_exists [GET => $route];
   response_content_is([GET => $route], 'whatever');
}

my $collector = do {
   local (@ARGV, $/) = ($logfile);
   <>;
};

# Verify log messages were all logged
for my $level (qw( debug core info warning error )) {
   like($collector, qr{$level-whatever}, 'log line is correct');
}

# Verify that core messages are filtered when Dancer's 'log' setting isn't 'core'
# setting log => 'debug';
# truncate($logfile,0);
# response_content_is([GET => "/core"], 'whatever');
# $collector = do {
#    local (@ARGV, $/) = ($logfile);
#    <>;
# };
# unlike($collector, qr{core-whatever}, 'log line is correct');

ok(unlink($logfile), 'unlinking log file');
