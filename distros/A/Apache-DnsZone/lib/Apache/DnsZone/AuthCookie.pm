package Apache::DnsZone::AuthCookie;

# $Id: AuthCookie.pm,v 1.8 2001/06/03 11:10:23 thomas Exp $

use strict;
use vars qw(@ISA $VERSION);

use Apache::Constants qw(OK);
use Apache::AuthTicket ();
use Apache::AuthCookie ();
use Apache::DnsZone;
use Apache::DnsZone::Config;
use Apache::DnsZone::Language;
use Apache::DnsZone::DB;
use CGI::FastTemplate ();
use DBI;
use Digest::MD5 qw(md5_hex);

($VERSION) = qq$Revision: 1.8 $ =~ /([\d\.]+)/;
@ISA = qw(Apache::AuthTicket);

sub make_login_screen {
    my ($self, $r, $action, $destination) = @_;
    my $reason = $r->prev->subprocess_env("AuthCookieReason");
    my $ticket_reason = undef;
    Apache::DnsZone::Debug(5, qq{make_login_screen called});
    if ($reason eq 'bad_cookie') {
	$ticket_reason = $r->prev->subprocess_env("AuthTicketReason");
    }

    my $cfg = Apache::DnsZone::Config->new($r);

    my $lang = $cfg->{'cfg'}->{DnsZoneLoginLang}; # choose default login language

    if (my $accept_lang = $r->header_in('Accept-Language')) {
	my $dbh = Apache::DnsZone::DB->new($cfg);
	my @lang = $accept_lang =~ /([^,\s]+)/g;
	foreach my $in_lang (@lang) {
	    next unless $in_lang =~ /^[a-z]{2}$/;
	    # look up abbrev in db and get language 
	    if ($dbh->is_valid_abbrev($in_lang)) {
		$lang = $dbh->get_lang_from_abbrev($in_lang);
		last;
	    }
	}
	$dbh->close();
    }

    my %lang = Apache::DnsZone::Language->fetch($cfg, $lang);
    

    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
    $tpl->define(layout => 'layout.tpl', login => 'login.tpl');
    $tpl->assign(%lang);
    $tpl->assign(TITLE => $lang{'PAGE_LOGIN'});
    $tpl->assign(DEBUG => '');
    
    $tpl->assign(DESTINATION => $destination);
    $tpl->assign(FORM_ACTION => $action);
    if ($ticket_reason) {
	$tpl->assign(LOGIN_ERROR => $lang{uc($ticket_reason)} . "<br>");
    } else {
	$tpl->assign(LOGIN_ERROR => '');
    }
    $tpl->assign(MENU => '&nbsp;');
    $tpl->parse(MAIN => ["login", "layout"]);

    my $content_ref = $tpl->fetch("MAIN");

    Apache::DnsZone::output_headers($r, 1, length(${$content_ref}));

    $r->print(${$content_ref});

    return OK;
}

sub dbi_connect {
    my ($this) = @_;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::AuthCookie::dbi_connect called});    
    my $r = $this->request;
    
    my $cfg = Apache::DnsZone::Config->new($r);
    my $dbh = Apache::DnsZone::DB->new($cfg);

    return $dbh->db();
}

1;

__END__


