package Apache2::Controller::Test::UnitConf;

use strict;
use warnings FATAL => 'all';

use Readonly;
use FindBin;

use base qw( Exporter );

our @EXPORT = qw(
    $L4P_UNIT_CONF
);

Readonly our $L4P_UNIT_CONF => qq{
log4perl.rootLogger=DEBUG, TestErr
log4perl.appender.TestErr=Log::Log4perl::Appender::File
log4perl.appender.TestErr.filename=$FindBin::Bin/logs/error_log
log4perl.appender.TestErr.layout=PatternLayout
log4perl.appender.TestErr.layout.ConversionPattern=----------------------------------%n%p %M() %L:%n%m%n
};

1;
