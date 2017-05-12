#!perl

use Test::More tests => 3;

BEGIN {
    use_ok('Catalyst::Controller::WrapCGI');
    use_ok('Catalyst::Controller::CGIBin');
    use_ok('CatalystX::GlobalContext');
}

diag("Testing Catalyst::Controller::WrapCGI, Perl $], $^X");
