#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

01-apprentissage-JSONRPC.t - Test to execute invocations of remote
procedure calls on Camel-PKI with PHP and JSON.

=head1 MÉCANISME

All the code is in the .php file which has nearly the same name
in the same directory. The current file is only here to automate tests.  

=cut

use Test::More;
use App::CamelPKI;
use App::CamelPKI::Test qw(create_camel_pki_conf_php run_php_script);
use File::Slurp;


my $webserver = App::CamelPKI->model("WebServer")->apache;
if ($webserver->is_installed_and_has_perl_support && $webserver->is_operational 
	&& App::CamelPKI::Test->is_php_cli_present) {
	plan tests => 1;
} else {
	plan skip_all => "Apache (and/or mod_perl) or php-cli is not insalled or Key Ceremony has not been done !";
}
$webserver->start(); END { $webserver->stop(); }
$webserver->tail_error_logfile();

create_camel_pki_conf_php();
my $hello = run_php_script("01-apprentissage-JSONRPC.php");
like($hello, qr/Hello, Jeremie Klein !/, "Wanted answer found !")
    or warn $webserver->tail_error_logfile;


