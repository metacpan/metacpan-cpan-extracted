<?php

/**
 * This PHP code demonstrates how to ask Camel-PKI to generate two
 * certificates using JSON-RPC. You'll find the documentation of
 * the JSON structure to send in 
 * App::CamelPKI::Controller::CA::Gabarit::VPN.
 *
 * Of course, the code is equally simple for all the other certificate
 * template families.
 */

require_once "jsonrpc.inc.php";

$req1 = Array("template" => "VPN1",
              "dns"      => "bar.example.com");
$req2 = Array("template" => "VPN1",
              "dns"      => "bar.example.com");
$req3 = Array("template" => "VPN1",
              "dns"      => "bar.example.com");
$req4 = Array("template" => "VPN1",
              "dns"      => "bar.example.com");

$allreqs = Array("requests" => Array($req1, $req2, $req3, $req4));


$response = jsonrpc("/ca/template/vpn/certifyJSON", $allreqs);

print_r($response);

?>
