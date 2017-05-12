<?php

#       #       #       #
#
# bk_admin.php
#
# Local setup for bk_admin_main.inc.
# Customize this file to your environment!
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#

require_once('bk_connect.inc');
$dbh = bk_connect();

require_once("BabelKit.php");
$bkh = new BabelKit($dbh);

# Set security here.
$perm_add = 1;
$perm_upd = 1;
$perm_del = 1;                  # Set to 0 for most people!

# If you are keeping session ids in your urls.
function bka_sess_url($url) {
    return $url;                # No session id in url.
#   global $sess;               # Session manager.
#   return $sess->url($url);    # Add session id to url.
}

#       #       #       #
# Do the actual work!
#
require_once("bk_admin_main.inc");
bka_admin_main();

?>
