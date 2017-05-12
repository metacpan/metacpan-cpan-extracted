package Sample::Apache2::AuthCookieHandler;

use strict;
use utf8;
use Class::Load 'load_class';
use Apache2::Const qw(:common HTTP_FORBIDDEN);
use Apache2::AuthCookie;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Util;
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use Encode qw(decode);
use vars qw(@ISA);

use Apache::Test;
use Apache::TestUtil;

if (have_min_apache_version('2.4.0')) {
    load_class('Apache2_4::AuthCookie');
    @ISA = qw(Apache2_4::AuthCookie);
}
else {
    load_class('Apache2::AuthCookie');
    @ISA = qw(Apache2::AuthCookie);
}

sub authen_cred ($$\@) {
    my $self = shift;
    my $r = shift;
    my @creds = @_;

    $r->server->log_error("authen_cred entry");

    return if $creds[0] eq 'fail'; # simulate bad_credentials

    # This would really authenticate the credentials 
    # and return the session key.
    # Here I'm just using setting the session
    # key to the escaped credentials and delaying authentication.
    return join ':', map { uri_escape_utf8($_) } @creds;
}

sub authen_ses_key ($$$) {
    my ($self, $r, $cookie) = @_;

    my ($user, $password) =
        map { decode('UTF-8', uri_unescape($_)) }
        split /:/, $cookie, 2;

    $r->server->log_error("authen_ses_key entry");

    $r->server->log_error("user=$user pass=$password cookie=$cookie");

    if ($user eq 'programmer' && $password eq 'Hero') {
        return $user;
    }
    elsif ($user eq 'some-user') {
        return $user;
    }
    elsif ($user eq '0') {
        return $user;
    }
    elsif ($user eq '程序员') { # programmer in chinese, at least according to google translate
        return $user;
    }
    else {
        return;
    }
}

sub dwarf {
    my $self = shift;
    my $r = shift;

    $r->server->log_error("dwarf entry");

    my $user = $r->user;

    $r->server->log_error("USER=$user");

    if ("bashful doc dopey grumpy happy sleepy sneezy programmer" =~ /\b$user\b/) {
        # You might be thinking to yourself that there were only 7
        # dwarves, that's because the marketing folks left out
        # the often under appreciated "programmer" because:
        #
        # 10) He didn't hold 8 to 5 hours.
        # 9)  Sometimes forgot to shave several days at a time.
        # 8)  Was always buzzed on caffine.
        # 7)  Wasn't into heavy labor.
        # 6)  Prone to "swearing while he worked."
        # 5)  Wasn't as easily controlled as the other dwarves.
        # 
        # 1)  He posted naked pictures of Snow White to the Internet.
        return OK;
    }

    return HTTP_FORBIDDEN;
}

sub login_form_handler {
    my ($self, $r) = @_;

    my $uri = $r->prev->uri;

    my $args = $r->prev->args;
    if ($args) {
        $uri .= "?$args";
    }

    my $reason = $r->prev->subprocess_env('AuthCookieReason');

    my $form = <<HERE;
<HTML>
<HEAD>
<TITLE>Enter Login and Password</TITLE>
</HEAD>
<BODY onLoad="document.forms[0].credential_0.focus();">
<FORM METHOD="POST" ACTION="/LOGIN">
<TABLE WIDTH=60% ALIGN=CENTER VALIGN=CENTER>
<TR><TD ALIGN=CENTER>
<H1>This is a secure document</H1>
</TD></TR>
<TR><TD ALIGN=LEFT>
<P>Failure reason: '$reason'.  Please enter your login and password to authenticate.</P>
</TD>
<TR><TD>
<INPUT TYPE=hidden NAME=destination VALUE="$uri">

</TD></TR>
<TR><TD>
<TABLE ALIGN=CENTER>
<TR>
<TD ALIGN=RIGHT><B>Login:</B></TD>
<TD><INPUT TYPE="text" NAME="credential_0" SIZE=10 MAXLENGTH=10></TD>
</TR>
<TR>
<TD ALIGN=RIGHT><B>Password:</B></TD>
<TD><INPUT TYPE="password" NAME="credential_1" SIZE=8 MAXLENGTH=8></TD>
</TR>
<TR>
<TD COLSPAN=2 ALIGN=CENTER><INPUT TYPE="submit" VALUE="Continue"></TD>
</TR></TABLE>
</TD></TR></TABLE>
</FORM>
</BODY>
</HTML>
HERE

    $r->no_cache(1);
    $r->content_type('text/html');
    my $len = length $form;
    $r->headers_out->set('Content-length', $len);
    $r->headers_out->set('Pragma', 'no-cache');
    $r->print($form);

    return OK;
}

1;
