#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

acceptance-issue-certificates.t - Launch acceptance-issue-certificates.php

=head1 DESCRIPTION

C<acceptance-issue-certificates.php> generates certificates using a
JSON-RPC call, and print them to the standard output, just like
C<../acceptance-issue-certificates.t> does in Perl. This Perl script
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
my $hello = run_php_script("acceptance-issue-certificates.php");
unlike($hello, qr/require_once/,
       "not interested in the PHP source code :-)");

like($hello, qr/BEGIN CERTIFICATE/, "got a certificate in the answer !")
    or diag $webserver->tail_error_logfile;
