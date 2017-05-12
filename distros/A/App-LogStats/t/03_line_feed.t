use strict;
use warnings;
use Test::More;
use t::AppLogStatsTest qw/test_stats/;

use App::LogStats;

t::AppLogStatsTest::set_interactive();

{
    my $expect = join('',
        "\r",
        " --------- ------ \r",
        "               1  \r",
        " --------- ------ \r",
        "  count       10  \r",
        "  sum         55  \r",
        " --------- ------ \r",
        "  average   5.50  \r",
        " --------- ------ \r",
        "  max         10  \r",
        "  min          1  \r",
        "  range        9  \r",
        " --------- ------ \r",
    );

    test_stats($expect, '--cr', 'share/log1');
}

{
    my $expect = join('',
        "\r\n",
        " --------- ------ \r\n",
        "               1  \r\n",
        " --------- ------ \r\n",
        "  count       10  \r\n",
        "  sum         55  \r\n",
        " --------- ------ \r\n",
        "  average   5.50  \r\n",
        " --------- ------ \r\n",
        "  max         10  \r\n",
        "  min          1  \r\n",
        "  range        9  \r\n",
        " --------- ------ \r\n",
    );

    test_stats($expect, '--crlf', 'share/log1');
}

done_testing;