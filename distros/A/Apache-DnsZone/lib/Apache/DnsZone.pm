package Apache::DnsZone;

# $Id: DnsZone.pm,v 1.37 2001/06/12 23:28:26 thomas Exp $

use strict;
use Exporter;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA);

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(Debug);
%EXPORT_TAGS = ();
$VERSION = '0.1';

use Apache ();
use Apache::Constants qw(:common REDIRECT);
use Apache::Request ();
use Apache::DnsZone::Config;
use Apache::DnsZone::Resolver;
use Apache::DnsZone::DB;
use Apache::DnsZone::Language;
use Apache::DnsZone::AuthCookie;
use Net::DNS;
use HTML::Entities;
use Email::Valid;
use CGI::FastTemplate;
use Data::Dumper;

my %lang = ();
my $cfg;
my $res;
my $dbh;
my $apr;
my $DebugLevel = 1;

sub init {
    my $r = shift || Apache->request();
    $cfg = Apache::DnsZone::Config->new($r);
    $res = Apache::DnsZone::Resolver->new();
    $dbh = Apache::DnsZone::DB->new($cfg);
    $apr = Apache::Request->instance($r, DISABLE_UPLOADS => 1, POST_MAX => 1024);
    my $status = $apr->parse;
    if ($status) {
	my $errmsg = $apr->notes("error-notes");
	Debug(1, qq{Apache::Request error: $errmsg});
	return $status;
    }
}

sub Debug {
    my $level = shift;
    if ($level <= $Apache::DnsZone::DebugLevel) {
	if ($_[-1] !~ /\n$/) {
	    warn("[DnsZone]: ", @_, "\n");
	} else {
	    warn("[DnsZone]: ", @_);
	}
    }
}

sub lang {
    my $lang = shift;
    return Apache::DnsZone::Language->fetch($cfg, $lang);
}

sub apr {
    return $apr;
}

sub cfg {
    return $cfg->{'cfg'};
}

###############################################
# check_ip(ip)                                #
# Checks ip for a valid ip address for a host #
# returns 0 on anything else than valid ip    #
###############################################

sub check_ip ($) {
    my $ip = shift;
    Debug(5, qq{check_ip($ip)});
    $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    return 0 unless ($1 >= 1 && $1 <= 254 && $2 >= 0 && $2 <= 255 && $3 >= 0 && $3 <= 255 && $4 >= 1 && $4 <= 254);
    # By using int on the values we make sure that the user can't enter data that will corrupt the database. 
    # IP addresses like 001.001.001.001 are avoided and will only show 1.1.1.1
    return join ".", int(${1}), int(${2}), int(${3}), int(${4});
}

############################################
# check_chars(fqdn)                        #
# checks for valid-only characters in fqdn #
############################################

sub check_chars ($) {
    my $name = shift;
    Debug(5, qq{check_chars($name)});
    return 0 unless ($name =~ m/^[a-z0-9\-\.\*]+$/i);
    return 1;
}

sub check_chars_cname ($) {
    my $name = shift;
    Debug(5, qq{check_chars_cname($name)});
    return 0 unless ($name =~ m/^[a-z0-9\-\.]+$/i);
    return 1;
}

sub check_chars_ns ($) {
    my $name = shift;
    Debug(5, qq{check_chars_ns($name)});
    return 0 unless ($name =~ m/^[a-z0-9\-\.]+$/i);
    return 1;
}

sub check_chars_domain ($) {
    my $name = shift;
    Debug(5, qq{check_chars_domain($name)});
    return 0 unless ($name =~ m/^[a-z0-9\-\.]+$/i);
    return 1;
}

##################################################################################
# check_host(host)                                                               #
# checks a hostname only for the valid sequence of chars that make up a hostname #
##################################################################################

sub check_host ($) {
    my $name = shift;
    Debug(5, qq{check_host($name) called\n});
#    return 0 unless check_chars($name);
    return 0 unless ($name =~ /^(?:\*|(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?))(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*\.?$/i);
    return 1;
}

sub check_host_cname ($) {
    my $name = shift;
    Debug(5, qq{check_host_cname($name) called\n});
#    return 0 unless check_chars_cname($name);
    return 0 unless ($name =~ /^(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*\.?$/i);
    return 1;
}

sub check_host_ns ($) {
    my $name = shift;
    Debug(5, qq{check_host_ns($name) called\n});
#    return 0 unless check_chars_ns($name);
    return 0 unless ($name =~ /^(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*\.?$/i);
    return 1;
}

sub check_host_exchanger ($) {
    my $name = shift;
    Debug(5, qq{check_host_exchanger($name) called\n});
#    return 0 unless check_chars_exchanger($name);
    return 0 unless ($name =~ /^(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*\.?$/i);
    return 1;
}

##########################################################
# check_fqdn(host, domain)                               #
# checks whetever domain is at end of host               #
# returns the host with appened domain name if necessary #
##########################################################

sub check_fqdn ($$) {
    my $host = shift;
    my $domain = shift;
    Debug(5, qq{check_fqdn($host, $domain) called\n});
    return 0 unless (check_chars($host) && check_chars_domain($domain));
    return 0 unless (check_host($host));
    return 0 unless (length($host) <= 255);
    return $host if ($host =~ /^$domain$/i || $host =~ /\.$domain$/i);
    return 0 unless (length($host . $domain) <= 255);
    return "$host$domain" if ($host =~ /\.$/);
    return 0 unless (length($host . "." . $domain) <= 255);
    return "$host.$domain";
}

#sub check_fqdn_cname ($$) {
#    my $host = shift;
#    my $domain = shift;
#    Debug(5, qq{check_fqdn_cname($host, $domain) called\n});
#    return 0 unless (check_chars_cname($host) && check_chars_domain($domain));
#    return 0 unless (check_host_cname($host));
#    return $host if ($host =~ /^$domain$/i || $host =~ /\.$domain$/i);
#    return "$host$domain" if ($host =~ /\.$/);
#    return "$host.$domain";
#}

sub check_fqdn_ns ($$) {
    my $host = shift;
    my $domain = shift;
    Debug(5, qq{check_fqdn_ns($host, $domain) called\n});
    return 0 unless (check_chars_ns($host) && check_chars_domain($domain));
    return 0 unless (check_host_ns($host));
    return 0 unless (length($host) <= 255);
    return $host if ($host =~ /^$domain$/i || $host =~ /\.$domain$/i);
    return 0 unless (length($host . $domain) <= 255);
    return "$host$domain" if ($host =~ /\.$/);
    return 0 unless (length($host . "." . $domain) <= 255);
    return "$host.$domain";
}

########################################################
# check_cname_host(host)                               #
# checks host for invalid chars and other invalidities #
########################################################

sub check_cname_host ($) {
    my $host = shift;
    Debug(5, qq{check_cname_host($host) called\n});
    return 0 unless (check_chars_cname($host));
    return 0 unless (check_host_cname($host));
    return 0 unless (length($host) <= 255);
    return 1;
}

########################################################
# check_exchanger(host)                                #
# checks host for invalid chars and other invalidities #
########################################################

sub check_exchanger ($) {
    my $host = shift;
    Debug(5, qq{check_exchanger($host) called\n});
    return 0 unless (check_chars($host));
    return 0 unless (check_host_exchanger($host));
    return 0 unless (length($host) <= 255);
    return 1;
}

########################################################
# check_nameserver(host)                               #
# checks host for invalid chars and other invalidities #
########################################################

sub check_nameserver ($) {
    my $host = shift;
    Debug(5, qq{check_nameserver($host) called\n});
    return 0 unless (check_chars($host));
    return 0 unless (check_host_ns($host));
    return 0 unless (length($host) <= 255);
    return 1;
}

#######################################################
# check_txt(txt)                                      #
# checks txt for invalid chars and other invalidities #
#######################################################

sub check_txt ($) {
    my $txt = shift;
    Debug(5, qq{check_txt($txt) called\n});
    return 0 unless $txt =~ /^[\s\w\d\.\-_]+$/;
    return 0 unless (length($txt) <= 255);
    # needs more checkups!
    return 1;
}

#########################################################
# check_email(email)                                    #
# Checks user entered email addresses with Email::Valid #
# Returns address if ok, otherwise 0                    #
#########################################################

sub check_email ($) {
    my $email = shift;
    Debug(5, qq{check_email($email) called\n});
    my $addr = Email::Valid->address($email);
    return 0 unless (length($addr) <= 255);
    return $addr if $addr;
    return 0;
}

##############################################
# get_serial_from_zone(domain_id)            #
# fetches serial from authorative nameserver #
##############################################

sub get_serial_from_zone ($) {
    my $domain_id = shift;
    Debug(5, qq{get_serial_from_zone($domain_id) called\n});
    my $domain = $dbh->id2domain($domain_id);
    resolver_setup($domain_id);
    my $query = $res->res->query($domain, "SOA");
    my $rr = ($query->answer)[0];
    return $rr->serial;
}

##############################################################
# update_serial(domain_id)                                   #
# updates zone serial in db from serial taken from real zone #
##############################################################

sub update_serial ($) {
    my $domain_id = shift;
    Debug(5, qq{update_serial($domain_id) called\n});
    my $serial = get_serial_from_zone($domain_id);
    $dbh->update_serial_soa($domain_id, $serial);
}

######################################
# check_ttl(ttl)                     #
# checks for ttl to be an int of > 0 #
######################################

sub check_ttl {
    my $ttl = shift;
    Debug(5, qq{check_ttl($ttl) called\n});
    if ($ttl =~ /^\d+$/) {
	if ($ttl == 0) {
	    return 0;
	} else {
	    if (length($ttl) <= 7) {
		return 1;
	    } else {
		return 0;
	    }
	}
    } else {
	return 0
    }
    return 0;
}

###################################
# check_lang(lang)                #
# checks for lang to be in the db #
###################################

sub check_lang {
    my $lang = shift;
    Debug(5, qq{check_lang($lang) called\n});
    if ($lang =~ /^\d+$/) {
	if ($lang == 0) {
	    return 0;
	} else {
	    return $dbh->is_valid_lang($lang);
	}
    } else {
	return 0
    }
    return 0;
}

############################################
# check_preference(preference)             #
# checks for preferece to be an int of > 0 #
############################################

sub check_preference {
    my $preference = shift;
    Debug(5, qq{check_preference($preference) called\n});
    if ($preference =~ /^\d+$/) {
	if (length($preference) <= 3) {
	    return 1;
	} else {
	    return 0;
	}
    } else {
	return 0
    }
    return 0;
}

##########################################################################################
# resolver_setup(domain_id)                                                              #
# Simply sets up the resolver for getting ready to update that domain                    #
# Makes sure that no matter which data the user enters it can only affect his own domain #
##########################################################################################

sub resolver_setup ($) {
    my $dom_id = shift;
    my ($domain, $nameserver) = $dbh->domain2ns($dom_id);
    Debug(4, qq{resolver_setup($dom_id) called ($domain, $nameserver)\n});
    $res->res->nameservers($nameserver);
    $res->res->domain($domain);
    $res->res->searchlist($domain);
    $res->res->tcp_timeout(5);
#    $res->res->print;
}

###################################
# check_for_conflicts($host)      # 
# check for conflicting hostnames #
###################################

sub check_for_conflicts {

}

#############################################
# output_headers($r, $cache, $length)       # 
# output headers, w w/o cache, w w/o length #
#############################################

sub output_headers {
    my $r = shift || Apache->request();
    my $cache = shift || 0;
    my $length = shift || 0;
    Debug(5, qq{output_headers(\$r, $cache, $length) called\n});    
    $r->content_type('text/html');

    if ($cache != 0) {
	$r->header_out("Pragma", "no-cache");
	$r->header_out("Cache-control", "no-cache");
	$r->no_cache(1);
    }
    if ($length != 0) {
	$r->header_out("Content-Length", $length);
    }

    $r->send_http_header();
}

##########################################
# output_redirect($r, $cache, $location) # 
# output redirect, w w/o cache, location #
##########################################

sub output_redirect {
    my $r = shift || Apache->request();
    my $cache = shift || 0;
    my $location = shift || 0;
    Debug(5, qq{output_redirect(\$r, $cache, $location) called\n});
    $r->content_type('text/html');

    if ($cache != 0) {
	$r->header_out("Pragma", "no-cache");
	$r->header_out("Cache-control", "no-cache");
	$r->no_cache(1);
    }

    $r->header_out(Location => $location);
}

sub is_updated_SOA {
    my $dom_id = shift;
    my $new_email = shift;
    my $new_refresh = shift;
    my $new_retry = shift;
    my $new_expire = shift;
    my $new_ttl = shift;
    my ($old_auth_ns, $old_email, $old_serial, $old_refresh, $old_retry, $old_expire, $old_ttl, $rec_lock) = $dbh->soa_lookup($dom_id);
    return 0 if $old_email eq $new_email && $old_refresh == $new_refresh && $old_retry == $new_retry && $old_expire == $new_expire && $old_ttl == $new_ttl;
    return 1;
}

sub check_before_add_A {
    my $dom_id = shift;
    my $host = shift;
    my $address = shift;
    Debug(5, qq{check_before_add_A($dom_id, $host, $address) called});
    if ($dbh->is_duplicate_A($dom_id, $host, $address)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $host)) {
	return 0;
    }
    # no A record exists that has the same address, no CNAME record exists with the same name
    return 1;
}

sub check_before_edit_A {
    my $dom_id = shift;
    my $a_id = shift;
    my $new_host = shift;
    my $new_address = shift;
    Debug(5, qq{check_before_edit_A($dom_id, $a_id, $new_host, $new_address) called});
    my ($old_name, $old_address, $old_ttl) = $dbh->a_lookup($dom_id, $a_id);
    return 1 if $old_name eq $new_host && $old_address eq $new_address;
    if ($dbh->is_duplicate_A($dom_id, $new_host, $new_address)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $new_host)) {
	return 0;
    }
    return 1;
}

sub is_updated_A {
    my $dom_id = shift;
    my $a_id = shift;
    my $new_host = shift;
    my $new_address = shift;
    my $new_ttl = shift;
    my ($old_name, $old_address, $old_ttl) = $dbh->a_lookup($dom_id, $a_id);
    return 0 if $old_name eq $new_host && $old_address eq $new_address && $old_ttl == $new_ttl;
    return 1;
}

sub check_before_add_CNAME {
    my $dom_id = shift;
    my $host = shift;
    Debug(5, qq{check_before_add_CNAME($dom_id, $host) called});
    if ($dbh->does_A_exist($dom_id, $host)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $host)) {
	return 0;
    }
    if ($dbh->does_MX_exist($dom_id, $host)) {
	return 0;
    }
    if ($dbh->does_NS_exist($dom_id, $host)) {
	return 0;
    }
    if ($dbh->does_TXT_exist($dom_id, $host)) {
	return 0;
    }
    return 1;
}

sub check_before_edit_CNAME {
    my $dom_id = shift;
    my $cname_id = shift;
    my $new_host = shift;
    my $new_cname = shift;
    Debug(5, qq{check_before_edit_CNAME($dom_id, $cname_id, $new_host, $new_cname) called});
    my ($old_host, $old_cname, $old_ttl) = $dbh->cname_lookup($dom_id, $cname_id);
    return 1 if $old_host eq $new_host && $old_cname eq $new_cname;
    return 1 if $old_host eq $new_host;
    if ($dbh->does_A_exist($dom_id, $new_host)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $new_host)) {
	return 0;
    }
    if ($dbh->does_MX_exist($dom_id, $new_host)) {
	return 0;
    }
    if ($dbh->does_NS_exist($dom_id, $new_host)) {
	return 0;
    }
    if ($dbh->does_TXT_exist($dom_id, $new_host)) {
	return 0;
    }
    return 1;
}

