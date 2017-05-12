<?php

#       #       #       #
#
# ck_connect.inc
#
# Connect to the database.
# Customize this file to your environment!
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#

function ck_connect() {

    # Where is your database library located?

    $lib_type    = 'pear';     # pear | adodb | phplib 
    $pear_path   = '.:/usr/share/pear:/usr/lib/php';
    $adodb_path  = '.:/usr/local/lib/adodb';
    $phplib_path = '.:/usr/lib/phplib';

    # Customize this connection for your database:

    $db_type     = 'mysql';
    $host        = 'localhost';
    $database    = 'webbysoft';
    $user        = 'webbysoft';
    $password    = '124c41';

    if ($lib_type == 'pear') {

        ini_set( 'include_path', $pear_path );
        require_once('DB.php');

        $dbh = DB::connect("$db_type://$user:$password@$host/$database");
        if (DB::iserror($dbh)) die($dbh->getMessage());

    } elseif ($lib_type == 'adodb') {

        ini_set( 'include_path', $adodb_path );
        require_once('adodb.inc.php');

        $dbh = ADONewConnection($db_type);
        $dbh->Connect($host, $user, $password, $database);

    } elseif ($lib_type == 'phplib') {

        ini_set( 'include_path', $phplib_path );
        require_once("db_$db_type.inc");

        $dbh            = new DB_Sql;
        $dbh->Host      = $host;
        $dbh->Database  = $database;
        $dbh->User      = $user;
        $dbh->Password  = $password;

    }

    return $dbh;
}

?>
