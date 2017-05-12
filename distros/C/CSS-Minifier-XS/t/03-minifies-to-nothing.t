use strict;
use warnings;
use Test::More tests => 2;
use CSS::Minifier::XS qw(minify);

my $results;

###############################################################################
# RT #36557: Nasty segfault on minifying comment-only css input
#
# Actually turns out to be that *anything* that minifies to "nothing" causes
# a segfault in Perl-5.8.  Perl-5.10 seems immune.
$results = minify( q{/* */} );
ok( !defined $results, "minified single block comment to nothing" );

$results = minify( q{} );
ok( !defined $results, "minified empty string to nothing" );
