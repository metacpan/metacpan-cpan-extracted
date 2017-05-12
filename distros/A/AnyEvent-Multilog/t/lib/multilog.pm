package t::lib::multilog;
use strict;
use warnings;
use Test::Builder;
use File::Which qw(which);
use Sub::Exporter -setup => {
    exports => [ qw/check_multilog/ ],
};

sub check_multilog {
    my $talkative = shift;
    my $tb = Test::Builder->new;
    my $multilog = $ENV{MULTILOG} || which('multilog');
    chomp $multilog;
    $tb->plan(skip_all => 'no multilog found')
        unless -e $multilog && -x $multilog;
    $tb->diag("multilog found at $multilog") if $talkative;
    return $multilog;
}

1;
