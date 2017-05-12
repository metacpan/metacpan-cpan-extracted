use Test::More;
use strict;
use warnings;

use Dancer::ModuleLoader;
use Test::Output;

plan tests => 9;

use_ok 'Dancer::Logger::LogHandler';

my $l = Dancer::Logger::LogHandler->new();

ok defined($l), 'Dancer::Logger::LogHandler object';
isa_ok $l, 'Dancer::Logger::LogHandler';
can_ok $l, qw(init _log debug warning error);

my $format = Dancer::Logger::LogHandler::_format('test');
like $format, qr/test in/, "format looks good";

# default logs are sent to STDERR

stderr_like(
    sub { $l->_log(debug => "dummy test") }, 
    qr/\[DEBUG\] dummy test in t\/01-log\.t/, 
    '_log works');

stderr_like(
    sub { $l->debug("Perl Dancer test message 2/4") }, 
    qr/\[DEBUG\] Perl Dancer test message 2\/4 in/,
    "debug works");

stderr_like(
    sub { $l->warning("Perl Dancer test message 3/4") }, 
    qr/\[WARNING\] Perl Dancer test message 3\/4 in/,
    "warning works");

stderr_like(
    sub { $l->error("Perl Dancer test message 4/4") },
    qr/\[ERROR\] Perl Dancer test message 4\/4 in/,
    "error works");

