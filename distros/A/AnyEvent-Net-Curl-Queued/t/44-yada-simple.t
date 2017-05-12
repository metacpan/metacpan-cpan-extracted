#!perl
use lib qw(inc);
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use Test::HTTP::AnyEvent::Server;
use YADA;

my $server = Test::HTTP::AnyEvent::Server->new;

my $q = YADA->new(allow_dups => 1, http_response => 1, common_opts => { encoding => 'bzip2' });
for my $i (1 .. 10) {
    for my $method (qw(append prepend)) {
        $q->$method(
            $server->uri . "repeat/$i/$method",
            sub {
                my ($self, $result) = @_;
                like(${$self->data}, qr{^(?:$method){$i}$}x, 'got data: ' . ${$self->data});
            }
        );
    }
}

my @urls = ($server->uri . 'echo/head') x 2;
$urls[-1] =~ s{\b127\.0\.0\.1\b}{localhost}x;
my @opts = (referer => 'http://www.cpan.org/', ipresolve => Net::Curl::Easy::CURL_IPRESOLVE_V4);
my $on_finish = sub {
    my ($self, $r) = @_;
    isa_ok($self->response, qw(HTTP::Response));
    like($self->response->decoded_content, qr{\bReferer\s*:\s*\Q$opts[1]\E}isx, 'referer');
};

$q->append(
    @urls,
    sub { $_[0]->setopt(@opts) }, # on_init placeholder
    $on_finish,
);

$q->append(
    [ @urls ],
    { opts => { @opts } },
    $on_finish,
);

$q->append(
    URI->new($_) => $on_finish,
    { opts => { @opts } },
) for @urls;

$q->append(
    \@urls => {
        opts            => { @opts },
        on_finish       => $on_finish,
    }
);

$q->wait;

done_testing(20 + 4 * (scalar @urls) * 2);