sub is_updated_CNAME {
    my $dom_id = shift;
    my $cname_id = shift;
    my $new_host = shift;
    my $new_cname = shift;
    my $new_ttl = shift;
    my ($old_host, $old_cname, $old_ttl) = $dbh->cname_lookup($dom_id, $cname_id);
    return 0 if $old_host eq $new_host && $old_cname eq $new_cname && $old_ttl == $new_ttl;
    return 1;
}

sub check_before_add_MX {
    my $dom_id = shift;
    my $host = shift;
    my $exchanger = shift;
    my $preference = shift;
    Debug(5, qq{check_before_add_MX($dom_id, $host, $exchanger, $preference) called});
    if ($dbh->is_duplicate_MX($dom_id, $host, $preference)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $host)) {
	return 0;
    }
    return 1;
}

sub check_before_edit_MX {
    my $dom_id = shift;
    my $mx_id = shift;
    my $new_host = shift;
    my $new_exchanger = shift;
    my $new_preference = shift;
    Debug(5, qq{check_before_edit_MX($dom_id, $mx_id, $new_host, $new_exchanger, $new_preference) called});
    my ($old_name, $old_exchanger, $old_preference, $old_ttl) = $dbh->mx_lookup($dom_id, $mx_id);
    return 1 if $old_name eq $new_host && $old_preference eq $new_preference;
    if ($dbh->is_duplicate_MX($dom_id, $new_host, $new_preference)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $new_host)) {
	return 0;
    }
    return 1;
}

sub is_updated_MX {
    my $dom_id = shift;
    my $mx_id = shift;
    my $new_host = shift;
    my $new_exchanger = shift;
    my $new_preference = shift;
    my $new_ttl = shift;
    my ($old_name, $old_exchanger, $old_preference, $old_ttl) = $dbh->mx_lookup($dom_id, $mx_id);
    return 0 if $old_name eq $new_host && $old_preference == $new_preference && $old_exchanger eq $new_exchanger && $old_ttl == $new_ttl;
    return 1;
}

sub check_before_add_NS {
    my $dom_id = shift;
    my $host = shift;
    my $nsdname = shift;
    Debug(5, qq{check_before_add_NS($dom_id, $host, $nsdname) called});
    if ($dbh->is_duplicate_NS($dom_id, $host, $nsdname)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $host)) {
	return 0;
    }
    return 1;
}

sub check_before_edit_NS {
    my $dom_id = shift;
    my $ns_id = shift;
    my $new_host = shift;
    my $new_ns = shift;
    Debug(5, qq{check_before_edit_NS($dom_id, $ns_id, $new_host, $new_ns) called});
    my ($old_name, $old_nameserver, $old_ttl) = $dbh->ns_lookup($dom_id, $ns_id);
    return 1 if $old_name eq $new_host && $old_nameserver eq $new_ns;
    if ($dbh->is_duplicate_NS($dom_id, $new_host, $new_ns)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $new_host)) {
	return 0;
    }
    return 1;
}

sub is_updated_NS {
    my $dom_id = shift;
    my $ns_id = shift;
    my $new_host = shift;
    my $new_ns = shift;
    my $new_ttl = shift;
    my ($old_name, $old_nameserver, $old_ttl) = $dbh->ns_lookup($dom_id, $ns_id);
    return 0 if $old_name eq $new_host && $old_nameserver eq $new_ns && $old_ttl == $new_ttl;
    return 1;
}

sub check_before_add_TXT {
    my $dom_id = shift;
    my $host = shift;
    my $txt = shift;
    Debug(5, qq{check_before_add_TXT($dom_id, $host, $txt) called});
    if ($dbh->is_duplicate_TXT($dom_id, $host, $txt)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $host)) {
	return 0;
    }
    return 1;
}

sub check_before_edit_TXT {
    my $dom_id = shift;
    my $txt_id = shift;
    my $new_host = shift;
    my $new_txt = shift;
    Debug(5, qq{check_before_edit_TXT($dom_id, $txt_id, $new_host, $new_txt) called});
    my ($old_name, $old_txt, $old_ttl) = $dbh->txt_lookup($dom_id, $txt_id);
    return 1 if $old_name eq $new_host && $old_txt eq $new_txt;
    if ($dbh->is_duplicate_TXT($dom_id, $new_host, $new_txt)) {
	return 0;
    }
    if ($dbh->does_CNAME_exist($dom_id, $new_host)) {
	return 0;
    }
    return 1;
}

sub is_updated_TXT {
    my $dom_id = shift;
    my $txt_id = shift;
    my $new_host = shift;
    my $new_txt = shift;
    my $new_ttl = shift;
    my ($old_name, $old_txt, $old_ttl) = $dbh->txt_lookup($dom_id, $txt_id);
    return 0 if $old_name eq $new_host && $old_txt eq $new_txt && $old_ttl == $new_ttl;
    return 1;
}

