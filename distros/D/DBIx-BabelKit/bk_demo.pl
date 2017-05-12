#!/usr/bin/perl

#       #       #       #
#
# bk_demo.cgi
#
# BabelKit Universal Multilingual Code HTML select function Perl demo page.
#
# Copyright (C) 2003 John Gorman <jgorman@webbysoft.com>
# http://www.webbysoft.com/babelkit
#

use strict;
use warnings;
use DBI;
use DBIx::BabelKit;
use CGI;
require("bk_connect.pl");

&bk_demo();

sub bk_demo {

    my $dbh = bk_connect();
    my $cgi = new CGI;
    my $babelkit = new DBIx::BabelKit($dbh,
                   getparam  => sub { $cgi->param(shift) },
                   getparams => sub { $cgi->param((shift).'[]') }
                   );

    print $cgi->header;

    my $title = "BabelKit Multilanguage Code Select Perl Demo";

    my $display_lang = $cgi->param('display_lang') || '';
    my $mycurrency = $cgi->param('currency') || '';
    my $day = $cgi->param('day') || '';
    my $countrystr = join(',', $cgi->param('country[]') );
    my $monthstr = join(',', $cgi->param('month[]') );

    print "
    <html>
    <head>
    <title>$title</title>
    </head>

    <body text=\"#000044\" bgcolor=\"#f0ffff\"
    link=\"#0000cc\" vlink=\"#0066ff\" alink=\"#ffcc00\">

    <center>
    <form action=\"" . $cgi->url(-absolute=>1) . "\" method=\"post\">
    <table border=\"1\" width=\"600\" cellpadding=\"20\">
    <tr>
    <td>

    <h2 style=\"color:#873852\">$title</h2>

    <a href=\"http://www.webbysoft.com/babelkit\">BabelKit</a> -
    Interface to a universal multilingual code table.

    <p>
    The codified values stored in database fields are not
    language sensitive.  However, web pages and other documents
    often need to display the code descriptions in various
    languages.
    
    <p>
    BabelKit makes this a snap to program.  You can see
    the Perl method calls to BabelKit that produce these
    multilingual HTML select elements.

    <p>
    This page shows off the BabelKit code select functions.
    Select another language for the code description display.
    Select various combinations of countries and months then
    click [Test BabelKit] at the bottom to see the selected
    codes:

    <p>
    <table border=\"3\" cellpadding=\"10\">
    <tr><th>Variable</th><th>Code(s)</th></tr>
    <tr><td>\$display_lang</td><td>'$display_lang'</td></tr>
    <tr><td>\$mycurrency</td><td>'$mycurrency'</td></tr>
    <tr><td>day</td><td>'$day'</td></tr>
    <tr><td>country</td><td>[$countrystr]</td></tr>
    <tr><td>month</td><td>[$monthstr]</td></tr>
    </table>

    <p>
    Have fun!
    ";

    #
    # Select Display Language.
    #

    print "</td></tr><tr><td>
    <b>Select another display language!</b>
    <p>Specify the variable name as 'display_lang'.
    <br>Pass in the native language as the default value.
    <br>Submit form when selection changes.
    <pre>
print \$babelkit->select('code_lang', \$display_lang,
                         var_name =&gt; 'display_lang',
                         default  =&gt; \$babelkit->{native},
                         options  =&gt; 'onchange=\"submit()\"'
);
    </pre>
    \$display_lang is '$display_lang':
    <p>
    ";
    print $babelkit->select('code_lang', $display_lang,
                             var_name => 'display_lang',
                             default  => $babelkit->{native},
                             options  => 'onchange="submit()"'
    );

    #
    # Currency Dropdown.
    #

    print "</td></tr><tr><td>
    <b>Select a currency.</b>
    <p>Pass in a specific code value.
    <pre>
print \$babelkit->select('currency', \$display_lang,
                         value =&gt; \$mycurrency
);
    </pre>
    \$mycurrency is '$mycurrency':
    <p>
    ";
    print $babelkit->select('currency', $display_lang,
                            value => $mycurrency
    );

    #
    # Day Radiobox.
    #

    print "</td></tr><tr><td>
    <b>Radiobox for days of the week.</b>
    <p>Constrain choices to the weekdays (1-5).
    <br>A blank separator displays them all on one line.
    <pre>
print \$babelkit->radio('day', \$display_lang,
                         subset =&gt; [ 1, 2, 3, 4, 5 ],
                         sep    =&gt; ''
);
    </pre>
    'day' is '$day':
    <p>
    ";
    print $babelkit->radio('day', $display_lang,
                           subset => [ 1, 2, 3, 4, 5 ],
                           sep    => ''
    );

    #
    # Country Select Multiple.
    #

    print "</td></tr><tr><td>
    <b>Select multiple countries</b>.
    <p>Specify a window scrolling size of 10.
    <p>Experiment with Ctrl-click and Shift-click
    <br>to select multiple countries.
    <pre>
print \$babelkit->multiple('country', \$display_lang,
                           size =&gt; 10
);
    </pre>
    'country' contains [$countrystr]:
    <p>
    ";
    print $babelkit->multiple('country', $display_lang,
                              size => 10
    );

    #
    # Month Checkbox.
    #

    print "</td></tr><tr><td>
    <b>Checkbox for multiple month selections.</b>
    <p>Simple no frills method call.
    <pre>
print \$babelkit->checkbox('month', \$display_lang);
    </pre>
    'month' contains [$monthstr]:
    <p>
    ";
    print $babelkit->checkbox('month', $display_lang);


    print "
    </td></tr><tr><td>
    <input type=submit value=\"Test BabelKit\">
    &lt;-- Click here to see the updated perl variables!
    </td>
    </tr>
    </table>
    </form>
    </center>
    </body>
    </html>
    ";
}
