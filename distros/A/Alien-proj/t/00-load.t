use strict;
use warnings;
use Test::More;
use Test::Alien;

BEGIN {
    use_ok('Alien::proj') or BAIL_OUT('Failed to load Alien::proj');
}

alien_ok 'Alien::proj';

diag(
    sprintf(
        'Testing Alien::proj %s, Perl %s, %s',
        $Alien::proj::VERSION, $], $^X
    )
);


diag '';
diag 'Install type is ' . Alien::proj->install_type;
diag 'Aliens:';
my %alien_versions;
foreach my $alien (qw /Alien::sqlite Alien::libtiff Alien::curl/) {
    my $have = eval "require $alien";
    next if !$have;
    diag sprintf "%s: version: %s, install type: %s", $alien, $alien->version, $alien->install_type;
    $alien_versions{$alien} = $alien->version;
}


done_testing();