sub handler {
    my $r = shift || Apache->request();
    Debug(2, qq{Apache::DnsZone::handler called});
    if ($r->header_only) {
	$r->send_http_header;
	return OK;
    }
    init($r);
    # lang is setup for the whole process of the script here
    my $user = $r->connection->user;
    my ($lang) = $dbh->get_user_lang($user);
    %lang = lang($lang);

    my $uri = $r->uri;
    if ($uri !~ m|^/admin|) {
	return DECLINED;
    } 

    # Internal dispatch based on parameters to the url

    if (apr()->param('action')) {
	my $action = lc(apr()->param('action'));
	my $button = "";
	if (apr->param('button')) {
	    $button = lc(apr()->param('button'));
	    if ($button eq lc($lang{'CANCEL'})) {
	        Debug(3, qq{pushing cancel() to PerlHandler (called from a pushed button)});
		$r->push_handlers(PerlHandler => \&cancel);
		return OK;
#	    } elsif ($button eq lc($lang{'HELP'})) {
#	        DnsZone::Debug(3, qq{pushing help() to PerlHandler (called from a pushed button)});
#		$r->push_handlers(PerlHandler => \&help);
#		return OK;
	    } 
	}
	if ($action eq 'view') {
	    Debug(3, qq{pushing view_domain() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&view_domain);
	} elsif ($action eq 'edit') {
	    Debug(3, qq{pushing edit_record() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&edit_record);
	} elsif ($action eq 'add') {
	    Debug(3, qq{pushing add_record() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&add_record);
        } elsif ($action eq 'delete') {
  	    Debug(3, qq{pushing delete_record() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&delete_record);
        } elsif ($action eq 'settings') {
  	    Debug(3, qq{pushing settings() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&settings);
	} elsif ($action eq 'logout') {
	    Debug(3, qq{pushing logout() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&logout);
	} else {
  	    Debug(3, qq{pushing default_page_handler() to PerlHandler});
	    $r->push_handlers(PerlHandler => \&default_page_handler);
	}
    } else {
        Debug(3, qq{pushing default_page_handler() to PerlHandler});
	$r->push_handlers(PerlHandler => \&default_page_handler);
    }
    return OK;
}

sub default_page_handler {
    my $r = shift || Apache->request();
    Debug(3, qq{calling default_page_handler()});
    init($r);
    my $user = $r->connection->user;
    my ($uid, $email, $lang_id, $lang) = $dbh->get_user_info($user);
    my $dom_count = $dbh->get_domain_count($uid);
    if ($dom_count == 1) {
	# In case the user only has one domain we redirect to his admin page right away
	my $dom_id = $dbh->get_one_domain_id($uid);
	output_redirect($r, 1, qq{/admin?action=view&dom_id=$dom_id});
	$dbh->close();
	return REDIRECT;
    } else {
	# make a list of domains to manage
	$r->push_handlers(PerlHandler => \&list_domains);
    }
    $dbh->close();
    return OK;
}

sub logout {
    my $r = shift || Apache->request();
    Debug(3, qq{calling logout()});
    init($r);
    output_redirect($r, 1, $cfg->{'cfg'}->{DnsZoneLogoutHandler});
#    $r->push_handlers(PerlHandler => sub {
#      Apache::DnsZone::AuthCookie->logout(Apache->request);
#    });
    $dbh->close();
    return REDIRECT;
}

sub list_domains {
    my $r = shift || Apache->request();
    Debug(3, qq{calling list_domains()});
    init($r); 
    my ($uid, $email, $lang_id, $lang) = $dbh->get_user_info($r->connection->user);

    my $sth_dom = $dbh->list_domains_prepare($uid);

    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
    $tpl->define(layout => 'layout.tpl', list => 'list_domain.tpl', record => 'list_domain_record.tpl', menu => 'menu.tpl');
    $tpl->assign(%lang);
    $tpl->assign(TITLE => $lang{'PAGE_LIST_DOMAIN'});
    $tpl->assign(DEBUG => '');
    
    if ($dbh->get_domain_count($uid) == 1) {
	$tpl->assign(ADDITIONAL_MENU => '');
    } else {
	$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
    }

    while (my ($dom_id, $domain) = $sth_dom->fetchrow_array()) {
	$tpl->assign(DOMAIN => qq{<a href="/admin?action=view&dom_id=$dom_id">$domain</a><br>\n});
	$tpl->parse(LIST => ".record");
    }
    $sth_dom->finish();

    $tpl->parse(MENU => "menu");
    $tpl->parse(MAIN => ["list", "layout"]);

    my $content_ref = $tpl->fetch("MAIN");

    output_headers($r, 1, length(${$content_ref}));

    $r->print(${$content_ref});

    $dbh->close();
    return OK;
}

#sub help {
#    my $r = shift || Apache->request();
#    Debug(3, qq{calling help()});
#    init($r);
#
#    unless (apr()->param('type')) {
#	$r->log_reason("No type specified for help");
#	output_redirect($r, 0, '/admin');
#	$dbh->close();
#	return REDIRECT;
#    }
#    my $type = uc apr()->param('type');
#    ($type) = ($type =~ /(\w+)/)[0];
#    if ($type !~ /^\w+$/) {
#	$r->log_reason("User tried to supply bogus type data in the help");
#	output_redirect($r, 0, '/admin');
#	$dbh->close();
#	return REDIRECT;
#    }
#    
#    # do the dispatch of the help
#    # context help, with use of the supplied arguments to build an explanation of what you are trying to do right now?
#    # language sensitive help
#
#    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
#    $tpl->define(layout => 'layout.tpl', help => 'help.tpl');
#    $tpl->assign(%lang);
#    $tpl->assign(TITLE => $lang{'PAGE_HELP'});
#    $tpl->assign(DEBUG => '');
#
#    $tpl->assign(HELP => qq{$type});
#    $tpl->parse(HELP => "help");
#
#    $tpl->parse(MAIN => ["help", "layout"]);
#
#    my $content_ref = $tpl->fetch("MAIN");
#
#    output_headers($r, 1, length(${$content_ref}));
#
#    $r->print(${$content_ref});
#
#    $dbh->close();
#    return OK;
#}

sub cancel {
    my $r = shift || Apache->request();
    Debug(3, qq{calling cancel()});
    init($r);
    if (apr()->param('dom_id')) {
	my $dom_id = apr()->param('dom_id');
	($dom_id) = ($dom_id =~ /(\d+)/)[0];
	if ($dom_id =~ /^\d+$/) {
	    output_redirect($r, 1, qq{/admin?action=view&dom_id=$dom_id});
	    $dbh->close();
	    return REDIRECT;
	}
    }
    output_redirect($r, 1, '/admin?action=default');
    $dbh->close();
    return REDIRECT;
}

sub settings {
    my $r = shift || Apache->request();
    Debug(3, qq{calling settings()});
    init($r); 
    my $user = $r->connection->user;

    if (apr()->param('button') && lc(apr()->param('button')) eq lc($lang{'SUBMIT'})) {
        Debug(5, qq{This is an update of settings request});
	my ($uid) = $dbh->get_user_id($user);

	my $all_set = 1;
	my $user_email = apr()->param('user_email');
	if (!($user_email = check_email($user_email))) {
	    $all_set = 0;
	}
	my $lang_id = apr()->param('lang');
	if (!check_lang($lang_id)) {
	    $all_set = 0;
	}
        if (apr()->param('password') && apr()->param('password_confirm')) {
	    if (apr()->param('password') ne apr()->param('password_confirm')) {
		$all_set = 0;
	    } 
	}
	if ((apr()->param('password') && !apr()->param('password_confirm')) || (!apr()->param('password') && apr()->param('password_confirm'))) {
	    $all_set = 0;
	}
	if ($all_set) {
	    # update email and language
	    Debug(5, qq{Updating email and language settings});
	    $dbh->set_user_lang_email($uid, $lang_id, $user_email);
	    if (apr()->param('password') && apr()->param('password') ne '' && apr()->param('password_confirm') && apr()->param('password_confirm') ne '' && apr()->param('password') eq apr()->param('password_confirm')) {
	        Debug(5, qq{Updating password});
		$dbh->set_user_password($uid, apr()->param('password'));
	    }
	} else {
	    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
	    $tpl->define(layout => 'layout.tpl', settings => 'settings.tpl', menu => 'menu.tpl');
	    $tpl->assign(%lang);
	    $tpl->assign(TITLE => $lang{'PAGE_SETTINGS'});
	    $tpl->assign(DEBUG => '');
	    
	    if ($dbh->get_domain_count($uid) == 1) {
		$tpl->assign(ADDITIONAL_MENU => '');
	    } else {
		$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
	    }

	    $tpl->assign(LANG_VALUE => $dbh->lang_select_box($uid, $lang_id));
	    $tpl->assign(EMAIL_VALUE => encode_entities(apr()->param('user_email')));
	    
	    $tpl->assign(NEW_PASSWORD_VALUE => encode_entities(apr()->param('password')));
	    $tpl->assign(CONFIRM_PASSWORD_VALUE => encode_entities(apr()->param('password_confirm')));
	    
	    if (!($user_email = check_email($user_email))) {
		$tpl->assign(EMAIL => qq{<font color="red">} . $lang{EMAIL} . qq{</font>});
	    }
	    if (!check_lang($lang_id)) {
		$tpl->assign(LANGUAGE => qq{<font color="red">} . $lang{LANGUAGE} . qq{</font>});
	    }
	    if (apr()->param('password') && apr()->param('password') ne '' && apr()->param('password_confirm') && apr()->param('password_confirm') ne '') {
		if (!(apr()->param('password') eq apr()->param('confirm_password'))) {
		    $tpl->assign(NEW_PASSWORD => qq{<font color="red">} . $lang{NEW_PASSWORD} . qq{</font>});
		    $tpl->assign(CONFIRM_PASSWORD => qq{<font color="red">} . $lang{CONFIRM_PASSWORD} . qq{</font>});
		}
	    }
	    if ((apr()->param('password') && !apr()->param('password_confirm')) || (!apr()->param('password') && apr()->param('password_confirm'))) {
		    $tpl->assign(NEW_PASSWORD => qq{<font color="red">} . $lang{NEW_PASSWORD} . qq{</font>});
		    $tpl->assign(CONFIRM_PASSWORD => qq{<font color="red">} . $lang{CONFIRM_PASSWORD} . qq{</font>});
	    }

	    $tpl->parse(MENU => "menu");
	    $tpl->parse(MAIN => ["settings", "layout"]);
	    
	    my $content_ref = $tpl->fetch("MAIN");  
	    
	    output_headers($r, 1, length(${$content_ref}));
	  
	    $r->print(${$content_ref});
    
            $dbh->close();
	    return OK;
	}

        output_redirect($r, 1, '/admin?action=default');

	$dbh->close();
	return REDIRECT;
    } else {
        Debug(5, qq{This is a view of settings request});
	my ($uid, $user_email, $lang_id, $lang) = $dbh->get_user_info($user);

        my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
        $tpl->define(layout => 'layout.tpl', settings => 'settings.tpl', menu => 'menu.tpl');
        $tpl->assign(%lang);
        $tpl->assign(TITLE => $lang{'PAGE_SETTINGS'});
        $tpl->assign(DEBUG => '');
        $tpl->assign(LANG_VALUE => $dbh->lang_select_box($uid, $lang_id));
        $tpl->assign(EMAIL_VALUE => $user_email);

        if ($dbh->get_domain_count($uid) == 1) {
	    $tpl->assign(ADDITIONAL_MENU => '');
	} else {
	    $tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
	}
	  
        $tpl->assign(NEW_PASSWORD_VALUE => '');
	$tpl->assign(CONFIRM_PASSWORD_VALUE => '');

        $tpl->parse(MENU => "menu");
	$tpl->parse(MAIN => ["settings", "layout"]);

	my $content_ref = $tpl->fetch("MAIN");  

        output_headers($r, 1, length(${$content_ref}));

        $r->print(${$content_ref});

	$dbh->close();
	return OK;
    }
}

sub delete_record {
    my $r = shift || Apache->request();
    Debug(3, qq{calling delete_record()});
    init($r);
    my $user = $r->connection->user;
    my ($uid, $email, $lang_id, $lang) = $dbh->get_user_info($user);

    # same as in view_domain() maybe a function should be built for this?
    if (!apr()->param('dom_id')) {
	$r->log_reason("No dom_id for this request: aborting");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check dom_id
    my $dom_id = apr()->param('dom_id');
    ($dom_id) = ($dom_id =~ /(\d+)/)[0];
    if ($dom_id !~ /^\d+$/) {
	$r->log_reason("User didn't supply a domain id for this request or tried to fake it");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # is uid owner of dom_id
    my ($domain, $domain_owner_id) = $dbh->domain_stat($dom_id);
    unless (defined($domain_owner_id) && $uid == $domain_owner_id) {
	$r->log_reason("User trying to hijack another domain");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check for record_id & type
    unless (apr()->param('type')) {
	$r->log_reason("No type specified for edit");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    my $type = uc apr()->param('type');
    ($type) = ($type =~ /(\w+)/)[0];
    if ($type !~ /^\w+$/ || $type =~ /^SOA$/i) {
	$r->log_reason("User tried to supply bogus type data");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    my $record_id = apr()->param('record_id') if apr()->param('record_id');
    ($record_id) = ($record_id =~ /(\d+)/)[0];
    if ($record_id !~ /^\d+$/) {
	$r->log_reason("User didn't supply a record id for this request or tried to fake it");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    # check for rec_lock
    # and at the same time if UID = owner of record
    my $rec_lock = 0;
    for ($type) {
	if (/^A$/) { ($rec_lock) = $dbh->get_lock_A($dom_id, $record_id); }
	elsif (/^CNAME$/) { ($rec_lock) = $dbh->get_lock_CNAME($dom_id, $record_id); }
	elsif (/^MX$/) { ($rec_lock) = $dbh->get_lock_MX($dom_id, $record_id); }
	elsif (/^NS$/) { ($rec_lock) = $dbh->get_lock_NS($dom_id, $record_id); }
	elsif (/^TXT$/) { ($rec_lock) = $dbh->get_lock_TXT($dom_id, $record_id); }
	else { $rec_lock = 1; }
    }
    if ($rec_lock) {
	$r->log_reason("User tried to delete a locked record");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    if (apr()->param('button') && lc(apr()->param('button')) eq lc($lang{'SUBMIT'})) {
        Debug(5, qq{This is a submit of delete_record request});
	for ($type) {
	    if (/^A$/) {
		if (dns_del_A($dom_id, $record_id)) {
		    Debug(5, qq{dns_delete_A succeded\n});
		} else {
		    Debug(5, qq{dns_delete_A failed\n});
		}
	    }
	    elsif (/^CNAME$/) {
		if (dns_del_CNAME($dom_id, $record_id)) {
		    Debug(5, qq{dns_delete_CNAME succeded\n});
		} else {
		    Debug(5, qq{dns_delete_CNAME failed\n});
		}
	    }
	    elsif (/^MX$/) {
		if (dns_del_MX($dom_id, $record_id)) {
		    Debug(5, qq{dns_delete_MX succeded\n});
		} else {
		    Debug(5, qq{dns_delete_MX failed\n});
		}
	    }
	    elsif (/^NS$/) {
		if (dns_del_NS($dom_id, $record_id)) {
		    Debug(5, qq{dns_delete_NS succeded\n});
		} else {
		    Debug(5, qq{dns_delete_NS failed\n});
		}
	    }
	    elsif (/^TXT$/) {
		if (dns_del_TXT($dom_id, $record_id)) {
		    Debug(5, qq{dns_delete_TXT succeded\n});
		} else {
		    Debug(5, qq{dns_delete_TXT failed\n});
		}
	    }
	    
	}
	output_redirect($r, 1, qq{/admin?action=view&dom_id=$dom_id});

	$dbh->close();
	return REDIRECT;
    } else {
        Debug(5, qq{This is a view of delete_record request});

        my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
        $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
        $tpl->assign(%lang);
        $tpl->assign(DEBUG => '');

	if ($dbh->get_domain_count($uid) == 1) {
	    $tpl->assign(ADDITIONAL_MENU => '');
	} else {
	    $tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
	}

        my $page_title = $lang{PAGE_DEL};
        $page_title =~ s/\$record/$type/;
        $page_title =~ s/\$domain/$domain/;

        $tpl->assign(TITLE => $page_title);
        $tpl->assign(EXPLANATION => $lang{DELETE_RECORD});
	for ($type) {
	    if (/^A$/) {
		my ($name, $address, $ttl) = $dbh->a_lookup($dom_id, $record_id);
		$tpl->define(record => 'a/remove.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(IP_ADDRESS_VALUE => $address);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^CNAME$/) {
		my ($name, $cname, $ttl) = $dbh->cname_lookup($dom_id, $record_id);
		$tpl->define(record => 'cname/remove.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(CNAME_VALUE => $cname);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^MX$/) {
		my ($name, $exchanger, $preference, $ttl) = $dbh->mx_lookup($dom_id, $record_id);
		$tpl->define(record => 'mx/remove.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(MX_VALUE => $exchanger);
		$tpl->assign(PREFERENCE_VALUE => $preference);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^NS$/) {
		my ($name, $nsdname, $ttl) = $dbh->ns_lookup($dom_id, $record_id);
		$tpl->define(record => 'ns/remove.tpl');
		$tpl->assign(ZONE_VALUE => $name);
		$tpl->assign(NS_VALUE => $nsdname);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^TXT$/) {
		my ($name, $txtdata, $ttl) = $dbh->txt_lookup($dom_id, $record_id);
		$tpl->define(record => 'txt/remove.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(TXT_VALUE => $txtdata);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	}

        $tpl->assign(RECORD_ID => $record_id);
	$tpl->assign(DOM_ID => $dom_id);

	$tpl->parse(MENU => "menu");
        $tpl->parse(MAIN => ["record", "layout"]);

	my $content_ref = $tpl->fetch("MAIN");

	output_headers($r, 1, length(${$content_ref}));

        $r->print(${$content_ref});	
	
	$dbh->close();
	return OK;
    }
}

sub add_record {
    my $r = shift || Apache->request();
    Debug(3, qq{calling add_record()});
    init($r);
    my $user = $r->connection->user;
    my ($uid, $email, $lang_id, $lang) = $dbh->get_user_info($user);

    # same as in view_domain() maybe a function should be built for this?
    if (!apr()->param('dom_id')) {
	$r->log_reason("No dom_id for this request: aborting");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check dom_id
    my $dom_id = apr()->param('dom_id');
    ($dom_id) = ($dom_id =~ /(\d+)/)[0];
    if ($dom_id !~ /^\d+$/) {
	$r->log_reason("User didn't supply a domain id for this request or tried to fake it");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # is uid owner of dom_id
    my ($domain, $domain_owner_id) = $dbh->domain_stat($dom_id);
    unless (defined($domain_owner_id) && $uid == $domain_owner_id) {
	$r->log_reason("User trying to hijack another domain");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check for record_id & type
    unless (apr()->param('type')) {
	$r->log_reason("No type specified for edit");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    my $type = uc apr()->param('type');
    ($type) = ($type =~ /(\w+)/)[0];
    if ($type !~ /^\w+$/) {
	$r->log_reason("User tried to supply bogus type data");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    my $no_records_left = 0;
    my ($A_max, $CNAME_max, $MX_max, $NS_max, $TXT_max) = $dbh->get_max_record_count($dom_id);
    for ($type) {
	if (/^A$/) {
	    my ($a_count) = $dbh->get_a_count($dom_id);
	    if ($A_max <= $a_count) {
		$no_records_left = 1;
	    }
	}
	elsif (/^CNAME$/) {
	    my ($cname_count) = $dbh->get_cname_count($dom_id);
	    if ($CNAME_max <= $cname_count) {
		$no_records_left = 1;
	    }
	}
	elsif (/^MX$/) {
	    my ($mx_count) = $dbh->get_mx_count($dom_id);
	    if ($MX_max <= $mx_count) {
		$no_records_left = 1;
	    }
	}
	elsif (/^NS$/) {
	    my ($ns_count) = $dbh->get_ns_count($dom_id);
	    if ($NS_max <= $ns_count) {
		$no_records_left = 1;
	    }
	}
	elsif (/^TXT$/) {
	    my ($txt_count) = $dbh->get_txt_count($dom_id);
	    if ($TXT_max <= $txt_count) {
		$no_records_left = 1;
	    }
	}
    }
    if ($no_records_left) {
	$r->log_reason("User tried to add a record without having more records for this type");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    
    if (apr()->param('button') && lc(apr()->param('button')) eq lc($lang{'SUBMIT'})) {
	# this the update
        Debug(5, qq{This is a submit of add_record request});

	for ($type) {
	    if (/^A$/) { 
		# actually there needs to be another check to see if they really exists the parameters maybe up in the checking of the rec_lock
		my $all_set = 1;
		my $ip = apr()->param('ip');;
		if (!($ip = check_ip($ip))) {
		    $all_set = 0;
		}
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_add_A($dom_id, $host, $ip)) {
		    # update dns! and sql
		    # check wheter name is the same? so no need for update?
		    # rule checking like not the same a and cname record
		    # check wheter an excact copy exists in dns to avoid errors
		    
		    if (dns_set_A($dom_id, $host, $ip, $ttl)) {
		      Debug(5, qq{dns_update_A succeded\n});
		    } else {
		      Debug(5, qq{dns_update_A failed\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');
		    
		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_ADD};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'a/add.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host'))); # maybe it needs to fully qualify it if it was okay?
		    $tpl->assign(IP_ADDRESS_VALUE => encode_entities(apr()->param('ip')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    # do the red-marker assignment
		    # and the error text getting
		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($ip = check_ip($ip))) {
			$tpl->assign(IP_ADDRESS => qq{<font color="red">} . $lang{IP_ADDRESS} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_IP}};
		    }
		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    # check_before_add_A
		    if ($all_set) {
			# this means check_before_add_A failed!
			# text for error?
			$tpl->assign(IP_ADDRESS => qq{<font color="red">} . $lang{IP_ADDRESS} . qq{</font>});
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }
		    $tpl->assign(EXPLANATION => $error_text);
		    
		    $tpl->assign(DOM_ID => $dom_id);

		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

		    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
	        }
	    }
	    elsif (/^CNAME$/) { 
		my $all_set = 1;
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $cname = apr()->param('cname');
		if (!check_cname_host($cname)) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		# do the update dance!
		if ($all_set && check_before_add_CNAME($dom_id, $host)) {
		    # update dns! and sql
		    # check wheter name is the same? so no need for update?
		    # rule checking
		    # check wheter an excact copy exists in dns to avoid errors
		    
		    if (dns_set_CNAME($dom_id, $host, $cname, $ttl)) {
		        Debug(5, qq{dns_update_CNAME succeded\n});
		    } else {
		        Debug(5, qq{dns_update_CNAME failed\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_ADD};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'cname/add.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host')));
		    $tpl->assign(CNAME_VALUE => encode_entities(apr()->param('cname')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!check_cname_host($cname)) {
			$tpl->assign(CNAME => qq{<font color="red">} . $lang{CNAME} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_CNAME}};
		    }
		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    if ($all_set) {
			# means check_before_add_CNAME failed
			$tpl->assign(CNAME => qq{<font color="red">} . $lang{CNAME} . qq{</font>});
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});			
			$error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }
		    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    
		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);
		    
		    my $content_ref = $tpl->fetch("MAIN");
		    
		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
		}
	    }
	    elsif (/^MX$/) { 
		my $all_set = 1;
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $exchanger = apr()->param('exchanger');
		if (!check_exchanger($exchanger)) {
		    $all_set = 0;
		}
		my $preference = apr()->param('preference');
		if (!check_preference($preference)) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_add_MX($dom_id, $host, $exchanger, $preference)) {
		    if (dns_set_MX($dom_id, $host, $exchanger, $preference, $ttl)) {
		        Debug(5, qq{dns_update_MX succeded\n});
		    } else {
		        Debug(5, qq{dns_update_MX failed\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');
		    
		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_ADD};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'mx/add.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host')));
		    $tpl->assign(MX_VALUE => encode_entities(apr()->param('exchanger')));
		    $tpl->assign(PREFERENCE_VALUE => encode_entities(apr()->param('preference')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_exchanger($exchanger)) {
			$tpl->assign(MX => qq{<font color="red">} . $lang{MX} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_MX}};
		    }
		    if (!check_preference($preference)) {
			$tpl->assign(PREFERENCE => qq{<font color="red">} . $lang{PREFERENCE} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_PREFERENCE}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    if ($all_set) {
			# means check_before_add_MX failed
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$tpl->assign(PREFERENCE => qq{<font color="red">} . $lang{PREFERENCE} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }
		    $tpl->assign(EXPLANATION => $error_text);
		    
		    $tpl->assign(DOM_ID => $dom_id);
		    
		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

		    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));

		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
		}
	    }
	    elsif (/^NS$/) { 
		my $all_set = 1;
		my $zone = "";
		if (!($zone = check_fqdn_ns(apr()->param('zone'), $domain))) {
		    $all_set = 0;
		}
		my $nameserver = apr()->param('nsdname');
		if (!check_nameserver($nameserver)) {
		    $all_set = 0;
		}
		
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_add_NS($dom_id, $zone, $nameserver)) {
		    if (dns_set_NS($dom_id, $zone, $nameserver, $ttl)) {
		        Debug(5, qq{dns_update_NS succeded\n});
		    } else {
		        Debug(5, qq{dns_update_NS failed\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

                    if ($dbh->get_domain_count($uid) == 1) {
                        $tpl->assign(ADDITIONAL_MENU => '');
                    } else {
	                $tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
                    }

		    my $page_title = $lang{PAGE_ADD};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'ns/add.tpl');
		    $tpl->assign(ZONE_VALUE => encode_entities(apr()->param('zone')));
		    $tpl->assign(NS_VALUE => encode_entities(apr()->param('nsdname')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($zone = check_fqdn_ns(apr()->param('zone'), $domain))) {
			$tpl->assign(ZONE => qq{<font color="red">} . $lang{ZONE} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_ZONE}};
		    }
		    if (!check_nameserver($nameserver)) {
			$tpl->assign(NS => qq{<font color="red">} . $lang{NS} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_NS}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
                    if ($all_set) {
			$tpl->assign(ZONE => qq{<font color="red">} . $lang{ZONE} . qq{</font>});
			$tpl->assign(NS => qq{<font color="red">} . $lang{NS} . qq{</font>});    
                        $error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
                    }

                    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);

                    $tpl->parse(MENU => "menu");
                    $tpl->parse(MAIN => ["record", "layout"]);

                    my $content_ref = $tpl->fetch("MAIN");

                    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
		}
	    }
	    elsif (/^TXT$/) { 
		my $all_set = 1;
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $txtdata = apr()->param('txtdata');
		if (!check_txt($txtdata)) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_add_TXT($dom_id, $host, $txtdata)) {
		    if (dns_set_TXT($dom_id, $host, $txtdata, $ttl)) {
		        Debug(5, qq{dns_update_TXT succeded\n});
		    } else {
		        Debug(5, qq{dns_update_TXT failed\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
                    }

		    my $page_title = $lang{PAGE_ADD};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);
		    $tpl->define(record => 'txt/add.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host')));
		    $tpl->assign(TXT_VALUE => encode_entities(apr()->param('txtdata')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_txt($txtdata)) {
			$tpl->assign(TXT => qq{<font color="red">} . $lang{TXT} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_TXT}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
                    if ($all_set) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$tpl->assign(TXT => qq{<font color="red">} . $lang{TXT} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
                    }

                    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    
                    $tpl->parse(MENU => "menu");
                    $tpl->parse(MAIN => ["record", "layout"]);

                    my $content_ref = $tpl->fetch("MAIN");

                    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
		}
	    }
	    else { 
	        Debug(1, qq{User trying to update an unexsisting type: $type\n});
	    }
	}
	
        output_redirect($r, 1, qq{/admin?action=view&dom_id=$dom_id});
	$dbh->close();
	return REDIRECT;
    } else {
	# this is the view
        Debug(5, qq{This is an view of add_record request});

        my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
        $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
        $tpl->assign(%lang);
        $tpl->assign(DEBUG => '');
	
	if ($dbh->get_domain_count($uid) == 1) {
	    $tpl->assign(ADDITIONAL_MENU => '');
	} else {
	    $tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
	}

        my $page_title = $lang{PAGE_ADD};
        $page_title =~ s/\$record/$type/;
        $page_title =~ s/\$domain/$domain/;

        $tpl->assign(TITLE => $page_title);
	$tpl->assign(EXPLANATION => $lang{FILLOUT_FIELDS});
	for ($type) {
	    if (/^A$/) {
		$tpl->define(record => 'a/add.tpl');
		$tpl->assign(HOST_VALUE => '');
		$tpl->assign(IP_ADDRESS_VALUE => '');
		$tpl->assign(TTL_VALUE => '');
	    }
	    elsif (/^CNAME$/) {
		$tpl->define(record => 'cname/add.tpl');
		$tpl->assign(HOST_VALUE => '');
		$tpl->assign(CNAME_VALUE => '');
		$tpl->assign(TTL_VALUE => '');
	    }
	    elsif (/^MX$/) {
		$tpl->define(record => 'mx/add.tpl');
		$tpl->assign(HOST_VALUE => '');
		$tpl->assign(MX_VALUE => '');
		$tpl->assign(PREFERENCE_VALUE => '');
		$tpl->assign(TTL_VALUE => '');
	    }
	    elsif (/^NS$/) {
		$tpl->define(record => 'ns/add.tpl');
		$tpl->assign(ZONE_VALUE => '');
		$tpl->assign(NS_VALUE => '');
		$tpl->assign(TTL_VALUE => '');
	    }
	    elsif (/^TXT$/) {
		$tpl->define(record => 'txt/add.tpl');
		$tpl->assign(HOST_VALUE => '');
		$tpl->assign(TXT_VALUE => '');
		$tpl->assign(TTL_VALUE => '');
	    }
	}

	$tpl->assign(DOM_ID => $dom_id);

	$tpl->parse(MENU => "menu");
        $tpl->parse(MAIN => ["record", "layout"]);

	my $content_ref = $tpl->fetch("MAIN");

	output_headers($r, 1, length(${$content_ref}));

        $r->print(${$content_ref});	

        $dbh->close();
	return OK;
    }
}

sub edit_record {
    my $r = shift || Apache->request();
    Debug(3, qq{calling edit_record()});
    init($r);
    my $user = $r->connection->user;
    my ($uid, $email, $lang_id, $lang) = $dbh->get_user_info($user);

    # same as in view_domain() maybe a function should be built for this?
    if (!apr()->param('dom_id')) {
	$r->log_reason("No dom_id for this request: aborting");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check dom_id
    my $dom_id = apr()->param('dom_id');
    ($dom_id) = ($dom_id =~ /(\d+)/)[0];
    if ($dom_id !~ /^\d+$/) {
	$r->log_reason("User didn't supply a domain id for this request or tried to fake it");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # is uid owner of dom_id
    my ($domain, $domain_owner_id) = $dbh->domain_stat($dom_id);
    unless (defined($domain_owner_id) && $uid == $domain_owner_id) {
	$r->log_reason("User trying to hijack another domain");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check for record_id & type
    unless (apr()->param('type')) {
	$r->log_reason("No type specified for edit");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    my $type = uc apr()->param('type');
    ($type) = ($type =~ /(\w+)/)[0];
    if ($type !~ /^\w+$/) {
	$r->log_reason("User tried to supply bogus type data");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    # now only if it's a SOA it's okay not to have a record_id - record_id is equal to dom_id
    my $record_id = apr()->param('record_id') if apr()->param('record_id');
    $record_id = $dom_id if $type eq 'SOA';
    ($record_id) = ($record_id =~ /(\d+)/)[0];
    if ($record_id !~ /^\d+$/) {
	$r->log_reason("User didn't supply a record id for this request or tried to fake it");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    # check for rec_lock
    # and at the same time if UID = owner of record
    my $rec_lock = 0;
    for ($type) {
	if (/^SOA$/) { ($rec_lock) = $dbh->get_lock_SOA($dom_id); }
	elsif (/^A$/) { ($rec_lock) = $dbh->get_lock_A($dom_id, $record_id); }
	elsif (/^CNAME$/) { ($rec_lock) = $dbh->get_lock_CNAME($dom_id, $record_id); }
	elsif (/^MX$/) { ($rec_lock) = $dbh->get_lock_MX($dom_id, $record_id); }
	elsif (/^NS$/) { ($rec_lock) = $dbh->get_lock_NS($dom_id, $record_id); }
	elsif (/^TXT$/) { ($rec_lock) = $dbh->get_lock_TXT($dom_id, $record_id); }
	else { $rec_lock = 1; }
    }
    if ($rec_lock) {
	$r->log_reason("User tried to change a locked record");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    if (apr()->param('button') && lc(apr()->param('button')) eq lc($lang{'SUBMIT'})) {
        Debug(5, qq{This is a submit of edit_record request});
	for ($type) {
	    if (/^SOA$/) { 
		my $soa_email = apr()->param('soa_email');
		my $refresh = apr()->param('refresh');
		my $retry = apr()->param('retry');
		my $expire = apr()->param('expire');
		my $default_ttl = apr()->param('default_ttl');
		my $all_set = 1;
		if (!(check_ttl($refresh) && check_ttl($retry) && check_ttl($expire) && check_ttl($default_ttl))) {
		    $all_set = 0;
		}
		if (!($soa_email = check_email($soa_email))) {
		    $all_set = 0;
		}
		if ($soa_email =~ /\..*?\@/) { 
		    # is there a dot before the @ => invalid for a soa email
		    $all_set = 0;
                } 
		if ($all_set) {
		    my $serial = get_serial_from_zone($dom_id);
		    $serial++;
		    $soa_email =~ s/\@/\./;
		    if (is_updated_SOA($dom_id, $soa_email, $refresh, $retry, $expire, $default_ttl)) {
			if (dns_update_SOA($dom_id, $serial, $soa_email, $refresh, $retry, $expire, $default_ttl)) {
			    Debug(2, qq{dns_update_SOA succeded\n});
			} else {
			    Debug(2, qq{dns_update_SOA failed\n});
			}
		    } else {
		        Debug(2, qq{Dns record not changed so not updated\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');
		    
		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_EDIT};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'soa/edit.tpl');
		    $tpl->assign(ADMIN_EMAIL_VALUE => encode_entities(apr()->param('soa_email')));
		    $tpl->assign(REFRESH_VALUE => encode_entities(apr()->param('refresh')));
		    $tpl->assign(RETRY_VALUE => encode_entities(apr()->param('retry')));
		    $tpl->assign(EXPIRE_VALUE => encode_entities(apr()->param('expire')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('default_ttl')));
		    
		    my ($auth_ns, $serial) = $dbh->get_authns_serial($dom_id);

		    $tpl->assign(AUTH_NS_VALUE => $auth_ns);
		    $tpl->assign(SERIAL_VALUE => $serial);

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!check_ttl($refresh)) {
			$tpl->assign(REFRESH => qq{<font color="red">} . $lang{REFRESH} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_REFRESH}};
		    }
		    if (!check_ttl($retry)) {
			$tpl->assign(RETRY => qq{<font color="red">} . $lang{RETRY} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_RETRY}};
		    }
		    if (!check_ttl($expire)) {
			$tpl->assign(EXPIRE => qq{<font color="red">} . $lang{EXPIRE} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_EXPIRE}};
		    }
		    if (!check_ttl($default_ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    
		    if (!($soa_email = check_email($soa_email))) {
			$tpl->assign(ADMIN_EMAIL => qq{<font color="red">} . $lang{ADMIN_EMAIL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_ADMIN_EMAIL}};
		    }
		    if ($soa_email =~ /\..*?\@/) { 
			# is there a dot before the @ => invalid for a soa email
			$tpl->assign(ADMIN_EMAIL => qq{<font color="red">} . $lang{ADMIN_EMAIL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_ADMIN_EMAIL}};
		    } 
		    
		    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    $tpl->assign(RECORD_ID => $record_id);

		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

		    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));

		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
		}
	    } 
	    elsif (/^A$/) { 
		# actually there needs to be another check to see if they really exists the parameters maybe up in the checking of the rec_lock
		my $all_set = 1;
		my $ip = apr()->param('ip');
		if (!($ip = check_ip($ip))) {
		    $all_set = 0;
		}
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_edit_A($dom_id, $record_id, $host, $ip)) {
		    # update dns! and sql
		    # check wheter name is the same? so no need for update?
		    
		    # check wheter an excact copy exists in dns to avoid errors
		    if (is_updated_A($dom_id, $record_id, $host, $ip, $ttl)) {
			if (dns_update_A($dom_id, $record_id, $host, $ip, $ttl)) {
			    Debug(2, qq{dns_update_A succeded\n});
			} else {
			    Debug(2, qq{dns_update_A failed\n});
			}
		    } else {
		        Debug(2, qq{Dns record not changed so not updated\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');
		    
		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_EDIT};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'a/edit.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host'))); # maybe it needs to fully qualify it if it was okay?
		    $tpl->assign(IP_ADDRESS_VALUE => encode_entities(apr()->param('ip')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    # do the red-marker assignment

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($ip = check_ip($ip))) {
			$tpl->assign(IP_ADDRESS => qq{<font color="red">} . $lang{IP_ADDRESS} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_IP}};
		    }
		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    if ($all_set) {
			$tpl->assign(IP_ADDRESS => qq{<font color="red">} . $lang{IP_ADDRESS} . qq{</font>});
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }

		    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    $tpl->assign(RECORD_ID => $record_id);

		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

		    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
	        }
	    }
	    elsif (/^CNAME$/) { 
		my $all_set = 1;
                my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $cname = apr()->param('cname');
		if (!check_cname_host($cname)) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		# do the update dance!
		if ($all_set && check_before_edit_CNAME($dom_id, $record_id, $host, $cname)) {
		    # update dns! and sql
		    # check wheter name is the same? so no need for update?
		    
		    # check wheter an excact copy exists in dns to avoid errors
		    if (is_updated_CNAME($dom_id, $record_id, $host, $cname, $ttl)) {
			if (dns_update_CNAME($dom_id, $record_id, $host, $cname, $ttl)) {
			    Debug(2, qq{dns_update_CNAME succeded\n});
			} else {
			    Debug(2, qq{dns_update_CNAME failed\n});
			}
		    } else {
		        Debug(2, qq{Dns record not changed so not updated\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_EDIT};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'cname/edit.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host')));
		    $tpl->assign(CNAME_VALUE => encode_entities(apr()->param('cname')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!check_cname_host($cname)) {
			$tpl->assign(CNAME => qq{<font color="red">} . $lang{CNAME} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_CNAME}};
		    }
		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    if ($all_set) {
			$tpl->assign(CNAME => qq{<font color="red">} . $lang{CNAME} . qq{</font>});
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }

		    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    $tpl->assign(RECORD_ID => $record_id);
		    
		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

		    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

 	            $dbh->close();
		    return OK;
		}
	    }
	    elsif (/^MX$/) { 
		my $all_set = 1;
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $exchanger = apr()->param('exchanger');
		if (!check_exchanger($exchanger)) {
		    $all_set = 0;
		}
		my $preference = apr()->param('preference');
		if (!check_preference($preference)) { 
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_edit_MX($dom_id, $record_id, $host, $exchanger, $preference)) {
		    if (is_updated_MX($dom_id, $record_id, $host, $exchanger, $preference, $ttl)) {
                        if (dns_update_MX($dom_id, $record_id, $host, $exchanger, $preference, $ttl)) {
			    Debug(2, qq{dns_update_MX succeded\n});
			} else {
			    Debug(2, qq{dns_update_MX failed\n});
		        }
                    } else {
    		        Debug(2, qq{Dns record not changed so not updated\n});
                    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

                    if ($dbh->get_domain_count($uid) == 1) {
                        $tpl->assign(ADDITIONAL_MENU => '');
                    } else {
	                $tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
                    }

		    my $page_title = $lang{PAGE_EDIT};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'mx/edit.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host')));
		    $tpl->assign(MX_VALUE => encode_entities(apr()->param('exchanger')));
		    $tpl->assign(PREFERENCE_VALUE => encode_entities(apr()->param('preference')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

                    my $error_text = $lang{ERROR_CORRECT};

		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_exchanger($exchanger)) {
			$tpl->assign(MX => qq{<font color="red">} . $lang{MX} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_MX}};
		    }
		    if (!check_preference($preference)) {
			$tpl->assign(PREFERENCE => qq{<font color="red">} . $lang{PREFERENCE} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_PREFERENCE}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
                    if ($all_set) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$tpl->assign(PREFERENCE => qq{<font color="red">} . $lang{PREFERENCE} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
                    }

                    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    $tpl->assign(RECORD_ID => $record_id);
		    
                    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

                    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$tpl->fetch("MAIN")});	

                    $dbh->close();
		    return OK;
		}
	    }
	    elsif (/^NS$/) { 
		my $all_set = 1;
		my $zone = "";
		if (!($zone = check_fqdn_ns(apr()->param('zone'), $domain))) {
		    $all_set = 0;
		}
		my $nameserver = apr()->param('nsdname');
		if (!check_nameserver($nameserver)) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_edit_NS($dom_id, $record_id, $zone, $nameserver)) {
		    if (is_updated_NS($dom_id, $record_id, $zone, $nameserver, $ttl)) {
			if (dns_update_NS($dom_id, $record_id, $zone, $nameserver, $ttl)) {
			    Debug(2, qq{dns_update_NS succeded\n});
                        } else {
			    Debug(2, qq{dns_update_NS failed\n});
                        }
                    } else {
			Debug(2, qq{Dns record not changed so not updating\n});
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
                    }

		    my $page_title = $lang{PAGE_EDIT};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);

		    $tpl->define(record => 'ns/edit.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('zone')));
		    $tpl->assign(NS_VALUE => encode_entities(apr()->param('nsdname')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($zone = check_fqdn_ns(apr()->param('zone'), $domain))) {
			$tpl->assign(ZONE => qq{<font color="red">} . $lang{ZONE} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_ZONE}};
		    }
		    if (!check_nameserver($nameserver)) {
			$tpl->assign(NS => qq{<font color="red">} . $lang{NS} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_NS}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
                    if ($all_set) {
			$tpl->assign(ZONE => qq{<font color="red">} . $lang{ZONE} . qq{</font>});
			$tpl->assign(NS => qq{<font color="red">} . $lang{NS} . qq{</font>});
                        $error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }

                    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    $tpl->assign(RECORD_ID => $record_id);

                    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

                    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

		    $dbh->close();
                    return OK;
		}
	    }
	    elsif (/^TXT$/) { 
		my $all_set = 1;
		my $host = "";
		if (!($host = check_fqdn(apr()->param('host'), $domain))) {
		    $all_set = 0;
		}
		my $txtdata = apr()->param('txtdata');
		if (!check_txt($txtdata)) {
		    $all_set = 0;
		}
		my $ttl = apr()->param('ttl');
		if (!check_ttl($ttl)) {
		    $all_set = 0;
		}
		if ($all_set && check_before_edit_TXT($dom_id, $record_id, $host, $txtdata)) {
		    if (is_updated_TXT($dom_id, $record_id, $host, $txtdata, $ttl)) {
			if (dns_update_TXT($dom_id, $record_id, $host, $txtdata, $ttl)) {
			    Debug(2, qq{dns_update_TXT succeded\n});
			} else {
			    Debug(2, qq{dns_update_TXT failed\n});
			}
		    } else {
			Debug(2, qq{Dns record not changed so not updating\n});			
		    }
		} else {
		    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
		    $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
		    $tpl->assign(%lang);
		    $tpl->assign(DEBUG => '');

		    if ($dbh->get_domain_count($uid) == 1) {
			$tpl->assign(ADDITIONAL_MENU => '');
		    } else {
			$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
		    }

		    my $page_title = $lang{PAGE_EDIT};
		    $page_title =~ s/\$record/$type/;
		    $page_title =~ s/\$domain/$domain/;
		    
		    $tpl->assign(TITLE => $page_title);
		    $tpl->define(record => 'txt/edit.tpl');
		    $tpl->assign(HOST_VALUE => encode_entities(apr()->param('host')));
		    $tpl->assign(TXT_VALUE => encode_entities(apr()->param('txtdata')));
		    $tpl->assign(TTL_VALUE => encode_entities(apr()->param('ttl')));

		    my $error_text = $lang{ERROR_CORRECT};

		    if (!($host = check_fqdn(apr()->param('host'), $domain))) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_HOST}};
		    }
		    if (!check_txt($txtdata)) {
			$tpl->assign(TXT => qq{<font color="red">} . $lang{TXT} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TXT}};
		    }
		    if (!check_ttl($ttl)) {
			$tpl->assign(TTL => qq{<font color="red">} . $lang{TTL} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_TTL}};
		    }
		    if ($all_set) {
			$tpl->assign(HOST => qq{<font color="red">} . $lang{HOST} . qq{</font>});
			$tpl->assign(TXT => qq{<font color="red">} . $lang{TXT} . qq{</font>});
			$error_text .= qq{<br>$lang{ERROR_DUPLICATE}};
		    }

		    $tpl->assign(EXPLANATION => $error_text);

		    $tpl->assign(DOM_ID => $dom_id);
		    $tpl->assign(RECORD_ID => $record_id);
		    
		    $tpl->parse(MENU => "menu");
		    $tpl->parse(MAIN => ["record", "layout"]);

		    my $content_ref = $tpl->fetch("MAIN");

		    output_headers($r, 1, length(${$content_ref}));
		    
		    $r->print(${$content_ref});	

                    $dbh->close();
		    return OK;
		}
	    }
	    else { 
	        Debug(1, qq{User trying to update an unexsisting type: $type\n});
	    }
	}
        output_redirect($r, 1, qq{/admin?action=view&dom_id=$dom_id});
	$dbh->close();
	return REDIRECT;
    } else {
	# is view
        Debug(5, qq{This is a view of edit_record request});    

        my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
        $tpl->define(layout => 'layout.tpl', menu => 'menu.tpl');
        $tpl->assign(%lang);
        $tpl->assign(DEBUG => '');
	
	if ($dbh->get_domain_count($uid) == 1) {
	    $tpl->assign(ADDITIONAL_MENU => '');
	} else {
	    $tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
	}

        my $page_title = $lang{PAGE_EDIT};
        $page_title =~ s/\$record/$type/;
        $page_title =~ s/\$domain/$domain/;

        $tpl->assign(TITLE => $page_title);
	$tpl->assign(EXPLANATION => $lang{EDIT_FIELDS});
	for ($type) {
	    if (/^SOA$/) {
		my ($auth_ns, $soa_email, $serial, $refresh, $retry, $expire, $default_ttl) = $dbh->soa_lookup($dom_id);
		$soa_email =~ s/\./\@/;	    
		$tpl->define(record => 'soa/edit.tpl');
		$tpl->assign(AUTH_NS_VALUE => $auth_ns);
		$tpl->assign(SERIAL_VALUE => $serial);
		$tpl->assign(ADMIN_EMAIL_VALUE => $soa_email);
		$tpl->assign(REFRESH_VALUE => $refresh);
		$tpl->assign(RETRY_VALUE => $retry);
		$tpl->assign(EXPIRE_VALUE => $expire);
		$tpl->assign(TTL_VALUE => $default_ttl);
	    }
	    elsif (/^A$/) {
		my ($name, $address, $ttl) = $dbh->a_lookup($dom_id, $record_id);
		$tpl->define(record => 'a/edit.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(IP_ADDRESS_VALUE => $address);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^CNAME$/) {
		my ($name, $cname, $ttl) = $dbh->cname_lookup($dom_id, $record_id);
		$tpl->define(record => 'cname/edit.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(CNAME_VALUE => $cname);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^MX$/) {
		my ($name, $exchanger, $preference, $ttl) = $dbh->mx_lookup($dom_id, $record_id);
		$tpl->define(record => 'mx/edit.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(MX_VALUE => $exchanger);
		$tpl->assign(PREFERENCE_VALUE => $preference);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^NS$/) {
		my ($name, $nsdname, $ttl) = $dbh->ns_lookup($dom_id, $record_id);
		$tpl->define(record => 'ns/edit.tpl');
		$tpl->assign(ZONE_VALUE => $name);
		$tpl->assign(NS_VALUE => $nsdname);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	    elsif (/^TXT$/) {
		my ($name, $txtdata, $ttl) = $dbh->txt_lookup($dom_id, $record_id);
		$txtdata = encode_entities($txtdata);
		$tpl->define(record => 'txt/edit.tpl');
		$tpl->assign(HOST_VALUE => $name);
		$tpl->assign(TXT_VALUE => $txtdata);
		$tpl->assign(TTL_VALUE => $ttl);
	    }
	}

        $tpl->assign(RECORD_ID => $record_id);
	$tpl->assign(DOM_ID => $dom_id);

	$tpl->parse(MENU => "menu");
        $tpl->parse(MAIN => ["record", "layout"]);

	my $content_ref = $tpl->fetch("MAIN");

	output_headers($r, 1, length(${$content_ref}));

        $r->print(${$content_ref});	

	$dbh->close();
	return OK;
    }
}

sub view_domain {
    my $r = shift || Apache->request();
    Debug(3, qq{calling view_domain()});
    init($r); 
    my $user = $r->connection->user;
    my ($uid, $user_email, $lang_id, $lang) = $dbh->get_user_info($user);

    if (!apr()->param('dom_id')) {
	$r->log_reason("No dom_id for this request: aborting");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # check dom_id
    my $dom_id = apr()->param('dom_id');
    ($dom_id) = ($dom_id =~ /(\d+)/)[0];
    if ($dom_id !~ /^\d+$/) {
	$r->log_reason("User didn't supply a domain id for this request or tried to fake it");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }
    # is uid owner of dom_id
    my ($domain, $domain_owner_id) = $dbh->domain_stat($dom_id);
    unless (defined($domain_owner_id) && $uid == $domain_owner_id) {
	$r->log_reason("User trying to hijack another domain");
	output_redirect($r, 1, '/admin');
	$dbh->close();
	return REDIRECT;
    }

    # actually it should be pretty safe to go on now!

    my $tpl = new CGI::FastTemplate($cfg->{'cfg'}->{DnsZoneTemplateDir});
    $tpl->define( 
	     layout => "layout.tpl",
	     menu => "menu.tpl",
	     view_domain => "view_domain.tpl",
	     view_domain_soa => "view_domain/soa.tpl",
	     view_domain_a => "view_domain/a.tpl",
	     view_domain_a_record => "view_domain/a_record.tpl",
	     view_domain_cname => "view_domain/cname.tpl",
	     view_domain_cname_record => "view_domain/cname_record.tpl",
	     view_domain_mx => "view_domain/mx.tpl",
	     view_domain_mx_record => "view_domain/mx_record.tpl",
	     view_domain_ns => "view_domain/ns.tpl",
	     view_domain_ns_record => "view_domain/ns_record.tpl",
	     view_domain_txt => "view_domain/txt.tpl",
	     view_domain_txt_record => "view_domain/txt_record.tpl"
	     );

    $tpl->assign(%lang);
    my $page_title = $lang{PAGE_VIEW_DOMAIN};
    $page_title =~ s/\$domain/$domain/;
    $tpl->assign(TITLE => $page_title);
    $tpl->assign(DOM_ID => $dom_id);
    $tpl->assign(DEBUG => '');

    if ($dbh->get_domain_count($uid) == 1) {
	$tpl->assign(ADDITIONAL_MENU => '');
    } else {
	$tpl->assign(ADDITIONAL_MENU => qq{<a href="/admin?action=default">$lang{LIST_DOMAIN}</a> | });
    }

    my ($A_max, $CNAME_max, $MX_max, $NS_max, $TXT_max) = $dbh->get_max_record_count($dom_id);

    my ($auth_ns, $email, $serial, $refresh, $retry, $expire, $default_ttl, $rec_lock) = $dbh->soa_lookup($dom_id);
    $email =~ s/\./\@/;

    $tpl->assign(SOA_SERIAL_VALUE => $serial);
    $tpl->assign(SOA_ADMIN_EMAIL_VALUE => $email);
    $tpl->assign(SOA_AUTH_NS_VALUE => $auth_ns);
    $tpl->assign(SOA_REFRESH_VALUE => $refresh);
    $tpl->assign(SOA_RETRY_VALUE => $retry);
    $tpl->assign(SOA_EXPIRE_VALUE => $expire);
    $tpl->assign(SOA_TTL_VALUE => $default_ttl);
    
    if ($rec_lock == 0) {
	$tpl->assign(SOA_EDIT => qq{[ <a href="/admin?action=edit&dom_id=$dom_id&type=SOA">$lang{EDIT}</a> ]});
    } else {
	$tpl->assign(SOA_EDIT => qq{<i>$lang{LOCKED}</i>});
    }

    $tpl->parse(SOA_RR => "view_domain_soa");
   
    if ($A_max != 0) { 
	my ($a_count) = $dbh->get_a_count($dom_id);
	if ($A_max > $a_count) {
	    $tpl->assign(A_ADD => qq{[ <a href="/admin?action=add&dom_id=$dom_id&type=A">$lang{ADD}</a> ]});
	} else {
	    $tpl->assign(A_ADD => qq{\&nbsp;});
	}
	if ($a_count != 0) {
	    my $sth_A = $dbh->view_domain_A_prepare($dom_id);
	    my $count = 0;
	    while (my ($A_id, $A_name, $A_address, $A_ttl, $A_rec_lock) = $sth_A->fetchrow_array()) {
		$count++;
		my $bgcolor = "";
		if ($count % 2 != 1) {
		    $tpl->assign(A_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableEvenColor});
		} else {
		    $tpl->assign(A_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableOddColor});
		}
		$tpl->assign(A_HOST_VALUE => $A_name);
		$tpl->assign(A_IP_VALUE => $A_address);
		$tpl->assign(A_TTL_VALUE => $A_ttl);
		if ($A_rec_lock == 0) {
		    $tpl->assign(A_CHANGE => qq{[ <a href="/admin?action=edit&dom_id=$dom_id&type=A&record_id=$A_id">$lang{EDIT}</a> | <a href="/admin?action=delete&dom_id=$dom_id&type=A&record_id=$A_id">$lang{REMOVE}</a> ]});
		} else {
		    $tpl->assign(A_CHANGE => qq{<i>$lang{LOCKED}</i>});
		}
		$tpl->parse(A_RECORD => ".view_domain_a_record");
	    }
	    $sth_A->finish();
	    $tpl->parse(A_RR => "view_domain_a");
	} else {
	    $tpl->assign(A_RECORD => '');
	    $tpl->parse(A_RR => "view_domain_a");
	}
    } else {
	$tpl->assign(A_ADD => '');
	$tpl->assign(A_RECORD => '');
	$tpl->assign(A_RR => '');
    }
    if ($CNAME_max != 0) { 
	my ($cname_count) = $dbh->get_cname_count($dom_id);
	if ($CNAME_max > $cname_count) {
	    $tpl->assign(CNAME_ADD => qq{[ <a href="/admin?action=add&dom_id=$dom_id&type=CNAME">$lang{ADD}</a> ]});
	} else {
	    $tpl->assign(CNAME_ADD => '');
	}
	if ($cname_count != 0) {
	    my $sth_CNAME = $dbh->view_domain_CNAME_prepare($dom_id);
	    my $count = 0;
	    while (my ($CNAME_id, $CNAME_name, $CNAME_cname, $CNAME_ttl, $CNAME_rec_lock) = $sth_CNAME->fetchrow_array()) {
		$count++;
		if ($count % 2 != 1) {
		    $tpl->assign(CNAME_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableEvenColor});
		} else {
		    $tpl->assign(CNAME_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableOddColor});
		}
		$tpl->assign(CNAME_HOST_VALUE => $CNAME_name);
		$tpl->assign(CNAME_CNAME_VALUE => $CNAME_cname);
		$tpl->assign(CNAME_TTL_VALUE => $CNAME_ttl);
		if ($CNAME_rec_lock == 0) {
		    $tpl->assign(CNAME_CHANGE => qq{[ <a href="/admin?action=edit&dom_id=$dom_id&type=CNAME&record_id=$CNAME_id">$lang{EDIT}</a> | <a href="/admin?action=delete&dom_id=$dom_id&type=CNAME&record_id=$CNAME_id">$lang{REMOVE}</a> ]});
		} else {
		    $tpl->assign(CNAME_CHANGE => qq{<i>$lang{LOCKED}</i>});
		}
		$tpl->parse(CNAME_RECORD => ".view_domain_cname_record");
	    }
	    $tpl->parse(CNAME_RR => "view_domain_cname");
	    $sth_CNAME->finish();
	} else {
	    $tpl->assign(CNAME_RECORD => '');
	    $tpl->parse(CNAME_RR => "view_domain_cname");
	}
    } else {
	$tpl->assign(CNAME_ADD => '');
	$tpl->assign(CNAME_RECORD => '');
	$tpl->assign(CNAME_RR => '');
    }
    if ($MX_max != 0) { 
	my ($mx_count) = $dbh->get_mx_count($dom_id);
	if ($MX_max > $mx_count) {
	    $tpl->assign(MX_ADD => qq{[ <a href="/admin?action=add&dom_id=$dom_id&type=MX">$lang{ADD}</a> ]});
	} else {
	    $tpl->assign(MX_ADD => '');
	}
	if ($mx_count != 0) {
	    my $sth_MX = $dbh->view_domain_MX_prepare($dom_id);
	    my $count = 0;
	    while (my ($MX_id, $MX_name, $MX_exchanger, $MX_preference, $MX_ttl, $MX_rec_lock) = $sth_MX->fetchrow_array()) {
		$count++;
		if ($count % 2 != 1) {
		    $tpl->assign(MX_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableEvenColor});
		} else {
		    $tpl->assign(MX_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableOddColor});
		}
		$tpl->assign(MX_HOST_VALUE => $MX_name);
		$tpl->assign(MX_MX_VALUE => $MX_exchanger);
		$tpl->assign(MX_PREFERENCE_VALUE => $MX_preference);
		$tpl->assign(MX_TTL_VALUE => $MX_ttl);
		if ($MX_rec_lock == 0) {
		    $tpl->assign(MX_CHANGE => qq{[ <a href="/admin?action=edit&dom_id=$dom_id&type=MX&record_id=$MX_id">$lang{EDIT}</a> |  <a href="/admin?action=delete&dom_id=$dom_id&type=MX&record_id=$MX_id">$lang{REMOVE}</a> ]});
		} else {
		    $tpl->assign(MX_CHANGE => qq{<i>$lang{LOCKED}</i>});
		}
		$tpl->parse(MX_RECORD => ".view_domain_mx_record");
	    }
	    $tpl->parse(MX_RR => "view_domain_mx");
	    $sth_MX->finish();
	} else {
	    $tpl->assign(MX_RECORD => '');
	    $tpl->parse(MX_RR => "view_domain_mx");
	}
    } else {
	$tpl->assign(MX_ADD => '');
	$tpl->assign(MX_RECORD => '');
	$tpl->assign(MX_RR => '');
    }
    if ($NS_max != 0) { 
	my ($ns_count) = $dbh->get_mx_count($dom_id);
	if ($NS_max > $ns_count) {
	    $tpl->assign(NS_ADD => qq{[ <a href="/admin?action=add&dom_id=$dom_id&type=NS">$lang{ADD}</a> ]});
	} else {
	    $tpl->assign(NS_ADD => '');
	}
	if ($ns_count != 0) {
	    my $sth_NS = $dbh->view_domain_NS_prepare($dom_id);
	    my $count = 0;
	    while (my ($NS_id, $NS_name, $NS_nsdname, $NS_ttl, $NS_rec_lock) = $sth_NS->fetchrow_array()) {
		$count++;
		if ($count % 2 != 1) {
		    $tpl->assign(NS_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableEvenColor});
		} else {
		    $tpl->assign(NS_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableOddColor});
		}
		$tpl->assign(NS_ZONE_VALUE => $NS_name);
		$tpl->assign(NS_NS_VALUE => $NS_nsdname);
		$tpl->assign(NS_TTL_VALUE => $NS_ttl);
		if ($NS_rec_lock == 0) {
		    $tpl->assign(NS_CHANGE => qq{[ <a href="/admin?action=edit&dom_id=$dom_id&type=NS&record_id=$NS_id">$lang{EDIT}</a> | <a href="/admin?action=delete&dom_id=$dom_id&type=NS&record_id=$NS_id">$lang{REMOVE}</a> ]}); 
		} else {
		    $tpl->assign(NS_CHANGE => qq{<i>$lang{LOCKED}</i>});
		}
		$tpl->parse(NS_RECORD => ".view_domain_ns_record");
	    }
	    $tpl->parse(NS_RR => "view_domain_ns");
	    $sth_NS->finish();
	} else {
	    $tpl->assign(NS_RECORD => '');
	    $tpl->parse(NS_RR => "view_domain_ns");
	}
    } else {
	$tpl->assign(NS_ADD => '');
	$tpl->assign(NS_RECORD => '');
	$tpl->assign(NS_RR => '');
    }
    if ($TXT_max != 0) { 
	my ($txt_count) = $dbh->get_txt_count($dom_id);
	if ($TXT_max > $txt_count) {
	    $tpl->assign(TXT_ADD => qq{[ <a href="/admin?action=add&dom_id=$dom_id&type=TXT">$lang{ADD}</a> ]});
	} else {
	    $tpl->assign(TXT_ADD => '');
	}
	if ($txt_count != 0) {
	    my $sth_TXT = $dbh->view_domain_TXT_prepare($dom_id);
	    my $count = 0;
	    while (my ($TXT_id, $TXT_name, $TXT_txt, $TXT_ttl, $TXT_rec_lock) = $sth_TXT->fetchrow_array()) {
		$count++;
		if ($count % 2 != 1) {
		    $tpl->assign(TXT_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableEvenColor});
		} else {
		    $tpl->assign(TXT_RR_BGCOLOR => $cfg->{'cfg'}->{DnsZoneTableOddColor});
		}
		$tpl->assign(TXT_HOST_VALUE => $TXT_name);
		$tpl->assign(TXT_TXT_VALUE => $TXT_txt);
		$tpl->assign(TXT_TTL_VALUE => $TXT_ttl);
		if ($TXT_rec_lock == 0) {
		    $tpl->assign(TXT_CHANGE => qq{[ <a href="/admin?action=edit&dom_id=$dom_id&type=TXT&record_id=$TXT_id">$lang{EDIT}</a> | <a href="/admin?action=delete&dom_id=$dom_id&type=TXT&record_id=$TXT_id">$lang{REMOVE}</a> ]});
		} else {
		    $tpl->assign(TXT_CHANGE => qq{<i>$lang{LOCKED}</i>});
		}
		$tpl->parse(TXT_RECORD => ".view_domain_txt_record");
	    }
	    $tpl->parse(TXT_RR => "view_domain_txt");
	    $sth_TXT->finish();
	} else {
	    $tpl->assign(TXT_RECORD => '');
	    $tpl->parse(TXT_RR => "view_domain_txt");
	}
    } else {
	$tpl->assign(TXT_ADD => '');
	$tpl->assign(TXT_RECORD => '');
	$tpl->assign(TXT_RR => '');
    }

    $tpl->parse(MENU => "menu");
    $tpl->parse(MAIN => ["view_domain", "layout"]);

    my $content_ref = $tpl->fetch("MAIN");

    output_headers($r, 1, length(${$content_ref}));

    $r->print(${$content_ref});
    
    $dbh->close();
    return OK;
}

sub dns_update_SOA {
    my $domain_id = shift;
    my $serial = shift;  
    my $soa_email = shift;
    my $refresh = shift;
    my $retry = shift;
    my $expire = shift;
    my $default_ttl = shift;
    my $auth_ns = $dbh->get_auth_ns($domain_id);
    my $domain = $dbh->id2domain($domain_id);
    my $update = new Net::DNS::Update($domain);
    resolver_setup($domain_id);
    Debug(5, qq{dns_update_SOA: (del) $domain SOA $auth_ns\n});
    $update->push("update", rr_del(qq{$domain SOA $auth_ns}));
    Debug(5, qq{dns_update_SOA: (set) $domain $default_ttl SOA $auth_ns $soa_email ($serial $refresh $retry $expire $default_ttl)});
    $update->push("update", rr_add(qq{$domain $default_ttl SOA $auth_ns $soa_email ($serial $refresh $retry $expire $default_ttl)}));
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_update_SOA (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->update_SOA($domain_id, $serial, $soa_email, $refresh, $retry, $expire, $default_ttl);    
}

sub dns_set_A {
    my $domain_id = shift;
    my $name = shift;
    my $ip = shift;
    my $ttl = shift || 86400; 
    my $domain = $dbh->id2domain($domain_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_set_A: $name $ttl A $ip});
    $update->push("update", rr_add(qq{$name $ttl A $ip}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_set_A (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->set_A($domain_id, $name, $ip, $ttl);
}

sub dns_update_A {
    my $domain_id = shift;
    my $a_id = shift;
    my $new_name = shift;
    my $new_ip = shift;
    my $new_ttl = shift || 86400;
    my $domain = $dbh->id2domain($domain_id);
    my ($old_name, $old_ip, $old_ttl) = $dbh->a_lookup($domain_id, $a_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{Apache::DnsZone::dns_update_A (del): ($domain) $old_name A $old_ip});
    $update->push("update", rr_del(qq{$old_name A $old_ip}));
    Debug(5, qq{Apache::DnsZone::dns_update_A (set): ($domain) $new_name $new_ttl A $new_ip});
    $update->push("update", rr_add(qq{$new_name $new_ttl A $new_ip}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_update_A (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->update_A($domain_id, $a_id, $new_name, $new_ip, $new_ttl);
}

sub dns_del_A {
    my $domain_id = shift;
    my $a_id = shift;
    my $domain = $dbh->id2domain($domain_id);
    my ($name, $ip, $ttl) = $dbh->a_lookup($domain_id, $a_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_del_A: ($domain) $name A $ip});
    $update->push("update", rr_del(qq{$name A $ip}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_del_A (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->delete_A($domain_id, $a_id);
}

sub dns_set_CNAME {
    my $domain_id = shift;
    my $name = shift;
    my $cname = shift;
    my $ttl = shift || 86400; 
    my $domain = $dbh->id2domain($domain_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_set_CNAME: $name $ttl CNAME $cname});
    $update->push("update", rr_add(qq{$name $ttl CNAME $cname}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_set_CNAME (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->set_CNAME($domain_id, $name, $cname, $ttl);
}

sub dns_update_CNAME {
    my $domain_id = shift;
    my $cname_id = shift;
    my $new_name = shift;
    my $new_cname = shift;
    my $new_ttl = shift || 86400;
    my $domain = $dbh->id2domain($domain_id);
    my ($old_name, $old_cname, $old_ttl) = $dbh->cname_lookup($domain_id, $cname_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{Apache::DnsZone::dns_update_CNAME (del): ($domain) $old_name CNAME $old_cname});
    $update->push("update", rr_del(qq{$old_name CNAME $old_cname}));
    Debug(5, qq{Apache::DnsZone::dns_update_CNAME (set): ($domain) $new_name $new_ttl CNAME $new_cname});
    $update->push("update", rr_add(qq{$new_name $new_ttl CNAME $new_cname}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_update_CNAME (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->update_CNAME($domain_id, $cname_id, $new_name, $new_cname, $new_ttl);
}

sub dns_del_CNAME {
    my $domain_id = shift;
    my $cname_id = shift;
    my $domain = $dbh->id2domain($domain_id);
    my ($name, $cname, $ttl) = $dbh->cname_lookup($domain_id, $cname_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_del_CNAME: ($domain) $name CNAME $cname});
    $update->push("update", rr_del(qq{$name CNAME $cname}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_del_CNAME (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->delete_CNAME($domain_id, $cname_id);
}

sub dns_set_MX {
    my $domain_id = shift;
    my $name = shift;
    my $exchanger = shift;
    my $preference = shift;
    my $ttl = shift || 86400; 
    my $domain = $dbh->id2domain($domain_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_set_MX: $name $ttl MX $preference $exchanger});
    $update->push("update", rr_add(qq{$name $ttl MX $preference $exchanger}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_set_MX (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->set_MX($domain_id, $name, $exchanger, $preference, $ttl);
}

sub dns_update_MX {
    my $domain_id = shift;
    my $mx_id = shift;
    my $new_name = shift;
    my $new_exchanger = shift;
    my $new_preference = shift;
    my $new_ttl = shift || 86400;
    my $domain = $dbh->id2domain($domain_id);
    my ($old_name, $old_exchanger, $old_preference, $old_ttl) = $dbh->mx_lookup($domain_id, $mx_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{Apache::DnsZone::dns_update_MX (del): ($domain) $old_name MX $old_preference $old_exchanger});
    $update->push("update", rr_del(qq{$old_name MX $old_preference $old_exchanger}));
    Debug(5, qq{Apache::DnsZone::dns_update_MX (set): ($domain) $new_name $new_ttl MX $new_preference $new_exchanger});
    $update->push("update", rr_add(qq{$new_name $new_ttl MX $new_preference $new_exchanger}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_update_MX (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->update_MX($domain_id, $mx_id, $new_name, $new_exchanger, $new_preference, $new_ttl);
}

sub dns_del_MX {
    my $domain_id = shift;
    my $mx_id = shift;
    my $domain = $dbh->id2domain($domain_id);
    my ($name, $exchanger, $preference, $ttl) = $dbh->mx_lookup($domain_id, $mx_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_del_MX: ($domain) $name MX $preference $exchanger});
    $update->push("update", rr_del(qq{$name MX $preference $exchanger}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_del_MX (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->delete_MX($domain_id, $mx_id);
}

sub dns_set_NS {
    my $domain_id = shift;
    my $name = shift; 
    my $ns = shift;
    my $ttl = shift || 86400; 
    my $domain = $dbh->id2domain($domain_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_set_NS: $name NS $ns});
    $update->push("update", rr_add(qq{$name $ttl NS $ns}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_set_NS (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->set_NS($domain_id, $name, $ns, $ttl);
}

sub dns_update_NS {
    my $domain_id = shift;
    my $ns_id = shift;
    my $new_name = shift;
    my $new_ns = shift;
    my $new_ttl = shift || 86400;
    my $domain = $dbh->id2domain($domain_id);
    my ($old_name, $old_ns, $old_ttl) = $dbh->ns_lookup($domain_id, $ns_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{Apache::DnsZone::dns_update_NS (del): ($domain) $old_name NS $old_ns});
    $update->push("update", rr_del(qq{$old_name NS $old_ns}));
    Debug(5, qq{Apache::DnsZone::dns_update_NS (set): ($domain) $new_name $new_ttl NS $new_ns});
    $update->push("update", rr_add(qq{$new_name $new_ttl NS $new_ns}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_update_NS (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->update_NS($domain_id, $ns_id, $new_name, $new_ns, $new_ttl);
}

sub dns_del_NS {
    my $domain_id = shift;
    my $ns_id = shift;
    my $domain = $dbh->id2domain($domain_id);
    my ($name, $ns, $ttl) = $dbh->ns_lookup($domain_id, $ns_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_del_NS: ($domain) $name NS $ns});
    $update->push("update", rr_del(qq{$name NS $ns}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_del_NS (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->delete_NS($domain_id, $ns_id);
}

sub dns_set_TXT {
    my $domain_id = shift;
    my $name = shift;
    my $txt = shift;
    my $ttl = shift || 86400; 
    my $domain = $dbh->id2domain($domain_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_set_TXT: $name TXT $txt});
    $update->push("update", rr_add(qq{$name $ttl TXT $txt}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_set_TXT (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->set_TXT($domain_id, $name, $txt, $ttl);
}

sub dns_update_TXT {
    my $domain_id = shift;
    my $txt_id = shift;
    my $new_name = shift;
    my $new_txt = shift;
    my $new_ttl = shift || 86400;
    my $domain = $dbh->id2domain($domain_id);
    my ($old_name, $old_txt, $old_ttl) = $dbh->txt_lookup($domain_id, $txt_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{Apache::DnsZone::dns_update_TXT (del): ($domain) $old_name TXT '$old_txt'});
    $update->push("update", rr_del(qq{$old_name TXT '$old_txt'}));
    Debug(5, qq{Apache::DnsZone::dns_update_TXT (set): ($domain) $new_name $new_ttl TXT '$new_txt'});
    $update->push("update", rr_add(qq{$new_name $new_ttl TXT '$new_txt'}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_update_TXT (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->update_TXT($domain_id, $txt_id, $new_name, $new_txt, $new_ttl);
}

sub dns_del_TXT {
    my $domain_id = shift;
    my $txt_id = shift;
    my $domain = $dbh->id2domain($domain_id);
    my ($name, $txt, $ttl) = $dbh->txt_lookup($domain_id, $txt_id);
    my $update = new Net::DNS::Update($domain);
    Debug(5, qq{dns_del_TXT: ($domain) $name TXT $txt});
    $update->push("update", rr_del(qq{$name TXT $txt}));
    resolver_setup($domain_id);
    my $ans = $res->res->send($update);
    Debug(5, qq{Apache::DnsZone::dns_del_TXT (result): } . $ans->header->rcode);
    unless ($ans->header->rcode eq "NOERROR") { return 0; }
    return $dbh->delete_TXT($domain_id, $txt_id);
}

1;
