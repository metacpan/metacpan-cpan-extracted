use Test::Base -Base;

#use Smart::Comments;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $package = 'CGI::Cookie::XS';

sub test ($) {
    $package = shift;
}

sub run_tests () {
    eval "use $package;";
    if ($@) { die $@ }
    for my $block (blocks()) {
        my $name = $block->name;
        my $cookie = $block->cookie;
        die "$name - No --- cookie specified" if !defined $cookie;
        chomp $cookie;
        ### $cookie
        my $res = $package->parse($cookie);
        if ($package eq 'CGI::Cookie') {
            for my $key (keys %$res) {
                $res->{$key} = $res->{$key}->{value};
            }
        }
        my $out = $block->out;
        die "$name - No --- out specified" if !defined $out;
        is Dumper($res), $out, "$name - out okay";
    }
}

1;
