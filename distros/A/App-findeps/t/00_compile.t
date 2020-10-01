use strict;
use warnings;

use FastGlob qw(glob);
use Test::More 0.98 tests => 1;

use_ok $_ for qw(App::findeps);

my @files = &glob('t/scripts/00/*.pl');
my $map   = App::findeps::scan( files => \@files );
my @list  = ();
foreach my $key ( sort keys %$map ) {
    my $version = $map->{$key};
    my $dist    = App::findeps::_name($key);
    $dist .= "~$version" if length $version;
    push @list, $dist;
}

for (@list) {
    is $_, 'Dummy', "succeed to exclude ./lib/";
}

if ( eval 'require Pod::Markdown' ) {
    qx'pod2markdown script/findeps >| findeps.md';
}

done_testing;
