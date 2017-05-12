<?php

#       #       #       #
#
# bk_admin.inc
#
# BabelKit Universal Multilingual Code Table translation page.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#

#       #       #       #
#
# Main dispatch logic.
#

function bka_admin_main() {
    global $bkh;        # Set in bk_admin.php:
    global $perm_add;
    global $perm_del;

    global $action;     # Set here:
    global $code_set;
    global $code_lang;
    global $code_lang2;
    global $code_code;
    global $code_admin;

    $getpost = $_POST ? '_POST' : '_GET';
    $action     = $GLOBALS[$getpost]['action'];
    $code_set   = $GLOBALS[$getpost]['code_set'];
    $code_lang  = $GLOBALS[$getpost]['code_lang'];
    $code_lang2 = $GLOBALS[$getpost]['code_lang2'];
    $code_code  = $GLOBALS[$getpost]['code_code'];

    if (!$code_lang or $code_lang == $code_lang2)
        $code_lang2 = '';

    if (!$code_lang) $code_lang = $bkh->native;
    $code_admin = bka_admin_get($code_set);
    if ($code_admin['slave']) {
        $perm_add = 0;
        $perm_del = 0;
    }

    bka_admin_header();

    if ($action == 'New') {
        bka_form_display();
    } elseif ($action == '' && $code_code <> '') {
        bka_form_display($code_code);
    } elseif ($action <> '') {
        bka_form_aud();
    } elseif ($code_set <> '') {
        bka_set_display();
    } else {
        bka_translations();
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
function bka_admin_header() {
    global $bkh;
    global $action;
    global $code_set;
    global $code_lang;
    global $code_lang2;
    global $code_code;

    $title = "BabelKit Universal Code Translation";
    if ($code_set) $title .= " : $code_set";
    if ($action == 'New') {
        $title .= " : New";
    } elseif ($code_code <> '') {
        $title .= " : $code_code";
    } elseif ($code_set) {
        if ($code_lang) $title .= " : $code_lang";
        if ($code_lang2) $title .= "/$code_lang2";
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
    <a href=\"" . bka_sess_url($_SERVER['PHP_SELF']) .
        "\"><b>Main Translation Page</b></a>
    - <a href=\"http://www.webbysoft.com/babelkit/doc\"><b>Help Docs</b></a>
    - <a href=\"http://www.webbysoft.com/babelkit\"><b>BabelKit Home</b></a>
    <p><b style=\"color:#873852\">
        Select a code set and language(s)</b>
    <form action=\"" . bka_sess_url($_SERVER['PHP_SELF']) . "\" method=\"post\">
    ";

    print $bkh->select('code_set',  $bkh->native, array(
        'blank_prompt' => 'All Codes'
    ));
    print $bkh->select('code_lang', $bkh->native);
    print $bkh->select('code_lang', $bkh->native, array(
        'var_name' => 'code_lang2',
        'select_prompt' => '(Other)',
        'blank_prompt' => '(None)'
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
# Display the code translation todo list
#
function bka_translations() {
    global $bkh;

    print "<b style=\"color:#873852\">BabelKit Translation Sets</b>\n";

    # Get the code counts for all language sets.
    $code_counts = bka_get_counts();

    # Get the code and language sets and print the top header.
    $set_rows  = $bkh->lang_set('code_set',  $bkh->native);
    $lang_rows = $bkh->lang_set('code_lang', $bkh->native);
    print "<pre>\n";
    printf("%-16s", "");
    foreach ( $lang_rows as $lang_row ) {
        if ($lang_row[3] == 'd') continue;
        $lang_cd = $lang_row[0];
        printf("<b>%6s</b>", $lang_cd);
    }

    # Print the count array.
    foreach ( $set_rows as $set_row ) {
        if ($set_row[3] == 'd') continue;
        $set_cd = $set_row[0];

        $this_admin = bka_admin_get($set_cd);
        if ($this_admin['param']) continue;

        print "\n<a href=\"" .
            bka_sess_url($_SERVER['PHP_SELF'] . "?code_set=$set_cd") .
            "\">$set_cd</a>";
        print bka_str_repeat(' ', 16 - strlen($set_cd) );

        $nat_count = $code_counts[$set_cd][$bkh->native];
        foreach ( $lang_rows as $lang_row ) {
            if ($lang_row[3] == 'd') continue;
            $lang_cd = $lang_row[0];
            $code_count = $code_counts[$set_cd][$lang_cd];
            print bka_str_repeat(' ', 6 - strlen($code_count + 0) );
            print "<a href=\"" . bka_sess_url($_SERVER['PHP_SELF'] .
                "?code_set=$set_cd" .
                "&code_lang=$bkh->native" .
                "&code_lang2=$lang_cd") .
                "\">";
            if ($code_count == $nat_count) {
                printf("%d", $code_count);
            } else {
                printf("<span style=\"color:red\">%d</span>", $code_count);
                $todo_count += 1;
            }
            print "</a>";

            $totals[$lang_cd] += $code_count;
        }
    }

    # Print the language totals.
    printf("\n%-16s", "");
    foreach ( $lang_rows as $lang_row ) {
        if ($lang_row[3] == 'd') continue;
        $lang_cd = $lang_row[0];
        printf("%6d", $totals[$lang_cd]);
    }

    print "</pre>\n";
    printf("%d language sets need translation work!", $todo_count);
}

#       #       #       #
#
# Display a code set
#
function bka_set_display() {
    global $bkh;
    global $code_set;
    global $code_lang;
    global $code_lang2;
    global $code_admin;
    global $perm_add;

    if ($code_lang == $bkh->native) {
        $edit_lang2 = $code_lang2;
    } else {
        $edit_lang2 = '';
    }

    $set_desc = $bkh->ucwords('code_set', $bkh->native, $code_set);
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    print "
    <table border=\"0\" cellspacing=\"1\" cellpadding=\"1\">
    <tr>
    ";

    if ($code_set == 'code_set') {

        print "
        <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
            <strong>&nbsp;P&nbsp;</strong></th>
        <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
            <strong>&nbsp;S&nbsp;</strong></th>
        <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
            <strong>&nbsp;M&nbsp;</strong></th>
        ";

    } else {

        print "
        <th bgcolor=\"#000000\" STYLE=\"color:white;font-size:9pt\">
            <strong>&nbsp;D&nbsp;</strong></th>
        ";
    }

    print "
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
    $base_set = $bkh->lang_set($code_set, $code_lang);
    foreach ( $base_set as $n => $row ) {
        $desc = $row[1];
        if (strlen($desc) > 50)
            $desc = substr($desc, 0, 50) . '...';
        $base_set[$n][1] = htmlspecialchars($desc);
    }

    if ($code_lang2) {

        # Add the second language descriptions.
        $lang_set = $bkh->lang_set($code_set, $code_lang2);
        $lang_lookup = array();
        foreach ( $lang_set as $row ) $lang_lookup[$row[0]] = $row[1];
        unset($lang_set);
        foreach ( $base_set as $n => $row ) {
            $cd = $row[0];
            $desc = $lang_lookup[$row[0]];
            if ($desc <> '') {
                if (strlen($desc) > 50)
                    $desc = substr($desc, 0, 50) . '...';
                $base_set[$n][4] = htmlspecialchars($desc);
            }
        }
        unset($lang_lookup);
    }

    $colspan = ($code_set == 'code_set') ? 5 : 3;
    foreach ( $base_set as $n => $row ) {
        list(
            $code_code,
            $code_desc,
            $code_order,
            $code_flag,
            $code_desc2
        ) = $row;

        $bgcolor    = ($n % 2) ? "#6699CC" : "#6699FF";

        print"
        <tr>
        ";
        if ($code_set == 'code_set') {

            $this_admin = bka_admin_get($code_code);
            $P = $this_admin['param'] ? 'P' : '';
            $S = $this_admin['slave'] ? 'S' : '';
            $M = $this_admin['multi'] ? 'M' : '';
            print "
            <td bgcolor=\"$bgcolor\">&nbsp;$P&nbsp;</td>
            <td bgcolor=\"$bgcolor\">&nbsp;$S&nbsp;</td>
            <td bgcolor=\"$bgcolor\">&nbsp;$M&nbsp;</td>
            ";
        } else {

            $D = $code_flag ? 'D' : '';
            print "
            <td bgcolor=\"$bgcolor\">&nbsp;$D&nbsp;</td>
            ";
        }
        print "
        <td bgcolor=\"$bgcolor\">&nbsp;$code_order&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_code&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_desc&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;
            <a href=\"" . bka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_lang=$bkh->native" .
            "&code_lang2=$edit_lang2" .
            "&code_code=$code_code") . "\" style=\"color:white;\">
            <strong>edit</strong></a>&nbsp;
        </td>
        </tr>
        ";

        if ($code_lang2) {
            print "
            <tr>
            <td bgcolor=\"$bgcolor\" colspan=\"$colspan\">&nbsp;</td>
            <td bgcolor=\"$bgcolor\">&nbsp;$code_desc2&nbsp;</td>
            <td bgcolor=\"$bgcolor\">&nbsp;</td>
            </tr>
            ";
        }
    }
    print("</table>\n");

    $count = count($base_set);
    switch ($count) {
        case 0: print("<p>No records.\n\n"); break;
        case 1: printf("<p><b>%d</b> record.\n\n", $count); break;
        default: printf("<p><b>%d</b> records.\n\n", $count);
    }
    if ($perm_add) {
        print "<p><a href=\"" . bka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&action=New") . "\">Add new $set_desc code</a>\n";
    }
}

#       #       #       #
#
# Display the multilanguage code entry/update form.
#
function bka_form_display($code_code = '') {
    global $bkh;
    global $code_set;
    global $code_lang;
    global $code_lang2;
    global $code_admin;
    global $perm_add;
    global $perm_upd;
    global $perm_del;

    # Check for a valid code set or exit.
    $set_desc = $bkh->ucwords('code_set', $bkh->native, $code_set);
    if (!$set_desc)
        bka_error_exit("No Code set specified!");
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    print "
    <form action=\"" . bka_sess_url($_SERVER['PHP_SELF']) . "\" method=\"post\">
    <input type=\"hidden\" name=\"code_set\" value=\"$code_set\" >
    <input type=\"hidden\" name=\"code_lang\" value=\"$code_lang\" >
    <input type=\"hidden\" name=\"code_lang2\" value=\"$code_lang2\" >
    <table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
    <tr><th></th><td>
    ";

    if ($code_code == '') {
        print "<b>Add $set_desc code</b>\n";
    } else {

        # Code navigation aids.
        $set = $bkh->lang_set($code_set, $bkh->native);
        list( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            bka_place($set, $code_code);
        print "<b>Edit $set_desc code \"$code_code\"</b>
                (#$n_of of $of_n)<br>\n";

        print "<a href=\"". bka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
            "&code_code=$next_cd") . "\">Next</a> ($next_cd)\n";

        print "<a href=\"". bka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
            "&code_code=$prev_cd") . "\">Prev</a> ($prev_cd)\n";

        print "<a href=\"". bka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
            "&code_code=$first_cd") . "\">First</a> ($first_cd)\n";

        print "<a href=\"". bka_sess_url($_SERVER['PHP_SELF'] .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
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

    list( $desc_nat, $code_order, $code_flag ) =
        $bkh->get($code_set, $bkh->native, $code_code);
    if ($code_set == 'code_set') {

        # Code Set Admin parameters
        $this_admin = bka_admin_get($code_code);

        $checked = ($this_admin['param']) ? 'checked' : '';
        print "
        <tr>
            <td align=\"right\"><strong>Parameter Set</strong></td>
            <td><input name=\"this_admin[param]\" type=\"checkbox\"
                value=\"1\" $checked>
            [Parameter sets are not translated]
            </td>
        </tr>
        ";

        $checked = ($this_admin['slave']) ? 'checked' : '';
        print "
        <tr>
            <td align=\"right\"><strong>Slave Set</strong></td>
            <td><input name=\"this_admin[slave]\" type=\"checkbox\"
                value=\"1\" $checked>
            [Slave sets are for translation only]
            </td>
        </tr>
        ";

        $checked = ($this_admin['multi']) ? 'checked' : '';
        print "
        <tr>
            <td align=\"right\"><strong>Multiline Set</strong></td>
            <td><input name=\"this_admin[multi]\" type=\"checkbox\"
                value=\"1\" $checked>
            [Paragraph mode]
            </td>
        </tr>
        ";

    } else {

        # Deprecated?
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

    # Make a field for each translation.
    if ($code_admin['param']) {
        $lang_rows = array(
          array(
            $bkh->native, $bkh->desc('code_lang', $bkh->native, $code_lang)
          )
        );
    } elseif ($code_lang2) {
        $lang_rows = array(
          array(
            $code_lang  , $bkh->desc('code_lang', $bkh->native, $code_lang),
          ),
          array(
            $code_lang2 , $bkh->desc('code_lang', $bkh->native, $code_lang2)
          )
        );
    } else {
        $lang_rows = $bkh->lang_set('code_lang', $bkh->native);
    }

    foreach ( $lang_rows as $lang_row ) {
        list( $lang_code, $lang_desc, $lang_order, $lang_flag ) = $lang_row;
        if ($lang_flag == 'd') continue;

        $code_desc = $bkh->data($code_set, $lang_code, $code_code);
        $code_desc = htmlspecialchars($code_desc);
        $lang_desc = ucfirst($lang_desc);

        print "<tr>\n";
        print "<td align=\"right\" valign=\"top\"><strong>$lang_desc</td>\n";
        if ($lang_code == $bkh->native && $code_admin['slave']) {
            print "<td>$code_desc\n";
            print "<input type=\"hidden\" name=\"code_desc[$lang_code]\"";
            print " value=\"$code_desc\">\n</td>\n";
        } elseif ($code_admin['multi']) {
            $n = count(explode("\n", $code_desc));
            if ($n < 3) $n = 3;
            print "<td><textarea name=\"code_desc[$lang_code]\" " .
                "cols=\"60\" rows=\"$n\" wrap=\"virtual\">$code_desc";
            print "</textarea></td>\n";
        } else {
            print "<td><input name=\"code_desc[$lang_code]\" size=\"50\"";
            print "    value=\"$code_desc\"></td>\n";
        }
        print "</tr>\n";
    }

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
            print "<a href=\"". bka_sess_url($_SERVER['PHP_SELF'] .
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
function bka_form_aud() {
    global $bkh;
    global $action;
    global $code_set;
    global $code_code;
    global $perm_add;
    global $perm_upd;
    global $perm_del;

    $code_order = $_POST['code_order'];
    $code_flag  = $_POST['code_flag'];
    $this_admin = $_POST['this_admin'];
    $code_desc  = $_POST['code_desc'];

    # Check for validity.
    if (! $bkh->get('code_set', $bkh->native, $code_set))
        bka_error_exit("No Code set specified!");
    if ($action == 'Add' && !$perm_add)
        bka_error_exit("No permission to add '$code_set'!");
    if ($action == 'Update' && !$perm_upd)
        bka_error_exit("No permission to update '$code_set'!");
    if ($action == 'Delete' && !$perm_del)
        bka_error_exit("No permission to delete '$code_set'!");
    if ($code_code == '')
        bka_error_exit("No code specified!");
    if (!ereg('^[a-zA-Z_0-9-]+$', $code_code))
        bka_error_exit("Code must consist of [a-zA-Z_0-9-]!");
    if (!ereg('^-?[0-9]*$', $code_order))
        bka_error_exit("Code order must be numeric!");

    # Variable setup.
    $lang_list = $bkh->lang_set('code_lang', $bkh->native);
    $nat_exists = $bkh->get($code_set, $bkh->native, $code_code);
    if ($action == "Update" || $action == 'Delete') {
        $set = $bkh->lang_set($code_set, $bkh->native);
        list( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            bka_place($set, $code_code);
    }

    if ($action == 'Delete') {
        if (!$nat_exists)
            bka_error_exit("No such code '$code_code'!");
        $bkh->remove($code_set, $code_code);
        print "Record Deleted!<p>\n";
        if ($next_cd == $code_code) {
            bka_set_display();
        } else {
            bka_form_display($next_cd);
        }
    }

    elseif ($action == 'Add' || $action == 'Update') {

        if ($action == 'Add' && $nat_exists)
            bka_error_exit("Code '$code_code' already exists!");
        elseif ($action == 'Update' && !$nat_exists)
            bka_error_exit("No such code '$code_code'!");

        if ($code_desc[$bkh->native] == '')
            bka_error_exit("No native code description specified!");

        # Pump in those fields.
        foreach ( $lang_list as $lang_row ) {
            $lang_cd = $lang_row[0];
            $lang_desc = $code_desc[$lang_cd];
            if (!isset($lang_desc)) continue;
            $lang_desc = trim($lang_desc);
            $bkh->put($code_set, $lang_cd, $code_code, $lang_desc,
                $code_order, $code_flag);
        }

        # Code Admin fields.
        if ($code_set == 'code_set') {
            bka_admin_put($code_code, $this_admin);
        }

        # Whats next.
        if ($action == 'Add') {
            print "Record Added!<p>\n";
            bka_form_display();
        }
        else {
            print "Record Updated!<p>\n";
            bka_form_display($next_cd);
        }
    }

    else {
        bka_error_exit("Unknown form action '$action'");
    }
}

#       #       #       #
#
# Local Functions
#

# Get the code counts for all language sets.
function bka_get_counts() {
    global $bkh;
    $result = $bkh->_query("
        select  code_set,
                code_lang,
                count(*) code_count
        from    $bkh->table
        group by code_set, code_lang
    ");
    $code_counts = array();
    foreach ( $result as $row ) {
        $code_counts[$row[0]][$row[1]] = $row[2];
    }
    return $code_counts;
}

# Find a code's place in the set.
function bka_place($set, $code_code) {
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

# Get the code_admin options for the set.
function bka_admin_get($code_set) {
    global $bkh;
    $params = explode(' ', $bkh->param('code_admin', $code_set));
    foreach ( $params as $n => $param ) {
        list( $attr, $value ) = explode('=', $param);
        $code_admin[$attr] = $value;
    }
    return $code_admin;
}

# Put the code_admin options for the set.
function bka_admin_put($code_set, $code_admin) {
    global $bkh;
    if (!$code_admin) $code_admin = array();
    foreach ( $code_admin as $attr => $value ) {
        if (!$attr or !$value) continue;
        if ($params) $params .= ' ';
        $params .= "$attr=$value";
    }
    $bkh->put('code_admin', $bkh->native, $code_set, $params);
}

# Error exit.
function bka_error_exit($msg) {
    print "<p><b>Error: $msg</b>";
    print "</body>\n</html>\n";
#   page_close();                       # If you need closure.
    exit();
}

# Compiler error workaround.
function bka_str_repeat($str, $rep) {
    if ($rep <= 0) return;              # Stunned designer.
#   return str_repeat($str, $rep);      # PHP bug too.
    for ($i = 0; $i < $rep; $i++) {
        $ret .= $str;
    }
    return $ret;
}

?>
