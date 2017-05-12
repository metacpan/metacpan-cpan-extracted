use strict;
use warnings;

use Test::More;

use Antispam::httpBL;

our $Response;

{
    package WWW::Honeypot::httpBL;

    no warnings 'redefine';

    sub _lookup {
        $_[0]->{_current_response} = $::Response;
    }
}

my $anti = Antispam::httpBL->new( access_key => 'foo' );

{
    $Response = '127.2.30.2';

    my $result = $anti->check_ip( ip => '1.1.1.1' );

    is(
        $result->score(), 4,
        'threat score of 30 becomes score of 4'
    );

    is_deeply(
        [ $result->details() ],
        [
            'IP address is an email harvester',
            'IP address threat score is 30',
            'Days since last activity for this IP: 2',
        ],
        'got expected details'
    );
}

{
    $Response = '127.0.125.6';

    my $result = $anti->check_ip( ip => '1.1.1.1' );

    is(
        $result->score(), 10,
        'threat score of 125 becomes score of 10'
    );

    is_deeply(
        [ $result->details() ],
        [
            'IP address is a comment spammer',
            'IP address is an email harvester',
            'IP address threat score is 125',
            'Days since last activity for this IP: 0',
        ],
        'got expected details'
    );
}

done_testing();
