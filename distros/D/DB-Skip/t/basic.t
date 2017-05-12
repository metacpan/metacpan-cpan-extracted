use strict;
use warnings;

use Test::InDistDir;

use Capture::Tiny 0.13 'capture';

use Test::More;

my @includes = map { "-I$_" } @INC;
my ( $out, $err, $res ) = capture {
    system( $^X, @includes, "-It/lib", "-d:DBSkipCaller", "t/bin/example.pl" );
};

unlike $out, qr/main::skip/, "main::skip is skipped";
unlike $out, qr/Marp::skip/, "Marp::skip is skipped";
unlike $out, qr/Moop::skip/, "Moop::skip is skipped";
like $out, qr/Meep::debug/, "Meep::debug is not skipped";
like $out, qr/main::debug/, "main::debug is not skipped";
my( @matches )= ($out =~ /(::)/g);
is @matches, 2, "only 2 subs are unskipped";
is $err, "", "no errors";
is $res, 0, "script didn't crash";

done_testing;
