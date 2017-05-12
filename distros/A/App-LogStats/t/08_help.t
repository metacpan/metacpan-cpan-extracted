use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::AppLogStatsTest;

t::AppLogStatsTest::set_interactive();

use Pod::Usage;
{
    # mock
    no warnings 'redefine'; ## no critic
    *Pod::Usage::pod2usage = sub {
        die "called pod2usage";
    };
}

{
    my $stats = App::LogStats->new;
    throws_ok {
        $stats->run('--help');
    } qr/^called pod2usage/, 'help';
}

done_testing;
