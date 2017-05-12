package MockApp;

use strict;
use warnings;

use base qw/Catalyst/;

use Catalyst::Log::Log4perl;

our %config = ( name => 'MockApp', home => './t/' );
sub config { \%config }

__PACKAGE__->log(
    Catalyst::Log::Log4perl->new( \<<CONF, override_cspecs => 1 ) );
log4perl.rootLogger=WARN, LOG
log4perl.appender.LOG=Log::Log4perl::Appender::String
log4perl.appender.LOG.layout=PatternLayout
log4perl.appender.LOG.layout.ConversionPattern=[%c] %m
CONF


__PACKAGE__->setup();

1;
