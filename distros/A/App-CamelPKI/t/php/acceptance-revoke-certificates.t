#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

acceptance-revoke-certificates.t - Launch acceptance-revoke-certificates.php

=head1 DESCRIPTION

C<acceptance-revoke-certificates.php> generates certificates using a
JSON-RPC call, and revoke them, just like
C<../acceptance-revoke-certificates.t> does in Perl. This Perl script
checks that the PHP code actually works.

=cut

use Test::More;
use App::CamelPKI;
use App::CamelPKI::Test qw(create_camel_pki_conf_php run_php_script);
use File::Slurp;


my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational 
	&& App::CamelPKI::Test->is_php_cli_present) {
	plan tests => 2;
} else {
	plan skip_all => "Apache (and/or mod_perl) or php-cli is not insalled or Key Ceremnoy has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

create_camel_pki_conf_php();
my $hello = run_php_script("acceptance-revoke-certificates.php");
like($hello, qr/ok/m, "Server accepted our request !");
unlike($hello, qr/require_once/m,
       "not interested in the PHP source code :-)");