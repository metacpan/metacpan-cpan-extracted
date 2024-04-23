#!perl
use 5.38.0;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest( { exclude => [ qw< /.git /html > ]
             , filter  => [ qr/ignore/, qr/config.el/ , qr/.tar.gz$/] } );
