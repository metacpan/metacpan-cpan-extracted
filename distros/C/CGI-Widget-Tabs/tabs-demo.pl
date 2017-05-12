#!/usr/bin/perl -w

# pragmata
use lib qw(./lib);
use strict;

use CGI::Widget::Tabs;
use CGI::Widget::Tabs::Style;

my @styles = css_styles();  # imported cosmetics
my $cgi = create_cgi_object();
exit if ! defined $cgi;

my $current_style = $cgi->param("style") || 1;  # the currently selected style sheet
print <<EOT;
Content-Type: text/html;

<head>
<title>CGI::Widget::Tabs - Demo</title>
<style type="text/css">
EOT
print $styles[ $current_style - 1 ]->{style}; # humans start with 1, lists at 0
print <<EOT;
.ferrari {font-weight: bold; background-color:#F21E1E}
</style>
</head>
<body>
<h1>F1 - Team Simulation - 2002</h1>
EOT

my $main_tab = CGI::Widget::Tabs->new;  # first set up the main tab
$main_tab->cgi_object($cgi);            # access to the outside world
$main_tab->cgi_param("t");              # |comment this line out to see it will
                                        # |use the default value "tab"
$main_tab->headings( "Drivers",         # >The headings list is a plain list.
                     "Courses",         # >This means the actual words
                     "Cars",            # >are used in the URL.
                     "Style sheets" );


$main_tab->class("my_tab");  # CSS base style to use

print "<p>This is the main tab</p>\n";
$main_tab->display;  # paint the tab

print "<br>";  # I could probably use a CSS bottom margin too.

# --- Predefine the possible details tabs.
# --- Various configuration methods are used to illustate how to
# --- initialize headings.
# ---
# --- Usually multiple tabs can be configured much cleaner and more efficient.
# --- For instance a hash containing a complete menu structure plus options
# --- can be made in a flash. The reason things look a bit chaotic,
# --- it is to allow all options being demonstrated.

# Set up the details tab. The first few methods are common methods:
my $details = CGI::Widget::Tabs->new;
$details->cgi_object($cgi); # access to the outside world
$details->class("my_tab");  # we'll use the same style sheet as the main tab

# --- Differentiate based on the active heading from the main tab

HEADINGS: {
    # --- "Courses" tab
    ( $main_tab->active eq "Courses" ) && do {
        # This tab uses a list of strings:
        $details->headings( "Monte Carlo", "Silverstone", "Nurburgring", "Monza" );
        $details->cgi_param("dt");  # _details _tracks
        last HEADINGS;
    };

    # --- "Drivers" tab
    ( $main_tab->active eq "Drivers" ) && do {
        # This tab uses k/v pairs:
        $details->headings( -jpm => "J.P. Montoya",
                            -rs  => "R. Shumacher",
                            -ms  => "M. Shumacher",
                            -rb  => "R. Barichello",
                            -dc  => "D. Coulthard",
                            -ms  => "M. Salo" );
        $details->cgi_param("dd"); # _details _drivers
        last HEADINGS;
    };


    # --- "Cars" tab
    ( $main_tab->active eq "Cars" ) && do {
        # This tab goes for the OO approach
        my $h;

        $h = $details->heading(); # add a heading
        $h->text("Ferrari");      # text to display
        $h->class("ferrari");     # these guys have their own wishes

        $h = $details->heading(); # add another heading
        $h->text("McLaren&nbsp;Mercedes");
        $h->raw(1);               # do not encode. pass as is.

        $h = $details->heading(); # add another heading
        $h->text("BMW Williams"); # text to display...
        $h->key("bmw");           # ...but key to use

        $h = $details->heading(); # add another heading
        $h->text("Chrysler");     # |we don't have F1 records on Chrysler
                                  # |redirect to Chrysler homepage instead.
        $h->url("http://www.chrysler.com");
        $h->key("chr");           # this statement is useless. we don't use
                                  # the default self refer. URL but a tailored one.

        $details->cgi_param("dc");  # _details _cars
        last HEADINGS;
    };


    # --- "Style sheets" tab
    ( $main_tab->active eq "Style sheets" ) && do {
        print <<EOT;
<p>Are you graphically enabled?
<a style="color:blue" href="mailto:koos_pol\@raketnet.nl?Subject=CGI::Widget::Tabs style sheet">
Send me</a> your own styles. I will gladly add them to this list!</p>
<table>
<tr style="font-weight: bold">
<td>Description</td>
</tr>
EOT
        # -- We want to stay on this tab, while selecting different
        # -- style sheets. So we reproduce the URL and only change
        # -- the style sheet number.
        my $query_string = "";
        foreach ( $cgi->param() ) {
            next if ( $_ eq "style" );
            $query_string .= "$_=".$cgi->param($_)."&";
        };
        chop $query_string;  # remove the last added '&'
        my $style_num = 1 ;
        foreach my $style ( @styles ) {
            print "<tr>\n";
            print "<td>$style_num <a style=\"color:#000000";
            print  ";font-weight:bold" if ( $style_num == $current_style );
            print "\" href=\"?$query_string&style=$style_num\">".$style->{descr}."</a></td>\n";
            print "</tr>\n";
            $style_num++;
        }
        print "</table>\n";
    };
}



# run the selected details tab
if ( $main_tab->active ne "Style sheets" ) {
    print "<p>These are the details tabs.</p>\n";
    $details->wrap(4);   # after 4 headings we wrap to the next row
    $details->display ;  # there is no details for this one

    print "<br>We now should run some intelligent code ";
    print "to process <strong>", $details->active,"</strong><br>\n";
    if ( $details->active eq '-ms' ) {
        print <<EOT;
<br>
<font color="red">
WHOAA!  There are two tab headings identified by the same
key &quot;-ms;&quot;</font>
EOT
    }
}
print "</body>\n</html>";




# ---------------------------
sub create_cgi_object {
# ---------------------------
    if  ( ( eval {require CGI::Minimal; CGI::Minimal::reset_globals(); $cgi = CGI::Minimal->new} )
          or
          ( eval {require CGI; $cgi = CGI->new} )
        ) {
        return $cgi;
    }
    # - This is error handling. As such, it should be taken care
    # - of by the caller. But I didn't wanted to clutter the main code.
    print <<EOT;
Content-Type: text/html;

<head>
<title>ERROR</title>
<body>CGI not found and CGI::Minimal not found.</body></html>
EOT
    return undef
}


