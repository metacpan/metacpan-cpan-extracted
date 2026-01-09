use strict;
use warnings;

use Test2::V0;

use Retry::Policy;
use EasyDNS::DDNS::HTTP;

{
    package Local::HTTPMock;
    use strict;
    use warnings;

    sub new {
        my ($class, %args) = @_;
        return bless {
            calls => 0,
            seq   => $args{seq} || [],
        }, $class;
    }

    sub calls { return $_[0]{calls} }

    sub request {
        my ($self, $method, $url, $opt) = @_;
        $self->{calls}++;

        my $i = $self->{calls} - 1;
        if (defined $self->{seq}[$i]) {
            return $self->{seq}[$i];
        }

        return { success => 1, status => 200, reason => 'OK', content => 'ok' };
    }
}

# Retry::Policy requires positive integers for delays; keep them tiny for tests.
my $rp = Retry::Policy->new(
    max_attempts  => 3,
    base_delay_ms => 1,
    max_delay_ms  => 1,
    jitter        => 'full',
);

# 1) network fail then success -> should retry and succeed
{
    my $mock = Local::HTTPMock->new(seq => [
        { success => 0, status => 599, reason => 'Internal', content => '' },
        { success => 1, status => 200, reason => 'OK', content => 'ok' },
    ]);

    my $h = EasyDNS::DDNS::HTTP->new(http => $mock, retry => $rp);

    my $res = $h->get('https://example.test/');
    is($mock->calls, 2, 'retried once after network/timeout failure');
    is($res->{status}, 200, 'success after retry');
}

# 2) 500 then 200 -> should retry and succeed
{
    my $mock = Local::HTTPMock->new(seq => [
        { success => 1, status => 500, reason => 'Oops', content => 'err' },
        { success => 1, status => 200, reason => 'OK',   content => 'ok' },
    ]);

    my $h = EasyDNS::DDNS::HTTP->new(http => $mock, retry => $rp);

    my $res = $h->get('https://example.test/');
    is($mock->calls, 2, 'retried once after 500');
    is($res->{status}, 200, 'success after retry');
}

done_testing;

