<?php

#       #       #       #
#
# ck_admin_main.inc
#
# CodeKit Universal Code Table Administration page.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/codekit
#

#       #       #       #
#
# Main dispatch logic.
#

function cka_admin_main() {
    global $ckh;        # Set in ck_admin.php:
    global $perm_add;
    global $perm_del;

    global $action;     # Set here:
    global $code_set;
    global $code_code;

    $getpost = $_POST ? '_POST' : '_GET';
    $action     = $GLOBALS[$getpost]['action'];
    $code_set   = $GLOBALS[$getpost]['code_set'];
    $code_code  = $GLOBALS[$getpost]['code_code'];

    cka_admin_header();

    if ($action == 'New') {
        cka_form_display();
    } elseif ($action == '' && $code_code <> '') {
        cka_form_display($code_code);
    } elseif ($action <> '') {
        cka_form_aud();
    } elseif ($code_set <> '') {
        cka_set_display();
    } else {
        cka_administration();
    }

    print "
    </body>
    </html>
    ";
}

#       #       #       #
#
# Print the page header
#
function cka_admin_header() {
    global $ckh;
    global $action;
    global $code_set;
    global $code_code;

    $title = "CodeKit Universal Code Administration";
    if ($code_set) $title .= " : $code_set";
    if ($action == 'New') {
        $title .= " : New";
    } elseif ($code_code <> '') {
        $title .= " : $code_code";
    }

    print "
    <html>
    <head>
    <title>$title</title>
    </head>

    <body text=\"#000044\" bgcolor=\"#f0ffff\"
    link=\"#0000cc\" vlink=\"#0066ff\" alink=\"#ffcc00\">

    <center>

    <h2 style=\"color:#873852\">$title</h2>
    <a href=\"" . cka_sess_url($_SERVER['PHP_SELF']) .
        "\"><b>Main Admin Page</b></a>
    - <a href=\"http://www.webbysoft.com/codekit/doc\"><b>Help Docs</b></a>
    - <a href=\"http://www.webbysoft.com/codekit\"><b>CodeKit Home</b></a>
    <p><b style=\"color:#873852\">
        Select a code set</b>
    <form action=\"" . cka_sess_url($_SERVER['PHP_SELF']) . "\" method=\"post\">
    ";

    print $ckh->select('code_set',  array(
        'blank_prompt' => 'All Codes',
        'options'      => 'onchange="submit()"'
    ));

    print "
    <input type=submit value=\"View Set\">
    </form>
    </center>
    <hr>
    ";
}

#       #       #       #
#
# Display the code administration page
#
function cka_administration() {
    global $ckh;

    print "<b style=\"color:#873852\">Main CodeKit Administration Page</b>\n";
    print "<p>\n";

    print "
    <table border=\"0\" cellspacing=\"1\" cellpadding=\"1\">
    <tr>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Code Set&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Description&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Count&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Admin&nbsp;</strong></th>
    </tr>
    ";

    # Print the count array.
    $set_counts = cka_get_counts();
    $set_rows  = $ckh->code_set('code_set');
    $total = 0;
    $n = 0;
    foreach ( $set_rows as $set_row ) {
        if ($set_row[3] == 'd') continue;
        $set_cd = $set_row[0];
        $set_desc = ucfirst($set_row[1]);
        $set_count = $set_counts[$set_cd];
        $total += $set_count;
        $bgcolor    = ($n % 2) ? "#6699CC" : "#6699FF";
        $n++;

        print"
        <tr>
        <td bgcolor=\"$bgcolor\">&nbsp;$set_cd&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$set_desc&nbsp;</td>
        <td bgcolor=\"$bgcolor\" align=\"right\">&nbsp;$set_count&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;
            <a href=\"" . cka_sess_url($self_url .
            "?code_set=$set_cd") .
            "\" style=\"color:white;\">
            <strong>admin</strong></a>&nbsp;
        </td>
        </tr>
        ";
    }

    $bgcolor    = ($n % 2) ? "#6699CC" : "#6699FF";
    print"
    <tr>
    <td bgcolor=\"$bgcolor\" colspan=\"2\">&nbsp;</td>
    <td bgcolor=\"$bgcolor\" align=\"right\">&nbsp;$total&nbsp;</td>
    <td bgcolor=\"$bgcolor\">&nbsp;</td>
    </tr>
    </table>
    ";
}

