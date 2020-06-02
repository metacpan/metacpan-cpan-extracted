use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::gdal') or BAIL_OUT('Failed to load Alien::gdal');
}

alien_ok 'Alien::gdal';

diag(
    sprintf(
        'Testing Alien::gdal %s, Perl %s, %s',
        $Alien::gdal::VERSION, $], $^X
    )
);

diag '';
diag 'Aliens:';
my %alien_versions;
foreach my $alien (qw /Alien::sqlite Alien::libtiff Alien::proj Alien::geos::af/) {
    my $have = eval "require $alien";
    next if !$have;
    diag sprintf "%s: version: %s, install type: %s", $alien, $alien->version, $alien->install_type;
    $alien_versions{$alien} = $alien->version;
}


done_testing();

