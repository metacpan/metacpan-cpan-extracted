#/usr/bin/env perl -T

use lib qw(inc);
use Test::More tests => 1;

use_ok('Catalyst::Plugin::Upload::Audio::File');

diag(
"Testing Catalyst::Plugin::Upload::Audio::File $Catalyst::Plugin::Upload::Audio::File::VERSION, Perl $], $^X"
);
