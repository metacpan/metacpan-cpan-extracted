<?php

/**
 * This PHP code shows how to invoke an Camel-PKI service with JSON-RPC.
 * In this case, it is just a test service end the response is a Hello
 * World. The source code is available in lib/App/PKI/Test/Apprentissage.pm
 * in the function named json_helloworld.
 */

require_once "jsonrpc.inc.php";

$bonjourstruct =
  jsonrpc("/test/json_helloworld",
          Array("nom" => "Klein", "prenom" => "Jeremie"));

print $bonjourstruct["salutation"];

?>
