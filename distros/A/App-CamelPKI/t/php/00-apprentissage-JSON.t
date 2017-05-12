#!/usr/bin/perl -w

use strict;

use App::CamelPKI::Test qw(run_php);
use Test::More;

App::CamelPKI::Test->is_php_cli_present;
if (App::CamelPKI::Test->is_php_cli_present){
	plan tests => 3;
} else {
	plan skip_all => "Missing php cli";
}

=pod

We are using PHP with JSON. For details, have a look at README
in the same directory and L<App::CamelPKI::Test/run_php>.

=cut

my $json = run_php(<<"SCRIPT");
<?php

print json_encode(Array("zoinx"));

?>
SCRIPT

like($json, qr/\[/m, "Bracket found !");
like($json, qr/zoinx/m, "zoinx found !");
unlike($json, qr/json_encode/m, "json_encode not found !");
