use strict;
use warnings;
use Test::More;
use t::AppYGParserTest qw/can_parse parse_fail/;

my $parser_class = 'App::YG::Apache::Error';
require_ok $parser_class;

note '----- OK -----';
can_parse(
    $parser_class,
    '[Sat Oct 06 17:34:17 2012] [notice] suEXEC mechanism enabled (wrapper: /usr/sbin/suexec)',
    [
        'Sat Oct 06 17:34:17 2012',
        'notice',
        '',
        'suEXEC mechanism enabled (wrapper: /usr/sbin/suexec)',
    ],
);
can_parse(
    $parser_class,
    '[Sat Oct 06 17:36:10 2012] [error] [client 123.220.65.13] File does not exist: /var/www/html/favicon.ico',
    [
        'Sat Oct 06 17:36:10 2012',
        'error',
        '123.220.65.13',
        'File does not exist: /var/www/html/favicon.ico',
    ],
);

note '----- NG -----';
parse_fail(
    $parser_class,
    'this is bad log!'
);
parse_fail(
    $parser_class,
    '[Sat Oct 06 17:36:03 2012] (notice) Digest: done'
);

done_testing;
