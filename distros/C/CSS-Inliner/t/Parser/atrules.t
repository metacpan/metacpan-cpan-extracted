use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Inliner::Parser');

my $css = <<END;
\@charset "ISO-8859-15";
\@import url("/css/main.css") screen, projection;
\@import "local.css";
body {
  color: yellow;
  padding: 100px;
}
\@font-face {
  font-family: "Lucida";
  src: url("example.com");
}
\@media print (min-width: 8in), handheld and (orientation: landscape) {
  body {
    color: blue;
    padding: 1in;
  }
  \@page :left {
    margin: 1.5in;
  }
}
\@media not all and (min-width: 700px) and (orientation: landscape) {
  body {
    padding: 20px;
  }
  \@font-face {
    font-family: "Bitstream Vera Serif Bold";
    src: url("http://developer.mozilla.org/\@api/deki/files/2934/=VeraSeBd.ttf");
  }
}
\@media screen and (grid) and (max-width: 15em) {
  body {
    padding: 20em;
  }
  \@font-face {
    font-family: "Times";
    src: url("source.com");
  }
}
\@document url(http://www.w3.org/), url-prefix(http://www.w3.org/Style/), domain(mozilla.org), regexp("https:.*") {
  body {
    color: purple;
    padding: 50px;
  }
  \@font-face {
    font-family: "Lucida";
    src: url("example.com");
  }
}
END

my $simple = CSS::Inliner::Parser->new();

$simple->read({ css => $css });

my $ordered = $simple->write();

# check to make sure that our shuffled hashes matched up...
ok($css eq $ordered);
