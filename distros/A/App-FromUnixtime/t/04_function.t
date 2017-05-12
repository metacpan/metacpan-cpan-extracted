use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/ capture /;

use App::FromUnixtime;

no warnings 'redefine';
*App::FromUnixtime::RC = sub { +{} };

{
    like from_unixtime(1419702037), qr/1419702037\([^\)]+\)/;
    like from_unixtime('date 1419702037'), qr/date 1419702037\([^\)]+\)/;
}

{
    my $replaced =  from_unixtime(<<"_TEXT_");
created_at 1419702037
updated_at 1419702037
_TEXT_
    like $replaced, qr/created_at 1419702037\([^\)]+\)/;
    like $replaced, qr/updated_at 1419702037\([^\)]+\)/;
}

{
    my $replaced = from_unixtime(
        'date 1419702037',
        '--start-bracket' => '[',
        '--end-bracket'   => ']',
    );

    like $replaced, qr/date 1419702037\[[^\]]+\]/;
}

done_testing;
