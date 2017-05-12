
#       #       #       #
#
# ck_admin.pl
#
# CodeKit Universal Code Table Administration page.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/codekit
#

use strict;
use warnings;
use vars qw(
    $action
    $code_set
    $code_code
    $self_url
);

#       #       #       #
#
# Main dispatch logic.
#

sub cka_admin_main {

    print $cgi->header;
    $self_url = $cgi->url(-absolute=>1);

    $action     = $cgi->param('action') || '';
    $code_set   = $cgi->param('code_set') || '';
    $code_code  = $cgi->param('code_code') || '';

    cka_admin_header();

    if ($action eq 'New') {
        cka_form_display();
    } elsif ($action eq '' && $code_code ne '') {
        cka_form_display($code_code);
    } elsif ($action ne '') {
        cka_form_aud();
    } elsif ($code_set ne '') {
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
sub cka_admin_header {

    my $title = "CodeKit Universal Code Administration";
    $title .= " : $code_set" if ($code_set);
    if ($action eq 'New') {
        $title .= " : New";
    } elsif ($code_code ne '') {
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
    <a href=\"" . cka_sess_url($self_url) .
        "\"><b>Main Admin Page</b></a>
    - <a href=\"http://www.webbysoft.com/codekit/doc\"><b>Help Docs</b></a>
    - <a href=\"http://www.webbysoft.com/codekit\"><b>CodeKit Home</b></a>
    <p><b style=\"color:#873852\">
        Select a code set</b>
    <form action=\"" . cka_sess_url($self_url) . "\" method=\"post\">
    ";

    print $ckh->select('code_set',
        blank_prompt  => 'All Codes',
        options       => 'onchange="submit()"'
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
# Display the code administration page
#
sub cka_administration {

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

    # Print the code sets.
    my $set_counts = cka_get_counts();
    my $set_rows  = $ckh->code_set('code_set');
    my $bgcolor;
    my $total = 0;
    my $n = 0;
    for my $set_row ( @$set_rows ) {
        next if $set_row->[3] eq 'd';
        my $set_cd   = $set_row->[0];
        my $set_desc = ucfirst($set_row->[1]);
        my $set_count = $set_counts->{$set_cd} || 0;
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
sub cka_set_display {

    my $set_desc = $ckh->ucwords('code_set', $code_set);
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    my $MD = ($code_set eq 'code_set') ? 'M' : 'D';
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
    my $base_set = $ckh->code_set($code_set);
    for my $row ( @$base_set ) {
        my $desc = $row->[1];
        if (length($desc) > 50) {
            $desc = substr($desc, 0, 50) . '...';
        }
        $row->[1] = DBIx::CodeKit::htmlspecialchars($desc);
    }

    my $n = 0;
    for my $row ( @$base_set ) {
        my (
            $code_code,
            $code_desc,
            $code_order,
            $code_flag
        ) = @$row;

        my $bgcolor    = ($n % 2) ? "#6699CC" : "#6699FF";
        $n++;
        my $D = uc($code_flag);

        print"
        <tr>
        <td bgcolor=\"$bgcolor\">&nbsp;$D&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_order&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_code&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;$code_desc&nbsp;</td>
        <td bgcolor=\"$bgcolor\">&nbsp;
            <a href=\"" . cka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_code=$code_code") . "\" style=\"color:white;\">
            <strong>edit</strong></a>&nbsp;
        </td>
        </tr>
        ";
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
        print "<p><a href=\"" . cka_sess_url($self_url .
            "?code_set=$code_set" .
            "&action=New") . "\">Add new $set_desc code</a>\n";
    }
}

#       #       #       #
#
# Display the code entry/update form.
#
sub cka_form_display {
    my $code_code = shift;
    $code_code = '' unless defined $code_code;

    # Check for a valid code set or exit.
    my ( $set_desc, $set_order, $set_flag ) = $ckh->get('code_set', $code_set);
    cka_error_exit("No Code set specified!") unless $set_desc;

    $set_desc = $ckh->ucwords('code_set', $code_set);
    print "<b style=\"color:#873852\">$set_desc Code Administration</b>\n";
    print "<p>\n";

    print "
    <form action=\"" . cka_sess_url($self_url) . "\" method=\"post\">
    <input type=\"hidden\" name=\"code_set\" value=\"$code_set\" >
    <table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
    <tr><th></th><td>
    ";

    if ($code_code eq '') {
        print "<b>Add $set_desc code</b>\n";
    } else {

        # Code navigation aids.
        my $set = $ckh->code_set($code_set);
        my ( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            cka_place($set, $code_code);
        print "<b>Edit $set_desc code \"$code_code\"</b>
                (#$n_of of $of_n)<br>\n";

        print "<a href=\"". cka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_code=$next_cd") . "\">Next</a> ($next_cd)\n";

        print "<a href=\"". cka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_code=$prev_cd") . "\">Prev</a> ($prev_cd)\n";

        print "<a href=\"". cka_sess_url($self_url .
            "?code_set=$code_set" .
            "&code_code=$first_cd") . "\">First</a> ($first_cd)\n";

        print "<a href=\"". cka_sess_url($self_url .
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

    my ( $code_desc, $code_order, $code_flag ) =
        $ckh->get($code_set, $code_code);
    $code_desc  = '' unless defined $code_desc;
    $code_order = '' unless defined $code_order;
    $code_flag  = '' unless defined $code_flag;

    if ($code_set eq 'code_set') {

        # Multiline?
        my $checked = ($code_flag eq 'm') ? 'checked' : '';
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

    # Description
    $code_desc = DBIx::CodeKit::htmlspecialchars($code_desc);
    print "<tr>\n";
    print "<td align=\"right\" valign=\"top\"><strong>Description</td>\n";
    if ($set_flag eq 'm') {
        my @n = split "\n", $code_desc;
        my $n = @n;
        $n = 3 if $n < 3;
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
            print "<a href=\"". cka_sess_url($self_url .
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
sub cka_form_aud {

    my $code_desc  = $cgi->param('code_desc') || '';
    my $code_order = $cgi->param('code_order') || '';
    my $code_flag  = $cgi->param('code_flag') || '';

    # Check for validity.
    if ( ! $ckh->get('code_set', $code_set) ) {
        cka_error_exit("No Code set specified!");
    }
    if ( $action eq 'Add' && !$perm_add ) {
        cka_error_exit("No permission to add '$code_set'!");
    }
    if ( $action eq 'Update' && !$perm_upd ) {
        cka_error_exit("No permission to update '$code_set'!");
    }
    if ( $action eq 'Delete' && !$perm_del ) {
        cka_error_exit("No permission to delete '$code_set'!");
    }
    if ( $code_code eq '' ) {
        cka_error_exit("No code specified!");
    }
    unless ( $code_code =~ /^[a-zA-Z_0-9-]+$/ ) {
        cka_error_exit("Code must consist of [a-zA-Z_0-9-]!");
    }
    unless ( $code_order =~ /^-?[0-9]*$/ ) {
        cka_error_exit("Code order must be numeric!");
    }

    # Variable setup.
    my $code_exists = $ckh->get($code_set, $code_code);
    my ( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd );
    if ($action eq 'Update' || $action eq 'Delete') {
        my $set = $ckh->code_set($code_set);
        ( $n_of, $of_n, $next_cd, $prev_cd, $first_cd, $last_cd ) =
            cka_place($set, $code_code);
    }

    if ($action eq 'Delete') {
        if (!$code_exists) {
            cka_error_exit("No such code '$code_code'!");
        }
        $ckh->remove($code_set, $code_code);
        print "Record Deleted!<p>\n";
        if ($next_cd eq $code_code) {
            cka_set_display();
        } else {
            cka_form_display($next_cd);
        }
    }

    elsif ($action eq 'Add' || $action eq 'Update') {

        if ($action eq 'Add' && $code_exists) {
            cka_error_exit("Code '$code_code' already exists!");
        }
        if ($action eq 'Update' && !$code_exists) {
            cka_error_exit("No such code '$code_code'!");
        }

        # Pump in those fields.
        $code_desc =~ s/^\s+//;
        $code_desc =~ s/\s+$//;
        $ckh->put($code_set, $code_code, $code_desc, $code_order, $code_flag);

        # Whats next.
        if ($action eq 'Add') {
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
sub cka_get_counts {
    my $sth = $dbh->prepare("
        select  code_set,
                count(*) code_count
        from    $ckh->{table}
        group by code_set
    ");
    $sth->execute;
    my $rows = $sth->fetchall_arrayref;
    my $set_counts = {};
    for my $row ( @$rows ) {
        $set_counts->{$row->[0]} = $row->[1];
    }
    return $set_counts;
}

# Find a code's place in the set.
sub cka_place {
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

# Error exit.
sub cka_error_exit {
    my $msg = shift;
    print "<p><b>Error: $msg</b>";
    print "</body>\n</html>\n";
    exit();
}

1;
