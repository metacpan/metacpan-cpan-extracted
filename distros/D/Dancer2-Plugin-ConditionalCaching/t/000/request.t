#!perl -T

use lib '.';
use t::tests;

plan tests => 6;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::ConditionalCaching;

    get '/test' => sub {
        return caching(
            changed => param('changed'),
            expires => param('expires'),
            builder => sub {
                to_dumper( {@_} );
            },
        );
    };

}

my $PT = boot 'Webservice';

sub shortcut {
    my ( $testname, $changed, $expires, $force ) = @_;
    my $path = '/test?';
    $path .= '&changed=' . $changed if defined $changed;
    $path .= '&expires=' . $expires if defined $expires;
    dotest(
        $testname => 2,
        sub {
            my $R;
            my $t = measure(
                sub {
                    $R = request(
                        $PT,
                        GET => $path,
                        headers(
                            CacheControl => {
                                MaxAge   => 12345,
                                MinFresh => 67890,
                            }
                        ),
                    );
                }
            );
            ok $R->is_success;
            my $C = deserialize($R);
            is_deeply $C => {
                MaxAge   => 12345,
                MinFresh => 67890,
                Force    => $force,
            };
        }
    );
}

shortcut( 'none', undef, undef, 0 );

shortcut( 'changed now',             time,         undef, 0 );
shortcut( 'changed almost in range', time - 12344, undef, 0 );
shortcut( 'changed out of range',    time - 12346, undef, 1 );

shortcut( 'expires almost in range', undef, time + 67891, 0 );
shortcut( 'expires now',             undef, time,         1 );

done_testing();
