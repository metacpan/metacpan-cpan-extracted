<?php

#       #       #       #
#
# ck_demo.php
#
# CodeKit Universal Code HTML select function PHP demo page.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/codekit
#

ck_demo();

function ck_demo() {

    require_once('ck_connect.inc');
    $dbh = ck_connect();

    require_once('CodeKit.php');
    $codekit = new CodeKit($dbh);

    $title = "CodeKit Code Select PHP Demo";

    $mycurrency = $_POST['currency'];
    $day = $_POST['day'];
    $country = $_POST['country'];
    if (!is_array($country)) $country = array();
    $countrystr = join(',', $country);
    $month = $_POST['month'];
    if (!is_array($month)) $month = array();
    $monthstr = join(',', $month);

    print "
    <html>
    <head>
    <title>$title</title>
    </head>

    <body text=\"#000044\" bgcolor=\"#f0ffff\"
    link=\"#0000cc\" vlink=\"#0066ff\" alink=\"#ffcc00\">

    <center>
    <form action=\"" . $_SERVER['PHP_SELF'] . "\" method=\"post\">
    <table border=\"1\" width=\"600\" cellpadding=\"20\">
    <tr>
    <td>

    <h2 style=\"color:#873852\">$title</h2>

    <a href=\"http://www.webbysoft.com/codekit\">CodeKit</a> -
    Interface to a universal code table.

    <p>
    Code sets are often used to present user data entry
    choices rather than hardcode specific values in application
    source code.  Web pages and other documents often need
    to display codefied database values as human readable
    descriptions.

    <p>
    CodeKit makes this a snap to program.  You can see
    the PHP method calls to CodeKit that produce these
    HTML select elements from database code sets.

    <p>
    This page shows off the CodeKit code select functions.
    Select various combinations of countries and months then
    click [Test CodeKit] at the bottom to see the selected
    codes:

    <p>
    <table border=\"3\" cellpadding=\"10\">
    <tr><th>Variable</th><th>Code(s)</th></tr>
    <tr><td>\$mycurrency</td><td>'$mycurrency'</td></tr>
    <tr><td>day</td><td>'$day'</td></tr>
    <tr><td>country</td><td>[$countrystr]</td></tr>
    <tr><td>month</td><td>[$monthstr]</td></tr>
    </table>

    <p>
    Have fun!
    ";

    #
    # Currency Dropdown.
    #

    print "</td></tr><tr><td>
    <b>Select a currency.</b>
    <p>Pass in a specific code value.
    <pre>
print \$codekit->select('currency', array(
                       'value' =&gt; \$mycurrency
));
    </pre>
    \$mycurrency is '$mycurrency':
    <p>
    ";
    print $codekit->select('currency', array(
                           'value' => $mycurrency
    ));

    #
    # Day Radiobox.
    #

    print "</td></tr><tr><td>
    <b>Radiobox for days of the week.</b>
    <p>Constrain choices to the weekdays (1-5).
    <br>A blank separator displays them all on one line.
    <pre>
print \$codekit->radio('day', array(
                      'subset' =&gt; array(1, 2, 3, 4, 5),
                      'sep'    =&gt; ''
));
    </pre>
    'day' is '$day'.
    <p>
    ";
    print $codekit->radio('day', array(
                          'subset' => array(1, 2, 3, 4, 5),
                          'sep'    => ''
    ));

    #
    # Country Select Multiple.
    #

    print "</td></tr><tr><td>
    <b>Select multiple countries</b>.
    <p>Specify a window scrolling size of 10.
    <p>Experiment with Ctrl-click and Shift-click.
    <br>to select multiple countries.
    <pre>
print \$codekit->multiple('country', array(
                         'size' =&gt; 10
));
    </pre>
    'country' contains [$countrystr]:
    <p>
    ";
    print $codekit->multiple('country', array(
                             'size' => 10
    ));

    #
    # Month Checkbox.
    #

    print "</td></tr><tr><td>
    <b>Checkbox for multiple month selections.</b>
    <p>Simple no frills method call.
    <pre>
print \$codekit->checkbox('month');
    </pre>
    'month' contains [$monthstr]:
    <p>
    ";
    print $codekit->checkbox('month');

    print "
    </td></tr><tr><td>
    <input type=submit value=\"Test CodeKit\">
    &lt;-- Click here to see the updated PHP variables!
    </td>
    </tr>
    </table>
    </form>
    </center>
    </body>
    </html>
    ";
}

?>
