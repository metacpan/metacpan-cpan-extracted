#!/usr/bin/perl -w

# $Id$

use strict;
use CGI;
use CGI::Carp 'fatalsToBrowser';
use URI::Escape;
use vars qw($SELF_URL);

use lib '/home/sherzodr/perllib';

# Check for some non-standard Perl modules
my @required = qw(MIME::Lite HTML::Template CGI::Session);
for my $mod ( @required ) {
    eval "require $mod";
    if ( $@ ) {
        print "Content-Type: text/html\n\n";
        print "$mod is required. If it's installed in a non-standard path, " .
                "please 'use lib' line in $0";
        exit(0);
    }
}

my $cgi     = CGI->new();
my $session = CGI::Session->load() or die CGI::Session->errstr;

if ( $session->is_expired ) {
    print $session->header();
    print "Your session expired, inevitably!";
    exit(0);
} elsif ( $session->is_empty ) {
    $session = $session->new();
}

$session->expire("+30s");

my $cmd     = $cgi->param('cmd') || $session->param("last_cmd") || 'directions';

$SELF_URL = $cgi->url() || $0;


# save the last executed command:
$session->param(last_cmd => $cmd);

if ( $cmd eq "directions" ) {
    print directions($cgi, $session);

} elsif ( $cmd eq 'step1' ) {
    print step1($cgi, $session);

} elsif ( $cmd eq 'step2' ) {
    print step2($cgi, $session);

} elsif ( $cmd eq 'step3' ) {
    print step3($cgi, $session);

} elsif ( $cmd eq 'finish') {
    print finish($cgi, $session);

} elsif ( $cmd eq 'clear' ) {
    print clear($cgi, $session);

} elsif ( $cmd eq "show-dump" ) {
    print show_dump($cgi, $session);

} else {
    print "Error: CMD: $cmd is not valid";

}














#--------------------------------------------------------------------
# functions start here
#--------------------------------------------------------------------
sub directions {
    my ($cgi, $session) = @_;

    my $dirver = ref($session);
    my $version = $session->VERSION();

    my $HTML = <<HTML;
<h2>Welcome to CGI::Session Demo Script</h2>

<div><strong>Driver:</strong> $dirver/$version</div>

<p>
The tricks are endless! This script is to demonstrate basic usage of
CGI::Session in CGI applications.
</p>

<h3>So what is the test all about?</h3>

<p>
Test consists of a single multi-page mailing list subscription form.
First form asks to fill in personal information, the second screen
asks to choose subscriptions you are interested in. The 3rd page
is a confirmation/summary of your subscriptions. Once you click on
"Finish" button, the program sends your subscription details to your
email you provided during subscriptions, and also attaches the source
code of this script.
</p>

<p>
During the process, application provides "Back", "Next" and"Clear Form"
buttons so that you can go back to previous forms to fill in/correct
the details. While going back, notice how the script remembers all the
data you have previously submitted, and presents pre-filled/pre-selected
form elements.
</p>

<p>
While somewhere in the middle of subscription, close the browser
intentionally, and reopen the page: <a href="$SELF_URL">$SELF_URL</a>. Notice how the script remembers which form you were filling out before you closed the browser, and displays
respective form, instead of taking you to the default page. Your previously
filled in form data are also kept.
</p>
<p>
In each page, the script also provides you with "show-dump" link at the bottom
of each screen. You can click on the link to view internal <b>_DATA</b> table
of CGI::Session, and see what kind of information are stored in the object
at each step.
</p>

<p>
Should you have any suggestions or comments, feel free to send me an email:
<a href="mailto:sherzodr\@cpan.org">sherzodr\@cpan.org</a>.
</p>

<form>
<input type="hidden" name="CGISESSID" value="%_session_id%" />
<input type="hidden" name="cmd" value="step1" />
<input type="submit" value="Start The Demo" />
</form>
HTML
    return template(\$HTML, $cgi, $session);
}




