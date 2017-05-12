<?php

#       #       #       #
#
# ck_admin.php
#
# Local setup for ck_admin.inc.
# Customize this file to your environment!
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/codekit
#

require_once('ck_connect.inc');
$dbh = ck_connect();

require_once("CodeKit.php");
$ckh = new CodeKit($dbh);

# Set security here.
$perm_add = 1;
$perm_upd = 1;
$perm_del = 1;                  # Set to 0 for most people!

# If you are keeping session ids in your urls.
function cka_sess_url($url) {
    return $url;                # No session id in url.
#   global $sess;               # Session manager.
#   return $sess->url($url);    # Add session id to url.
}

#       #       #       #
# Do the actual work!
#
require_once("ck_admin_main.inc");
cka_admin_main();

?>
