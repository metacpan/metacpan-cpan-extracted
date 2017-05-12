<?php
/**
 * This PHP code demonstrates how to ask Camel-PKI to revoke a 
 * certificate using JSON-RPC. You'll find the documentation of
 * the JSON structure to send in 
 * App::CamelPKI::Controller::CA::Gabarit::VPN.
 *
 * Of course, the code is equally simple for all the other certificate
 * template families.
 */

require_once "jsonrpc.inc.php";


$testhost1 = "foo.exemple.com";
$testhost2 = "bar.exemple.com";

$req1 = Array("template" => "VPN1",
              "dns"      => $testhost1);
$req2 = Array("template" => "VPN1",
              "dns"      => $testhost2);

$allreqs = Array("requests" => Array($req1, $req2));


$response = jsonrpc("/ca/template/vpn/certifyJSON", $allreqs);


$req = Array( "dns" => $testhost1);

$response = jsonrpc("/ca/template/vpn/revokeJSON", $req);
print "ok";
?>
