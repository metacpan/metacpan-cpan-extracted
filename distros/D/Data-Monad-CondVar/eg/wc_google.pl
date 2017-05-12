use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent::HTTP;
use AnyEvent::Util;

my $url = "http://www.google.com";
print as_cv { http_get $url, $_[0] }->flat_map(sub {
    my $html = shift;

    my $ret;
    AnyEvent::Util::run_cmd(
        [qw/wc /], '<' => \$html, '>' => \$ret,
    )->map(sub { $ret });
})->recv, "\n";
