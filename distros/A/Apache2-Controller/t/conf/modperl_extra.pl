
#warn `pwd`;
#warn "@INC";

use strict; 
use warnings;
use English '-no_match_vars';
use YAML::Syck;

# warn "INC: (@INC)\n";

use Log::Log4perl qw(:easy);

my $loginit = q{
log4perl.rootLogger=DEBUG, Screen
log4perl.appender.Screen=Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout=PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=----------------------------------%n%p %M() %L:%n%m%n
};

Log::Log4perl->init(\$loginit);

1;

