use strict;
use warnings;
use AnyEvent;
use AnyEvent::HTTP;
use Async::Queue;

my $q = Async::Queue->new(concurrency => 3, worker => sub {
    my ($url, $callback) = @_;
    print STDERR "Start $url\n";
    http_get $url, sub {
        my ($data, $headers) = @_;
        print STDERR "End $url\n";
        $callback->($data);
    };
});

my @urls = (
    'http://www.debian.org/',
    'http://www.ubuntu.com/',
    'http://fedoraproject.org/',
    'http://www.opensuse.org/',
    'http://www.centos.org/',
    'http://www.slackware.com/',
    'http://www.gentoo.org/',
    'http://www.archlinux.org/',
    'http://trisquel.info/',
);

my %results = ();
my $cv = AnyEvent->condvar;
foreach my $url (@urls) {
    $cv->begin();
    $q->push($url, sub {
        my ($data) = @_;
        $results{$url} = $data;
        $cv->end();
    });
}
$cv->recv;

foreach my $key (keys %results) {
    print STDERR "$key: " . length($results{$key}) . "bytes\n";
}
