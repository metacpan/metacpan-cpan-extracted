use strict;
use warnings;
use CGI::ExceptionManager;
use Test::More tests => 1;

CGI::ExceptionManager->run(
    callback => sub {
        ok 1, "should reach here";
        CGI::ExceptionManager->detach();
        ok 0, "should not reach here";
    },
    powered_by => 'menta',
);

