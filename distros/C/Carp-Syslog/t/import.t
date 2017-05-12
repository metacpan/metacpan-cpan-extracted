#!perl

use strict;
use Test::More;

use lib 't/lib';
use Mock::Syslog;

BEGIN {
    # Default settings.
    use Carp::Syslog;

    is $Mock::Syslog::IDENT, $0;
    is $Mock::Syslog::LOGOPT, '';
    is $Mock::Syslog::FACILITY, 'user';
}

BEGIN {
    # Simple override of facility.
    use Carp::Syslog 'local0';

    is $Mock::Syslog::IDENT, $0;
    is $Mock::Syslog::LOGOPT, '';
    is $Mock::Syslog::FACILITY, 'local0';
}

BEGIN {
    # Override all of the options.
    use Carp::Syslog { ident => 'myself', logopt => 'pid', facility => 'local1' };

    is $Mock::Syslog::IDENT, 'myself';
    is $Mock::Syslog::LOGOPT, 'pid';
    is $Mock::Syslog::FACILITY, 'local1';
}

done_testing;
