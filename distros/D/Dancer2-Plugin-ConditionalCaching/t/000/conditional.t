#!perl -T

use lib '.';
use t::tests;

#plan tests => 0;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::ConditionalCaching;

    any '/a' => sub {
        return caching(
            changed => time - 12345,
            etag    => 'abcdef',
            builder => sub { to_dumper( {@_} ) },
        );
    };

}

my $PT = boot 'Webservice';

dotest(
    'If-Match: *' => 1,
    sub {
        my $R;
        my $t = measure(
            sub {
                $R = request(
                    $PT,
                    POST => '/a',
                    headers(
                        IfMatch => '*',
                    ),
                );
            }
        );
        is $R->code => 200;
    }
);

dotest(
    'If-Match: "xxxxx"' => 1,
    sub {
        my $R;
        my $t = measure(
            sub {
                $R = request(
                    $PT,
                    POST => '/a',
                    headers(
                        IfMatch => '"xxxxx"',
                    ),
                );
            }
        );
        is $R->code => 412;
    }
);

dotest(
    'If-Unmodified-Since' => 1,
    sub {
        my $R;
        my $t = measure(
            sub {
                $R = request(
                    $PT,
                    POST => '/a',
                    headers(
                        IfUnmodifiedSince => time2str( time - 54321 ),
                    ),
                );
            }
        );
        is $R->code => 412;
    }
);

dotest(
    'If-None-Match: *' => 2,
    sub {
        my $R;
        my $t = measure(
            sub {
                $R = request(
                    $PT,
                    GET => '/a',
                    headers(
                        IfNoneMatch => '*',
                    ),
                );
            }
        );
        is $R->code => 304;
        $t = measure(
            sub {
                $R = request(
                    $PT,
                    POST => '/a',
                    headers(
                        IfNoneMatch => '*',
                    ),
                );
            }
        );
        is $R->code => 412;
    }
);

dotest(
    'If-None-Match: "abcdef"' => 2,
    sub {
        my $R;
        my $t = measure(
            sub {
                $R = request(
                    $PT,
                    GET => '/a',
                    headers(
                        IfNoneMatch => '"abcdef"',
                    ),
                );
            }
        );
        is $R->code => 304;
        $t = measure(
            sub {
                $R = request(
                    $PT,
                    POST => '/a',
                    headers(
                        IfNoneMatch => '"abcdef"',
                    ),
                );
            }
        );
        is $R->code => 412;
    }
);

dotest(
    'If-Modified-Since' => 1,
    sub {
        my $R;
        my $t = measure(
            sub {
                $R = request(
                    $PT,
                    GET => '/a',
                    headers(
                        IfModifiedSince => time2str( time - 4321 ),
                    ),
                );
            }
        );
        is $R->code => 304;
    }
);

done_testing();
