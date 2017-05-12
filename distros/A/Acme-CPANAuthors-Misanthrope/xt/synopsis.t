use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 2;

my $module = "$FindBin::Bin/../lib/Acme/CPANAuthors/Misanthrope.pm";
open my $fh, "<", $module
    or die "Couldn't open '$module' to read: $!";

my $synopsis = "";
while ( <$fh> ) {
    if ( /=head1 SYNOPSIS/ .. /=head\d (?!S)/
         and not /^=/ ) {
        $synopsis .= $_;
    }
}
close $fh;

ok( $synopsis,
    "Got code out of the SYNOPSIS space to evaluate" );

diag( $synopsis ) if $ENV{TEST_VERBOSE};

my $ok = eval "$synopsis; 1";

ok( $ok,  "Synopsis eval'd" );

diag( $@ . "\n" . $synopsis ) if $@ and $ENV{TEST_VERBOSE};
