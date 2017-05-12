<?php
function doIncludes() {
    require_once "Auth/OpenID/Consumer.php";
    require_once "Auth/OpenID/FileStore.php";
    require_once "Auth/OpenID/PAPE.php";
    require_once "Auth/OpenID/AX.php";
}

doIncludes();

function abortSignin($message) {
   $location = $_GET[req] ? $_GET[req] : "/";
   if ( ! preg_match('/\?/', $location) ){
      $location .= '?';
   }
   $location .= "&aalogin=" . urlencode($message);
   error_log($message);
   error_log("going to $location");
   header("Location: $location");
   exit(0);
}

function &getStore() {
    $store_path = "/tmp/_php_consumer_store";

    if (!file_exists($store_path) &&
        !mkdir($store_path)) {
        print "Could not create the FileStore directory '$store_path'. ".
            " Please check the effective permissions.";
        exit(0);
    }

    return new Auth_OpenID_FileStore($store_path);
}

function &getConsumer() {
    /**
     * Create a consumer object using the store object created
     * earlier.
     */
    $store = getStore();
    $consumer =& new Auth_OpenID_Consumer($store);
    return $consumer;
}


function getScheme() {
    $scheme = 'http';
    if (isset($_SERVER['HTTPS']) and $_SERVER['HTTPS'] == 'on') {
        $scheme .= 's';
    }
    return $scheme;
}

function getReturnTo() {
    return sprintf("%s://%s:%s%s/check-auth.php?req=%s",
                   getScheme(), $_SERVER['SERVER_NAME'],
                   $_SERVER['SERVER_PORT'],
                   dirname($_SERVER['PHP_SELF']),
                   urlencode($_GET[req]));
}
?>
