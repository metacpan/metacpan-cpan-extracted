#!perl -T

use strict;
use warnings;

use Test::More;

use_ok('App::CPAN::SBOM');

done_testing();

diag("App::CPAN::SBOM $App::CPAN::SBOM::VERSION, Perl $], $^X");
