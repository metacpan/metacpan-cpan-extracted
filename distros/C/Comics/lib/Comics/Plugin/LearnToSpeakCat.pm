#! perl

use strict;
use warnings;

package Comics::Plugin::LearnToSpeakCat;

use parent qw(Comics::Fetcher::GoComics);

our $VERSION = "1.00";

our $name    = "Learn to Speak Cat";
our $url     = "http://www.gocomics.com/learn-to-speak-cat/";

# Important: Return the package name!
__PACKAGE__;
