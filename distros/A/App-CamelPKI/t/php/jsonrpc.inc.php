<?php

/**
 * jsonrpc.inc.php : Library to provide JSON-RPC calls
 *
 * Developped for interfaces of JSON-RPC in Camel-PKI. This is a sample
 * client code.
 *
 * In case of error, we simply call the die() php function, as the error
 * message will appear as is. The programmer could wish to adapt this 
 * mecanism according to his use.
 */

/* 
 * Get tests parameters (hostname, port number, key and client's SSL
 * certificate)
 */
require_once "tmp/camel_pki_conf.inc.php";

/**
 * 
 * Send the data structure $structure (which is an Array) to the server
 * via a JSON-RPC's request to the URL $uri, and then send back
 * the return code of the server.
 */
function jsonrpc($uri, $structure = null) {
    $ch = camel_pki_curl_prepare($uri);

    /* On vérifie que le certificat du serveur est valide : */
    $cabundle = camel_pki_ca_bundle_filename();
    curl_setopt($ch, CURLOPT_CAINFO, $cabundle);
    $admincert = camel_pki_admin_certificate_filename();
    $adminkey = camel_pki_admin_key_filename();
    curl_setopt($ch, CURLOPT_SSLCERT, $admincert);
    curl_setopt($ch, CURLOPT_SSLCERTTYPE, "PEM");
    curl_setopt($ch, CURLOPT_SSLKEY, $adminkey);
    curl_setopt($ch, CURLOPT_SSLKEYTYPE, "PEM");

    $headers = Array("Accept: application/json");
    if (! is_null($structure)) {
        array_push($headers, "Content-Type: application/json");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($structure));
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    $reponse_serveur = curl_exec($ch);
    if (! $reponse_serveur) { die(curl_error($ch)); }
    $http_server_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    if ($http_server_code != 200) {
    	die("Code retour HTTP est différent de 200");
    }
    curl_close($ch);
    $retval = json_decode($reponse_serveur, true);

    if (is_null($retval)) {
        /* 
         * Error on decode : The message doesn't see to be JSON,
         * it is probably an error message.
		 */
        die($reponse_serveur);
    }
    return $retval;
}

/**
 * 
 * Configure a curl object to go to $uri and send it back.
 * It is in natural state (not configured with keys, a POST, an accept header
 * ) and the caller will have to had all information he wishes.
 * Same way, the caller have to call curl_close() on the requested object.
 */
function camel_pki_curl_prepare($uri) {
    /* Hostname is necessary. curl use it to check the server.
     * He have to be equal in the CN of the certificate of the web server,
     * which is found of `hostname` during the ley ceremony. */
    $host = camel_pki_https_host();
    $port = camel_pki_https_port();
    $url = "https://$host:$port$uri";
    $retval = curl_init($url);
    curl_setopt($retval, CURLOPT_RETURNTRANSFER, true);

    return $retval;
}

/**
 * Create a file containing the certification chain, downloading it
 * from the server. The erver's certificate isn't chacked in this case.
 * 
 * In a real implementation, he would be more prudent to do this one
 * time, after installing JSON client.
 */
function camel_pki_ca_bundle_filename() {
    $retval = "t/php/tmp/camel-pki-ca-bundle.crt";
    $ch = camel_pki_curl_prepare("/ca/certificate_chain_pem");
    /* Pas de vérification du certificat serveur : */
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $bundle = curl_exec($ch);
    if (! $bundle) { die(curl_error($ch)); }
    file_put_contents($retval, $bundle);
    curl_close($ch);
    return $retval;
}

/**
 * Create a file containing the certificate and the key 
 * of the administrator, from configuration, and sends back
 * the file's path.
 */
function camel_pki_admin_key_filename() {
    $retval = "t/php/tmp/camel-pki-admin-key.pem";
    file_put_contents($retval, camel_pki_key_pem());
    return $retval;
}

function camel_pki_admin_certificate_filename() {
    $retval = "t/php/tmp/camel-pki-admin-cert.pem";
    file_put_contents($retval, camel_pki_certificate_pem());
    return $retval;
}
?>
