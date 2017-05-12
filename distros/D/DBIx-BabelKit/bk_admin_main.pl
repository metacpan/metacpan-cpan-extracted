
#       #       #       #
#
# bk_admin.pl
#
# BabelKit Universal Multilingual Code Table translation page.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#

use strict;
use warnings;
use vars qw(
    $action
    $code_set
    $code_lang
    $code_lang2
    $code_code
    $code_admin
    $self_url
);

#       #       #       #
#
# Main dispatch logic.
#

sub bka_admin_main {

    print $cgi->header;
    $self_url = $cgi->url(-absolute=>1);

    $action     = $cgi->param('action') || '';
    $code_set   = $cgi->param('code_set') || '';
    $code_lang  = $cgi->param('code_lang') || '';
    $code_lang2 = $cgi->param('code_lang2') || '';
    $code_code  = $cgi->param('code_code') || '';

    if (!$code_lang or $code_lang eq $code_lang2) {
        $code_lang2 = '';
    }

    $code_lang ||= $bkh->{native};
    $code_admin = bka_admin_get($code_set);
    if ($code_admin->{slave}) {
        $perm_add = 0;
        $perm_del = 0;
    }

    bka_admin_header();

    if ($action eq 'New') {
        bka_form_display();
    } elsif ($action eq '' && $code_code ne '') {
        bka_form_display($code_code);
    } elsif ($action ne '') {
        bka_form_aud();
    } elsif ($code_set ne '') {
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
sub bka_admin_header {

    my $title = "BabelKit Universal Code Translation";
    $title .= " : $code_set" if ($code_set);
    if ($action eq 'New') {
        $title .= " : New";
    } elsif ($code_code ne '') {
        $title .= " : $code_code";
    } elsif ($code_set) {
        $title .= " : $code_lang" if ($code_lang);
        $title .= "/$code_lang2" if ($code_lang2);
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
    <a href=\"" . bka_sess_url($self_url) .
        "\"><b>Main Translation Page</b></a>
    - <a href=\"http://www.webbysoft.com/babelkit/doc\"><b>Help Docs</b></a>
    - <a href=\"http://www.webbysoft.com/babelkit\"><b>BabelKit Home</b></a>
    <p><b style=\"color:#873852\">
        Select a code set and language(s)</b>
    <form action=\"" . bka_sess_url($self_url) . "\" method=\"post\">
    ";

    print $bkh->select('code_set',  $bkh->{native},
        blank_prompt  => 'All Codes'
    );
    print $bkh->select('code_lang', $bkh->{native});
    print $bkh->select('code_lang', $bkh->{native},
        var_name      => 'code_lang2',
        select_prompt => '(Other)',
        blank_prompt  => '(None)'
    );

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
sub bka_translations {

    print "<b style=\"color:#873852\">BabelKit Translation Sets</b>\n";

    # Get the code counts for all language sets.
    my $code_counts = bka_get_counts();

    # Get the code and language sets and print the top header.
    my $set_rows  = $bkh->lang_set('code_set',  $bkh->{native});
    my $lang_rows = $bkh->lang_set('code_lang', $bkh->{native});
    print "<pre>\n";
    printf("%-16s", "");
    for my $lang_row ( @$lang_rows ) {
        next if $lang_row->[3] eq 'd';
        my $lang_cd = $lang_row->[0];
        printf("<b>%6s</b>", $lang_cd);
    }

    # Print the count array.
    my $todo_count = 0;
    my $totals = {};
    for my $set_row ( @$set_rows ) {
        next if $set_row->[3] eq 'd';
        my $set_cd = $set_row->[0];

        my $this_admin = bka_admin_get($set_cd);
        next if $this_admin->{param};

        print "\n<a href=\"" .
            bka_sess_url($self_url . "?code_set=$set_cd") .
            "\">$set_cd</a>";
        print ' ' x ( 16 - length($set_cd) );

        my $nat_count = $code_counts->{$set_cd}{$bkh->{native}} || 0;
        for my $lang_row ( @$lang_rows ) {
            next if $lang_row->[3] eq 'd';
            my $lang_cd = $lang_row->[0];
            my $code_count = $code_counts->{$set_cd}{$lang_cd} || 0;
            print ' ' x ( 6 - length($code_count + 0) );
            print "<a href=\"" . bka_sess_url($self_url .
                "?code_set=$set_cd" .
                "&code_lang=$bkh->{native}" .
                "&code_lang2=$lang_cd") .
                "\">";
            if ($code_count == $nat_count) {
                printf("%d", $code_count);
            } else {
                printf("<span style=\"color:red\">%d</span>", $code_count);
                $todo_count += 1;
            }
            print "</a>";

            $totals->{$lang_cd} += $code_count;
        }
    }

    # Print the language totals.
    printf("\n%-16s", "");
    for my $lang_row ( @$lang_rows ) {
        next if $lang_row->[3] eq 'd';
        my $lang_cd = $lang_row->[0];
        printf("%6d", $totals->{$lang_cd});
    }

    print "</pre>\n";
    printf("%d language sets need translation work!", $todo_count);
}

#       #       #       #
#
# Display a code set
#
sub bka_set_display {

    my $edit_lang2 = $code_lang2;
    $edit_lang2 = '' unless $code_lang eq $bkh->{native};

    my $set_desc = $bkh->ucwords('code_set', $bkh->{native}, $code_set);
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    print "
    <table border=\"0\" cellspacing=\"1\" cellpadding=\"1\">
    <tr>
    ";

    if ($code_set eq 'code_set') {
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
    my $base_set = $bkh->lang_set($code_set, $code_lang);
    for my $row ( @$base_set ) {
        my $desc = $row->[1];
        if (length($desc) > 50) {
            $desc = substr($desc, 0, 50) . '...';
        }
        $row->[1] = DBIx::BabelKit::htmlspecialchars($desc);
    }

    if ($code_lang2) {

        # Add the second language descriptions.
        my $lang_set = $bkh->lang_set($code_set, $code_lang2);
        my $lang_lookup = {};
        for my $row ( @$lang_set ) {
            $lang_lookup->{$row->[0]} = $row->[1];
        }
        undef $lang_set;
        for my $row ( @$base_set ) {
            my $cd = $row->[0];
            my $desc = $lang_lookup->{$row->[0]};
            if ($desc ne '') {
                if (length($desc) > 50) {
                    $desc = substr($desc, 0, 50) . '...';
                }
                $row->[4] = DBIx::BabelKit::htmlspecialchars($desc);
            }
        }
        undef $lang_lookup;
    }

    my $colspan = ($code_set eq 'code_set') ? 5 : 3;
    my $n = 0;
    for my $row ( @$base_set ) {
        my (
            $code_code,
            $code_desc,
            $code_order,
            $code_flag,
            $code_desc2
        ) = @$row;

        my $bgcolor    = ($n % 2) ? "#6699CC" : "#6699FF";
        $n++;

        print"
        <tr>
        ";
        if ($code_set eq 'code_set') {
            my $this_admin = bka_admin_get($code_code);
            my $P = $this_admin->{param} ? 'P' : '';
            my $S = $this_admin->{slave} ? 'S' : '';
            my $M = $this_admin->{multi} ? 'M' : '';
            print "
            <td bgcolor=\"$bgcolor\">&nbsp;$P&nbsp;</td>
            <td bgcolor=\"$bgcolor\">&nbsp;$S&nbsp;</td>
            <td bgcolor=\"$bgcolor\">&nbsp;$M&nbsp;</td>
            ";
        } else {
            my $D = $code_flag ? 'D' : '';
            print "
            <td bgcolor=\"$bgcolor\">&nbsp;$D&nbsp;</td>
            ";
        }
        print "
        <td bgcolor=\"$bgcolor\">&nbsp;$code_order&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_code&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_desc&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;
            <a href=\"" . bka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_lang=$bkh->{native}" .
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

    print "</table>\n";

    my $count = @$base_set;
    if ($count == 0) {
        print("<p>No records.\n\n");
    } elsif ($count == 1) {
        printf("<p><b>%d</b> record.\n\n", $count);
    } else {
        printf("<p><b>%d</b> records.\n\n", $count);
    }
    if ($perm_add) {
        print "<p><a href=\"" . bka_sess_url($self_url .
            "?code_set=$code_set" .
            "&action=New") . "\">Add new $set_desc code</a>\n";
    }

}

#       #       #       #
#
# Display the multilanguage code entry/update form.
#
sub bka_form_display {
    my $code_code = shift;
    $code_code = '' unless defined $code_code;

    # Check for a valid code set or exit.
    my $set_desc = $bkh->ucwords('code_set', $bkh->{native}, $code_set);
    bka_error_exit("No Code set specified!") unless $set_desc;
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    print "
    <form action=\"" . bka_sess_url($self_url) . "\" method=\"post\">
    <input type=\"hidden\" name=\"code_set\" value=\"$code_set\" >
    <input type=\"hidden\" name=\"code_lang\" value=\"$code_lang\" >
    <input type=\"hidden\" name=\"code_lang2\" value=\"$code_lang2\" >
    <table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
    <tr><th></th><td>
    ";

    if ($code_code eq '') {
        print "<b>Add $set_desc code</b>\n";
    } else {

        # Code navigation aids.
        my $set = $bkh->lang_set($code_set, $bkh->{native});
        my ( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            bka_place($set, $code_code);
        print "<b>Edit $set_desc code \"$code_code\"</b>
                (#$n_of of $of_n)<br>\n";

        print "<a href=\"". bka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
            "&code_code=$next_cd") . "\">Next</a> ($next_cd)\n";

        print "<a href=\"". bka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
            "&code_code=$prev_cd") . "\">Prev</a> ($prev_cd)\n";

        print "<a href=\"". bka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_lang=$code_lang" .
            "&code_lang2=$code_lang2" .
            "&code_code=$first_cd") . "\">First</a> ($first_cd)\n";

        print "<a href=\"". bka_sess_url($self_url .
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
    if ($code_code eq '') {
        if ($code_set eq 'code_set') {
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

    my ( $desc_nat, $code_order, $code_flag ) =
        $bkh->get($code_set, $bkh->{native}, $code_code);
    $code_order = '' unless defined $code_order;
    $code_flag ||= '';
    if ($code_set eq 'code_set') {

        # Code Set Admin parameters
        my $this_admin = bka_admin_get($code_code);

        my $checked = ($this_admin->{param}) ? 'checked' : '';
        print "
        <tr>
            <td align=\"right\"><strong>Parameter Set</strong></td>
            <td><input name=\"this_admin[param]\" type=\"checkbox\"
                value=\"1\" $checked>
            [Parameter sets are not translated]
            </td>
        </tr>
        ";

        $checked = ($this_admin->{slave}) ? 'checked' : '';
        print "
        <tr>
            <td align=\"right\"><strong>Slave Set</strong></td>
            <td><input name=\"this_admin[slave]\" type=\"checkbox\"
                value=\"1\" $checked>
            [Slave sets are for translation only]
            </td>
        </tr>
        ";

        $checked = ($this_admin->{multi}) ? 'checked' : '';
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
        my $checked = ($code_flag eq 'd') ? "checked" : "";
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
    my $lang_rows;
    if ($code_admin->{param}) {
        $lang_rows = [
          [
            $bkh->{native}, $bkh->desc('code_lang', $bkh->{native}, $code_lang)
          ]
        ];
    } elsif ($code_lang2) {
        $lang_rows = [
          [
            $code_lang  , $bkh->desc('code_lang', $bkh->{native}, $code_lang)
          ],
          [
            $code_lang2 , $bkh->desc('code_lang', $bkh->{native}, $code_lang2)
          ]
        ];
    } else {
        $lang_rows = $bkh->lang_set('code_lang', $bkh->{native});
    }

    for my $lang_row ( @$lang_rows ) {
        my ( $lang_code, $lang_desc, $lang_order, $lang_flag ) = @$lang_row;
        next if $lang_flag eq 'd';

        my $code_desc = $bkh->data($code_set, $lang_code, $code_code);
        $code_desc = DBIx::BabelKit::htmlspecialchars($code_desc);
        $lang_desc = ucfirst($lang_desc);

        print "<tr>\n";
        print "<td align=\"right\" valign=\"top\"><strong>$lang_desc</td>\n";
        if ($lang_code eq $bkh->{native} && $code_admin->{slave}) {
            print "<td>$code_desc\n";
            print "<input type=\"hidden\" name=\"code_desc[$lang_code]\"";
            print " value=\"$code_desc\">\n</td>\n";
        } elsif ($code_admin->{multi}) {
            my @n = split "\n", $code_desc;
            my $n = @n;
            $n = 3 if $n < 3;
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
    if ($code_code eq '') {
        if ($perm_add) {
            print "<input type=\"submit\" name=\"action\" value=\"Add\">\n";
        }
    } else {
        if ($perm_upd) {
            print "<input type=\"submit\" name=\"action\" value=\"Update\">\n";
        }
        if ($perm_del) {
            print "<input type=\"submit\" name=\"action\" value=\"Delete\">\n";
        }
        if ($perm_add) {
            print "<a href=\"". bka_sess_url($self_url .
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
sub bka_form_aud {

    my $code_order = $cgi->param('code_order') || '';
    my $code_flag  = $cgi->param('code_flag') || '';

    # Check for validity.
    if ( ! $bkh->get('code_set', $bkh->{native}, $code_set) ) {
        bka_error_exit("No Code set specified!");
    }
    if ( $action eq 'Add' && !$perm_add ) {
        bka_error_exit("No permission to add '$code_set'!");
    }
    if ( $action eq 'Update' && !$perm_upd ) {
        bka_error_exit("No permission to update '$code_set'!");
    }
    if ( $action eq 'Delete' && !$perm_del ) {
        bka_error_exit("No permission to delete '$code_set'!");
    }
    if ( $code_code eq '' ) {
        bka_error_exit("No code specified!");
    }
    unless ( $code_code =~ /^[a-zA-Z_0-9-]+$/ ) {
        bka_error_exit("Code must consist of [a-zA-Z_0-9-]!");
    }
    unless ( $code_order =~ /^-?[0-9]*$/ ) {
        bka_error_exit("Code order must be numeric!");
    }

    # Get those language descriptions.
    my $lang_list = $bkh->lang_set('code_lang', $bkh->{native});
    my $code_desc = {};
    for my $lang_row ( @$lang_list ) {
        my $lang_cd = $lang_row->[0];
        $code_desc->{$lang_cd} = $cgi->param("code_desc[$lang_cd]");
    }

    # Variable setup.
    my $nat_exists = $bkh->get($code_set, $bkh->{native}, $code_code);
    my ( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd );
    if ($action eq 'Update' || $action eq 'Delete') {
        my $set = $bkh->lang_set($code_set, $bkh->{native});
        ( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            bka_place($set, $code_code);
    }

    if ($action eq 'Delete') {
        if (!$nat_exists) {
            bka_error_exit("No such code '$code_code'!");
        }
        $bkh->remove($code_set, $code_code);
        print "Record Deleted!<p>\n";
        if ($next_cd eq $code_code) {
            bka_set_display();
        } else {
            bka_form_display($next_cd);
        }
    }

    elsif ($action eq 'Add' || $action eq 'Update') {

        if ($action eq 'Add' && $nat_exists) {
            bka_error_exit("Code '$code_code' already exists!");
        }
        if ($action eq 'Update' && !$nat_exists) {
            bka_error_exit("No such code '$code_code'!");
        }
        if ($code_desc->{$bkh->{native}} eq '') {
            bka_error_exit("No native code description specified!");
        }

        # Pump in those fields.
        for my $lang_row ( @$lang_list ) {
            my $lang_cd = $lang_row->[0];
            my $lang_desc = $code_desc->{$lang_cd};
            next unless defined $lang_desc;
            $lang_desc =~ s/^\s+//;
            $lang_desc =~ s/\s+$//;
            $bkh->put($code_set, $lang_cd, $code_code, $lang_desc,
                $code_order, $code_flag);
        }

        # Code Admin fields.
        if ($code_set eq 'code_set') {
            my $this_admin = {};
            $this_admin->{param} = $cgi->param("this_admin[param]");
            $this_admin->{slave} = $cgi->param("this_admin[slave]");
            $this_admin->{multi} = $cgi->param("this_admithis_admin[multi]");
            bka_admin_put($code_code, $this_admin);
        }

        # Whats next.
        if ($action eq 'Add') {
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
sub bka_get_counts {
    my $sth = $dbh->prepare("
        select  code_set,
                code_lang,
                count(*) code_count
        from    $bkh->{table}
        group by code_set, code_lang
    ");
    $sth->execute;
    my $rows = $sth->fetchall_arrayref;
    my $code_counts = {};
    for my $row ( @$rows ) {
        $code_counts->{$row->[0]}{$row->[1]} = $row->[2];
    }
    return $code_counts;
}

# Find a code's place in the set.
sub bka_place {
    my $set = shift;
    my $code_code = shift;

    my $count = @$set;
    my $first = $set->[0][0];
    my $last = $set->[$count - 1][0];

    my $prev;
    my $next;
    my $n;
    for ($n = 0; $n < $count; $n++) {
        last if $set->[$n][0] eq $code_code;
    }
    if ($n == 0) {
        $prev = $last;
        if ($count > 1) {
            $next = $set->[$n + 1][0];
        } else  {
            $next = $last;
        }
    } elsif ($n == $count - 1) {
        $prev = $set->[$n - 1][0];
        $next = $first;
    } else {
        $prev = $set->[$n - 1][0];
        $next = $set->[$n + 1][0];
    }

    return ( $n + 1, $count, $next, $prev, $first, $last );
}

# Get the code_admin options for the set.
sub bka_admin_get {
    my $code_set = shift;
    my $code_admin = {};
    my @params = split ' ', $bkh->param('code_admin', $code_set);
    for my $param ( @params ) {
        my ( $attr, $value ) = split '=', $param;
        $code_admin->{$attr} = $value;
    }
    return $code_admin;
}

# Put the code_admin options for the set.
sub bka_admin_put {
    my $code_set = shift;
    my $code_admin = shift || {};
    my $params = '';
    for my $attr ( sort keys %$code_admin ) {
        my $value = $code_admin->{$attr};
        next unless $attr and $value;
        $params .= ' ' if $params;
        $params .= "$attr=$value";
    }
    $bkh->put('code_admin', $bkh->{native}, $code_set, $params);
}

# Error exit.
sub bka_error_exit {
    my $msg = shift;
    print "<p><b>Error: $msg</b>";
    print "</body>\n</html>\n";
    exit();
}

1;
