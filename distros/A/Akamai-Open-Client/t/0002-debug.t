use Test::More;

BEGIN {
    use_ok('Akamai::Open::Debug');
}
require_ok('Akamai::Open::Debug');

my $log_conf = q/
            log4perl.category.Akamai.Open.Debug   = DEBUG, Screen
            log4perl.appender.Screen              = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr       = 1
            log4perl.appender.Screen.layout       = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern = %p %m
        /;

my $debug = Akamai::Open::Debug->initialize(config => $log_conf);
my $clone = Akamai::Open::Debug->instance();
my @array = (1, 2, 'a', 'b');

# object tests
isa_ok($debug,      'Akamai::Open::Debug');
isa_ok($clone,      'Akamai::Open::Debug');

# functional tests
is($debug, $clone,                  'test for a singleton object');
ok($debug->logger->debug('foo'),    'print a message of priority DEBUG');
ok($debug->logger->info('foo'),     'print a message of priority INFO');
ok($debug->logger->warn('foo'),     'print a message of priority WARN');
ok($debug->logger->error('foo'),    'print a message of priority ERROR');
ok($debug->logger->fatal('foo'),    'print a message of priority FATAL');

done_testing;
