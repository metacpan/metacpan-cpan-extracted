package MHFS::EventLoop::Poll v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';

my $selbackend;
BEGIN {
my @backends = ("'MHFS::EventLoop::Poll::Linux'",
                "'MHFS::EventLoop::Poll::Base'");

foreach my $backend (@backends) {
    if(eval "use parent $backend; 1;") {
        $selbackend = $backend;
        last;
    }
}
$selbackend or die("Failed to load MHFS::EventLoop::Poll backend");
}

sub backend {
    return $selbackend;
}

1;
