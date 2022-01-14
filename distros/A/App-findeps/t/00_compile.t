use strict;
use warnings;

use Test::More 0.98 tests => 2;

use_ok 'App::findeps';

my $map  = App::findeps::scan( files => ['t/scripts/00_basic.pl'] );
my @list = ();
foreach my $key ( sort keys %$map ) {
    my $version = $map->{$key};
    my $dist    = App::findeps::_name($key);
    $dist .= "~$version" if defined $version;
    push @list, $dist;
}

for (@list) {
    is $_, 'Acme::BadExample', "succeed to scan a file";
}

done_testing;
