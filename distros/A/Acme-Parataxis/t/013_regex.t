use v5.40;
use Test2::V1 -ipP;
use blib;
use Acme::Parataxis;
#
Acme::Parataxis::run sub {
    my $fiber = Acme::Parataxis->spawn(
        sub {
            my $val = 'hello world';
            Acme::Parataxis->yield('yielding');
            return 'matched' if $val =~ /hello/;
            return 'not matched';
        }
    );
    my $res = $fiber->await();
    is $res, 'matched', 'Regex match after yield works';
    Acme::Parataxis::stop();
};
Acme::Parataxis::run(
    sub {
        Acme::Parataxis->spawn(
            sub {
                my $str = 'hello world';
                ok $str =~ /hello/, 'Regex match in fiber';
            }
        )->await;
    }
);
#
done_testing();
