use strict;
use warnings;
use CGI::ExceptionManager;
use Test::More tests => 2;

{
    my $res = CGI::ExceptionManager->run(
        callback => sub {
            "OK";
        },
        powered_by => 'menta',
    );
    is $res, "OK";
}

{
    my $res = CGI::ExceptionManager->run(
        callback => sub {
            CGI::ExceptionManager::detach("OK");
        },
        powered_by => 'menta',
    );
    is $res, "OK", 'detach, scalar';
}

