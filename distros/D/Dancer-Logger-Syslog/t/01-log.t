use Test::More;
use strict;
use warnings;
use Dancer::ModuleLoader;

plan tests => 8;

use Dancer::Logger::Syslog;

use Dancer::Config 'setting';

setting appname => 'TestScript';
my $l = Dancer::Logger::Syslog->new;

ok defined($l), 'Dancer::Logger::Syslog object';
isa_ok $l, 'Dancer::Logger::Syslog';
can_ok $l, qw(init _log debug warning error);

SKIP: { 
    eval { $l->_log(debug => "dummy test") };
    skip "Need a SysLog connection to run last tests", 5 
        if $@ =~ /no connection to syslog available/;

    ok($l->_log(debug => "Perl Dancer test message 1/4"), "_log works");
    ok($l->_log(core => "Perl Dancer test message (core) 1/4"), 
        "_log works with 'core' level");
    ok($l->debug("Perl Dancer test message 2/4"), "debug works");
    ok($l->warning("Perl Dancer test message 3/4"), "warning works");
    ok($l->error("Perl Dancer test message 4/4"), "error works");
};