#       #       #       #
#
# Display a code set
#
function cka_set_display() {
    global $ckh;
    global $code_set;
    global $perm_add;

    $set_desc = $ckh->ucwords('code_set', $code_set);
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    $MD = ($code_set == 'code_set') ? 'M' : 'D';
    print "
    <table border=\"0\" cellspacing=\"1\" cellpadding=\"1\">
    <tr>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;$MD&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;O&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Code&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Description&nbsp;</strong></th>
    <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
        <strong>&nbsp;Edit&nbsp;</strong></th>
    </tr>
    ";

    # Gather the codes in order and truncate the descriptions.
    $base_set = $ckh->code_set($code_set);
    foreach ( $base_set as $n => $row ) {
        $desc = $row[1];
        if (strlen($desc) > 50)
            $desc = substr($desc, 0, 50) . '...';
        $base_set[$n][1] = htmlspecialchars($desc);
    }

    foreach ( $base_set as $n => $row ) {
        list(
            $code_code,
            $code_desc,
            $code_order,
            $code_flag
        ) = $row;

        $bgcolor    = ($n % 2) ? "#6699CC" : "#6699FF";
        $D = strtoupper($code_flag);

        print"
        <tr>
        <td bgcolor=\"$bgcolor\">&nbsp;$D&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_order&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_code&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_desc&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;
            <a href=\"" . cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_code=$code_code") . "\" style=\"color:white;\">
            <strong>edit</strong></a>&nbsp;
        </td>
        </tr>
        ";
    }
    print("</table>\n");

    $count = count($base_set);
    switch ($count) {
        case 0: print("<p>No records.\n\n"); break;
        case 1: printf("<p><b>%d</b> record.\n\n", $count); break;
        default: printf("<p><b>%d</b> records.\n\n", $count);
    }
    if ($perm_add) {
        print "<p><a href=\"" . cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&action=New") . "\">Add new $set_desc code</a>\n";
    }
}