sub step1 {
    my ($cgi, $session) = @_;
    my $HTML = <<'HTML';
<h4>Step 1 out of 3</h4>
<p> Hi %name%! Please fill out your personal information below </p>
<form method="post">
    <input type="hidden" name="CGISESSID", value="%_session_id%" />
    <input type="hidden" name="cmd" value="step2" />
    <div>Your full name:</div>
        <input type="text" name="name" value="%name%" size="35" />
    <div>Your email address:</div>
        <input type="text" name="email" value="%email%" size="35" />
    <div>Your website URL:</div>
        <input type="text" name="website" value="%website%" size="35" />
    <br />
    <input type="button" value="Cancel" onClick="clearTheForm(this.form)" />
    <input type="submit" value="Next &gt;&gt;" />
</form>
HTML

    return template(\$HTML, $cgi, $session);
}



sub step2 {
    my ($cgi, $session) = @_;

    $session->save_param($cgi);
    $session->load_param($cgi, ["subscriptions"]);

    my $HTML = <<HTML;
<h4>Step 2 out of 3</h4>
<p>Dear %name%.</p>
<p>
    Following are available newspaper subscriptions we offer.<br />
    Choose the subscriptions you are interested in, and click "Next &gt;&gt;"<br />button.  To select more than one subscription, press and hold [CTRL] key while selecting.<br />
    Should you wish to update your profile, click "&lt;&lt;Back" button.<br />

</p>

<form method="post">
<input type="hidden" name="CGISESSID" value="%_session_id%" />
<input type="hidden" name="cmd" value="step3" />
<div>Subscriptions:</div>
    %subscriptions_scrolling%
<br />
<input type="button" value="&lt;&lt;Back" onClick="location='$SELF_URL?cmd=step1;CGISESSID=%_session_id%'"/>
<input type="button" value="Cancel" onClick="clearTheForm(this.form)" />
<input type="submit" value="Next &gt;&gt;" />
</form>
HTML
    return template(\$HTML, $cgi, $session);
}



sub step3 {
    my ($cgi, $session) = @_;

    $session->save_param($cgi, ["subscriptions"]);
    $session->load_param($cgi, ["subscriptions"]);

    my $HTML = <<HTML;
<h4>Step 3 out of 3 - final!</h4>
<p>Dear %name%.</p>
<p>
Before you finalize your subscription, you need to review the following<br />
information you have submitted. Update if necessary. <br />
When you are down, click on "Finish" button. Voila!
</p>

<form method="post">
<input type="hidden" name="CGISESSID" value="%_session_id%" />
<input type="hidden" name="cmd" value="finish" />


<div><b>Your Profile</b> [<a href="%edit_profile%">edit</a>]</div>

<table border="0" cellpadding="2" cellspacing="0"
  frame="void" rules="none" summary="">
    <tr>
        <td>Name:</td>
        <td>%name%</td>
    </tr>
    <tr>
        <td>Email address:</td>
        <td><a href="mailto:%email%">%email%</a></td>
    </tr>
    <tr>
        <td>Your website:</td>
        <td><a href="%website%">%website%</a></td>
    </tr>
</table>

<br />

<div><b>Your Subscriptions</b> [<a href="%edit_subs%">edit</a>]</div>

%subscriptions_checkbox%

<input type="button" value="&lt;&lt;Back" onClick="location='$SELF_URL?cmd=step2;CGISESSID=%_session_id%'" />
    <input type="button" value="Update" onClick="updateTheForm(this.form)" />
    <input type="button" value="Cancel" onClick="clearTheForm(this.form)" />
    <input type="submit" value="Finish" />
</form>
HTML
    return template(\$HTML, $cgi, $session);
}




sub finish {
    my ($cgi, $session) = @_;

    my $to = sprintf("%s <%s>", $session->param('name'),
                                $session->param('email'));
    my $msg = MIME::Lite->new(
        From        => 'Sherzod Ruzmetov <sherzodr@cpan.org>',
        To          => $to,
        Subject     => 'CGI-Session Demo',
        Type        => 'multipart/mixed'
    );

    $msg->attach(   Type => 'text/plain',
                    Data => _data($cgi, $session));
    $msg->attach(   Type => 'application/octet-stream',
                    Path => $0,
                    Filename => 'session.cgi'
    );


    open(SENDMAIL, "|/usr/sbin/sendmail -t -oi") or die $!;
    $msg->print(\*SENDMAIL);
    close(SENDMAIL);

    $session->clear();
    return $cgi->redirect(-uri=>$ENV{SCRIPT_NAME});

}



