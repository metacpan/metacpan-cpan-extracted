use strict;
use warnings;

use DB::Skip pkgs => [ qw( Marp ), qr/^Mo/ ], subs => [qw( main::skip )];

my $meep = skip();
print $meep;
$meep = Marp::skip();
print $meep;
$meep = Moop::skip();
print $meep;
$meep = debug();
print $meep;
exit;

sub skip {
    return 1;
}

sub debug {
    return 4;
}

package Marp;

sub skip {
    return 2;
}

package Moop;

sub skip {
    Meep::debug();
    return 3;
}

package Meep;

sub debug {
    print 5;
}
