
package Apache2::Controller::Test::TestRun;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( Apache::TestRunPerl );

use Apache::TestConfig;
use Log::Log4perl qw(:easy);
use Apache2::Controller::Test::UnitConf qw( $L4P_UNIT_CONF );

# after starting the httpd, set up the logs
sub start {
    my ($self) = @_;

    $self->SUPER::start();

    Log::Log4perl->init(\$L4P_UNIT_CONF);
}

sub bug_report {
    my ($self) = @_;
    print <<EOI;
+-----------------------------------------------------------------------+
| Apache2::Controller - framework for Apache2 apps                      |
| Please file a bug report with CPAN RT:                                |
| http://rt.cpan.org/Public/Dist/Display.html?Name=Apache2-Controller   |
+-----------------------------------------------------------------------+
EOI
}

1;