sub _data {
    my ($cgi, $session) = @_;

    my $HTML = <<'HTML';
Thank you, %name%, for trying out our CGI::Session Demo Application.
Here are the information you submitted to the script. Notice that
we're also attaching the source code of the script to this email
together with the session object dump at the time this email was
being sent.

+-------------------------
| Personal Info:
+-------------------------
    name:       %name%
    email:      %email%
    website:    %website%

+-------------------------
| Subscriptions:
+-------------------------
%subscriptions_plain%

+-------------------------
| Session Object Dump:
+-------------------------
    %dump%


Regards,

Sherzod Ruzmetov <sherzodr@cpan.org>
HTML

    return template(\$HTML, $cgi, $session, 1);

}



sub template {
    my ($HTML, $cgi, $session, $no_html) = @_;
    my $t = HTML::Template->new( scalarref=>$HTML,
                                vanguard_compatibility_mode=>1,
                                associate => [$session, $cgi] );

    my @papers = (
        "The Perl Journal",
        "The SysAdmin Magazine",
        "The Coolest CGI::Session tricks mailing list",
        "XML.com weekly news and updates",
        "Perl5porters mailing list",
    );

    my $sid = $session->id();

    $t->param(
        edit_profile  => "$SELF_URL?cmd=step1;CGISESSID=$sid",
        edit_subs     => "$SELF_URL?cmd=step2;CGISESSID=$sid",
        subscriptions_scrolling => $cgi->scrolling_list(
                            -name=>'subscriptions',
                            -values => \@papers,
                            -size => 5,
                            -multiple => 1),

        subscriptions_checkbox => scalar($cgi->checkbox_group(
                            -name=>'subscriptions',
                            -values => \@papers, -linebreak=>1)),
        'dump'            => $session->dump(undef, 1),
    );

    if ( $no_html ) {
        return $t->output();
    }

    my $cookie = $cgi->cookie(-name=>CGI::Session->name(), -value=>$sid, -expires=>"+10h");

    $HTML = $cgi->header(-cookie=>$cookie) .
        $cgi->start_html(-title=>"CGI::Session Test Script", -script=>{code=>_js()},
        -style => {code=>_css()} ) .
        $t->output();

    unless ( $cgi->param("cmd") ) {
        $cgi->param(cmd => 'directions');
    }

    my $dump_url = sprintf("%s?cmd=show-dump;CGISESSID=%s;ref=%s",
            $SELF_URL, $sid, uri_escape($cgi->self_url()));

    if ( $session->param("_display_dump") ) {
        $HTML .= $cgi->a({-href=>$dump_url}, "hide-dump");
        $HTML .= $cgi->pre($session->dump(undef, 1));
    } else {
        $HTML .= $cgi->a({-href=>$dump_url}, "show-dump");
    }

    $HTML .= $cgi->end_html();

    return $HTML;
}


sub show_dump {
    my ($cgi, $session) = @_;

    if ( $session->param("_display_dump") ) {
        $session->clear(["_display_dump"]);

    } else {
        $session->param(_display_dump => 1);
    }

    return $cgi->redirect(-uri=>$cgi->param('ref') );
}



sub clear {
    my ($cgi, $session) = @_;
    $session->clear([$session->param()]);

    return $cgi->redirect(-uri=>$ENV{SCRIPT_NAME});
}



sub _js {
    return <<'JS';
function clearTheForm(obj) {
    if ( confirm("If you cancel the form, all your previously submitted data will be lost. Are you sure you want to continue?") ) {
        obj["cmd"].value = "clear";
        obj.submit();
        return true;
    }
    return false;
}
function updateTheForm(obj) {
    obj["cmd"].value = "step3";
    obj.submit();
    return true;
}
JS
}




sub _css {
    return <<'CSS';
Body {
    background-color:White;
    margin:         70px;
}

P {
    width:          600px;
    font-family:    Verdana, Arial, Sans-serif;
    font-size:      13px;
}

CSS
}


# $Id$