#       #       #       #
#
# Display the code entry/update form.
#
function cka_form_display($code_code = '') {
    global $ckh;
    global $code_set;
    global $perm_add;
    global $perm_upd;
    global $perm_del;

    # Check for a valid code set or exit.
    list( $set_desc, $set_order, $set_flag ) =
        $ckh->get('code_set', $code_set);
    if (!$set_desc)
        cka_error_exit("No Code set specified!");

    $set_desc = $ckh->ucwords('code_set', $code_set);
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    print "
    <form action=\"" . cka_sess_url($_SERVER['PHP_SELF']) . "\" method=\"post\">
    <input type=\"hidden\" name=\"code_set\" value=\"$code_set\" >
    <table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
    <tr><th></th><td>
    ";

    if ($code_code == '') {
        print "<b>Add $set_desc code</b>\n";
    } else {

        # Code navigation aids.
        $set = $ckh->code_set($code_set);
        list( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            cka_place($set, $code_code);
        print "<b>Edit $set_desc code \"$code_code\"</b>
                (#$n_of of $of_n)<br>\n";

        print "<a href=\"". cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_code=$next_cd") . "\">Next</a> ($next_cd)\n";

        print "<a href=\"". cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_code=$prev_cd") . "\">Prev</a> ($prev_cd)\n";

        print "<a href=\"". cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_code=$first_cd") . "\">First</a> ($first_cd)\n";

        print "<a href=\"". cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_code=$last_cd") . "\">Last</a> ($last_cd)\n";
    }

    # Code code.
    print "
    <hr></td>
    </tr>
    <tr>
    <td align=\"right\"><strong>Code</strong></td>
    <td>
    ";
    if ($code_code == '') {
        if ($code_set == 'code_set') {
            print "<input name=\"code_code\" size=\"16\" maxlength=\"16\">\n";
        } else {
            print "<input name=\"code_code\" size=\"32\" maxlength=\"32\">\n";
        }
    } else {
        print "$code_code\n";
        print "<input name=\"code_code\" type=\"hidden\"
            value=\"$code_code\">\n";
    }
    print "
    </td>
    </tr>
    ";

    list( $code_desc, $code_order, $code_flag ) =
        $ckh->get($code_set, $code_code);

    # Deprecated / Multiline.
    if ($code_set == 'code_set') {
        $checked = ($code_flag == 'm') ? "checked" : "";
        print "
        <tr>
            <td align=\"right\"><strong>Multiline Set</strong></td>
            <td><input name=\"code_flag\" type=\"checkbox\"
                value=\"m\" $checked>
            [Paragraph mode]
            </td>
        </tr>
        ";
    } else {
        $checked = ($code_flag == 'd') ? "checked" : "";
        print "
        <tr>
            <td align=\"right\"><strong>Deprecated</strong></td>
            <td><input name=\"code_flag\" type=\"checkbox\"
                value=\"d\" $checked>
            </td>
        </tr>
        ";
    }

    # Order number.
    print "
    <tr>
        <td align=\"right\"><strong>Code Order</strong></td>
        <td><input name=\"code_order\" size=\"4\"
        value=\"$code_order\"></td>
    </tr>
    ";

    # Description.
    print "<tr>\n";
    print "<td align=\"right\" valign=\"top\"><strong>Description</td>\n";
    if ($set_flag == 'm') {
        $n = count(explode("\n", $code_desc));
        if ($n < 3) $n = 3;
        print "<td><textarea name=\"code_desc\" " .
            "cols=\"60\" rows=\"$n\" wrap=\"virtual\">$code_desc";
        print "</textarea></td>\n";
    } else {
        print "<td><input name=\"code_desc\" size=\"50\"";
        print "    value=\"$code_desc\"></td>\n";
    }
    print "</tr>\n";

    # Action items.
    print "
    <tr>
    <td align=\"right\">Action</td>
    <td>
    ";
    if ($code_code == '') {
        if ($perm_add)
            print "<input type=\"submit\" name=\"action\" value=\"Add\">\n";
    } else {
        if ($perm_upd)
            print "<input type=\"submit\" name=\"action\" value=\"Update\">\n";
        if ($perm_del)
            print "<input type=\"submit\" name=\"action\" value=\"Delete\">\n";
        if ($perm_add) {
            print "<a href=\"". cka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&action=New") . "\">Add new $set_desc code</a>\n";
        }
    }
    print "
    </td>
    </tr>

    </form>
    </table>
    ";
}

#       #       #       #
#
# Add / Update / Delete a code.
#
function cka_form_aud() {
    global $ckh;
    global $action;
    global $code_set;
    global $code_code;
    global $perm_add;
    global $perm_upd;
    global $perm_del;

    $code_desc  = $_POST['code_desc'];
    $code_order = $_POST['code_order'];
    $code_flag  = $_POST['code_flag'];

    # Check for validity.
    if (! $ckh->get('code_set', $code_set))
        cka_error_exit("No Code set specified!");
    if ($action == 'Add' && !$perm_add)
        cka_error_exit("No permission to add '$code_set'!");
    if ($action == 'Update' && !$perm_upd)
        cka_error_exit("No permission to update '$code_set'!");
    if ($action == 'Delete' && !$perm_del)
        cka_error_exit("No permission to delete '$code_set'!");
    if ($code_code == '')
        cka_error_exit("No code specified!");
    if (!ereg('^[a-zA-Z_0-9-]+$', $code_code))
        cka_error_exit("Code must consist of [a-zA-Z_0-9-]!");
    if (!ereg('^-?[0-9]*$', $code_order))
        cka_error_exit("Code order must be numeric!");

    # Variable setup.
    $code_exists = $ckh->get($code_set, $code_code);
    if ($action == "Update" || $action == 'Delete') {
        $set = $ckh->code_set($code_set);
        list( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            cka_place($set, $code_code);
    }

    if ($action == 'Delete') {
        if (!$code_exists)
            cka_error_exit("No such code '$code_code'!");
        $ckh->remove($code_set, $code_code);
        print "Record Deleted!<p>\n";
        if ($next_cd == $code_code) {
            cka_set_display();
        } else {
            cka_form_display($next_cd);
        }
    }

    elseif ($action == 'Add' || $action == 'Update') {

        if ($action == 'Add' && $code_exists)
            cka_error_exit("Code '$code_code' already exists!");
        if ($action == 'Update' && !$code_exists)
            cka_error_exit("No such code '$code_code'!");

        # Pump in those fields.
        $code_desc = trim($code_desc);
        $ckh->put($code_set, $code_code, $code_desc, $code_order, $code_flag);

        # Whats next.
        if ($action == 'Add') {
            print "Record Added!<p>\n";
            cka_form_display();
        }
        else {
            print "Record Updated!<p>\n";
            cka_form_display($next_cd);
        }
    }

    else {
        cka_error_exit("Unknown form action '$action'");
    }
}

#       #       #       #
#
# Local Functions
#

# Get the code counts for all sets.
function cka_get_counts() {
    global $ckh;
    $result = $ckh->_query("
        select  code_set,
                count(*) set_count
        from    $ckh->table
        group by code_set
    ");
    $set_counts = array();
    foreach ( $result as $row ) {
        $set_counts[$row[0]] = $row[1];
    }
    return $set_counts;
}

# Find a code's place in the set.
function cka_place($set, $code_code) {
    $count = count($set);
    $first = $set[0][0];
    $last = $set[$count - 1][0];

    for ($n = 0; $n < $count; $n++) {
        if ($set[$n][0] == $code_code) break;
    }
    if ($n == 0) {
        $prev = $last;
        if ($count > 1) {
            $next = $set[$n + 1][0];
        } else  {
            $next = $last;
        }
    } elseif ($n == $count - 1) {
        $prev = $set[$n - 1][0];
        $next = $first;
    } else {
        $prev = $set[$n - 1][0];
        $next = $set[$n + 1][0];
    }

    reset($set);
    return array( $n + 1, $count, $next, $prev, $first, $last );
}

# Error exit.
function cka_error_exit($msg) {
    print "<p><b>Error: $msg</b>";
    print "</body>\n</html>\n";
#   page_close();                       # If you need closure.
    exit();
}

# Compiler error workaround.
function cka_str_repeat($str, $rep) {
    if ($rep <= 0) return;              # Stunned designer.
#   return str_repeat($str, $rep);      # PHP bug too.
    for ($i = 0; $i < $rep; $i++) {
        $ret .= $str;
    }
    return $ret;
}

?>
