#!/usr/bin/env perl

use strict;
use warnings;

use Dancer2;
use Test::More tests => 1;

BEGIN { # would usually be in config.yml
    set plugins => {
        SPID => {qw(
            sp_entityid         https://www.prova.it/
            sp_key_file         sp.key
            sp_cert_file        sp.pem
            idp_metadata_dir    idp_metadata/
            login_endpoint      /spid-login
            logout_endpoint     /spid-logout
            sso_endpoint        /spid-sso
            slo_endpoint        /spid-slo
        )},
    };
    use_ok('Dancer2::Plugin::SPID');
}

__END__
