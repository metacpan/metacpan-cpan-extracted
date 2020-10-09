#!perl

use 5.010;
use strict;
use warnings;

use Config;

use Test2::V0;
use Test::Alien;

use Alien::Plotly::Kaleido;

alien_ok 'Alien::Plotly::Kaleido';

my $install_type = Alien::Plotly::Kaleido->install_type;
diag("install type: $install_type");

if ( $install_type eq 'share' ) {
    diag( "bin_dir : " . Alien::Plotly::Kaleido->bin_dir );
    $ENV{PATH} = join(
        $Config{path_sep},
        Alien::Plotly::Kaleido->bin_dir,
        $ENV{PATH} // ''
    );
}

my $version = Alien::Plotly::Kaleido->detect_kaleido_version;
ok($version, 'detect_kaleido_version');

done_testing;
