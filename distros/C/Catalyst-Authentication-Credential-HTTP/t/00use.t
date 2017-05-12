use strict;
use warnings;
use Test::More;

use_ok 'Catalyst';
diag 'Catalyst ' . $Catalyst::VERSION;
use_ok 'Catalyst::Plugin::Authentication';
diag 'Catalyst::Plugin::Authentication ' . $Catalyst::Plugin::Authentication::VERSION;
use_ok 'Catalyst::Authentication::Credential::HTTP';
diag 'Catalyst::Authentication::Credential::HTTP ' . $Catalyst::Authentication::Credential::HTTP::VERSION;

done_testing;

