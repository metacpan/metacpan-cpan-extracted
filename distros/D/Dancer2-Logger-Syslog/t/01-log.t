use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Warnings qw/warnings :no_end_test/;
use lib 't/lib';

use Dancer2::Logger::Syslog;

my $l = Dancer2::Logger::Syslog->new( app_name => 'test', log_level => 'core' );

ok defined($l), 'Dancer2::Logger::Syslog object';
isa_ok $l, 'Dancer2::Logger::Syslog';
can_ok $l, qw(log debug warning error);

my @warnings;

@warnings = warnings { $l->log( debug => "Perl Dancer test message 1/5" ) };

cmp_deeply \@warnings,
  superbagof( re(qr{debug.+test.+debug.+Perl Dancer test message 1/5}) ),
  "log method sending to debug is good"
  or diag explain @warnings;

@warnings = warnings { $l->log( core => "Perl Dancer test message core 2/5" ) };

cmp_deeply \@warnings,
  superbagof( re(qr{debug.+test.+debug.+Perl Dancer test message core 2/5}) ),
  "log method sending to core is good"
  or diag explain @warnings;

@warnings = warnings { $l->debug("Perl Dancer test message 3/5") };

cmp_deeply \@warnings,
  superbagof( re(qr{debug.+test.+debug.+Perl Dancer test message 3/5}) ),
  "debug method is good"
  or diag explain @warnings;

@warnings = warnings { $l->warning("Perl Dancer test message 4/5") };

cmp_deeply \@warnings,
  superbagof( re(qr{warning.+test.+warning.+Perl Dancer test message 4/5}) ),
  "warning method is good"
  or diag explain @warnings;

@warnings = warnings { $l->error("Perl Dancer test message 5/5") };

cmp_deeply \@warnings,
  superbagof( re(qr{err.+test.+err.+Perl Dancer test message 5/5}) ),
  "error method is good"
  or diag explain @warnings;

done_testing;
