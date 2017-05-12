package Apache::DnsZone::DB::Oracle;

# $Id: Oracle.pm,v 1.8 2001/06/03 11:10:25 thomas Exp $

use strict;
use vars qw($VERSION);
($VERSION) = qq$Revision: 1.8 $ =~ /([\d\.]+)/;

package Apache::DnsZone::DB;

use strict;
use DBI;
use Apache::DnsZone;
use Apache::DnsZone::DB;

sub db_conn {
    my $dbsrc = shift;
    my $dbuser = shift;
    my $dbpass = shift;
    my $db = DBI->connect($dbsrc, $dbuser, $dbpass, { RaiseError => 1, AutoCommit => 0 });
    return $db;
}

sub a_lookup {
    my $self = shift;
    my $domain_id = shift;
    my $a_id = shift;
    my ($name, $ip, $ttl) = $self->{'dbh'}->selectrow_array("select name,address,ttl from records_A where id = ? and domain = ?", undef, $a_id, $domain_id);
    return $name, $ip, $ttl if wantarray;
    return qq{$name $ip $ttl};
}

sub cname_lookup {
    my $self = shift;
    my $domain_id = shift;
    my $cname_id = shift;
    my ($name, $cname, $ttl) = $self->{'dbh'}->selectrow_array("select name,cname,ttl from records_CNAME where id = ? and domain = ?", undef, $cname_id, $domain_id);
    return $name, $cname, $ttl if wantarray;
    return qq{$name $cname $ttl};
}

sub mx_lookup {
    my $self = shift;
    my $domain_id = shift;
    my $mx_id = shift;
    my ($name, $exchanger, $preference, $ttl) = $self->{'dbh'}->selectrow_array("select name,exchanger,preference,ttl from records_MX where id = ? and domain = ?", undef, $mx_id, $domain_id);
    return $name, $exchanger, $preference, $ttl if wantarray;
    return qq{$name $exchanger $preference $ttl};
}

sub ns_lookup {
    my $self = shift;
    my $domain_id = shift;
    my $ns_id = shift;
    my ($name, $ns, $ttl) = $self->{'dbh'}->selectrow_array("select name,nsdname,ttl from records_NS where id = ? and domain = ?", undef, $ns_id, $domain_id);
    return $name, $ns, $ttl if wantarray;
    return qq{$name $ns $ttl};
}

sub txt_lookup {
    my $self = shift;
    my $domain_id = shift;
    my $txt_id = shift;
    my ($name, $txt, $ttl) = $self->{'dbh'}->selectrow_array("select name,txtdata,ttl from records_TXT where id = ? and domain = ?", undef, $txt_id, $domain_id);
    return $name, $txt, $ttl if wantarray;
    return qq{$name $txt $ttl};
}

sub soa_lookup {
    my $self = shift;
    my $domain_id = shift;
    return $self->{'dbh'}->selectrow_array("select auth_ns, email, serial, refresh, retry, expire, default_ttl,rec_lock from soa where domain = ?", undef, $domain_id);
}

sub id2domain {
    my $self = shift;
    my $id = shift;
    return $self->{'dbh'}->selectrow_array("select domain from domains where id = ?", undef, $id);
}

sub domain2ns {
    my $self = shift;
    my $id = shift;
    return $self->{'dbh'}->selectrow_array("select domains.domain, soa.auth_ns from domains, soa where domains.id = soa.domain and domains.id = ?", undef, $id);
    # returns both domain and nameserver (used in resolver_setup)
}

sub get_auth_ns {
    my $self = shift;
    my $id = shift;
    return $self->{'dbh'}->selectrow_array("select auth_ns from soa where domain = ?", undef, $id);
}

sub get_authns_serial {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select auth_ns, serial from soa where domain = ?", undef, $dom_id);
}

sub get_user_info {
    my $self = shift;
    my $username = shift;
    return $self->{'dbh'}->selectrow_array("select users.id, users.email, users.lang, languages.lang from users,languages where users.username = ? and users.lang = languages.id", undef, $username);
}

sub get_user_id {
    my $self = shift;
    my $username = shift;
    return $self->{'dbh'}->selectrow_array("select users.id from users where users.username = ?", undef, $username);
}

sub get_user_lang_id {
    my $self = shift;
    my $uid = shift;
    return $self->{'dbh'}->selectrow_array("select users.lang from users where users.id = ?", undef, $uid);
}

sub get_user_lang {
    my $self = shift;
    my $username = shift;
    return $self->{'dbh'}->selectrow_array("select languages.lang from users, languages where users.username = ? and users.lang = languages.id", undef, $username);
}

sub set_user_lang_email {
    my $self = shift;
    my $uid = shift;
    my $lang_id = shift;
    my $email = shift;
    eval {
	my $sth = $self->{'dbh'}->prepare("update users set lang = ?, email = ? where id = ?");
	$sth->execute($lang_id, $email, $uid);
	$sth->finish();
	$self->{'dbh'}->commit();
    }
    if ($@) {
	$self->{'dbh'}->rollback();
	return 0;
    }
    return 1;
}

sub set_user_password {
    my $self = shift;
    my $uid = shift;
    my $password = shift;
    eval {
	my $sth = $self->{'dbh'}->prepare("update users set password = ? where id = ?");
	$sth->execute($password, $uid);
	$sth->finish();
	$self->{'dbh'}->commit();
    } 
    if ($@) {
	$self->{'dbh'}->rollback();
	return 0;
    }
    return 1;
}

sub get_domain_count {
    my $self = shift;
    my $uid = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from domains where owner = ?", undef, $uid);
}

sub get_one_domain_id {
    my $self = shift;
    my $uid = shift;
    return $self->{'dbh'}->selectrow_array("select id from domains where owner = ?", undef, $uid);
}

sub is_valid_lang {
    my $self = shift;
    my $lang_id = shift;
    return $self->{'dbh'}->selectrow_array("select 1 from languages where id = ?", undef, $lang_id);
}

sub is_valid_abbrev {
    my $self = shift;
    my $lang_abbrev = shift;
    return $self->{'dbh'}->selectrow_array("select 1 from languages where abbrev = ?", undef, $lang_abbrev);
}

sub get_lang_from_abbrev {
    my $self = shift;
    my $lang_abbrev = shift;
    return $self->{'dbh'}->selectrow_array("select lang from languages where abbrev = ?", undef, $lang_abbrev);
}

sub lang_select_box {
    my $self = shift;
    my $uid = shift;
    my $lang_id = shift || 0;
    if ($lang_id == 0) {
	$lang_id = $self->get_user_lang_id($uid);
    }
    my $lang_select = qq{<select name="lang">\n};
    my $sth_lang = $self->{'dbh'}->prepare("select id,lang,language from languages order by language asc");
    $sth_lang->execute();
    while (my ($l_id, $l_lang, $l_language) = $sth_lang->fetchrow_array()) {
	$lang_select .= qq{<option value="$l_id"};
	if ($lang_id == $l_id) {
	    $lang_select .= qq{ selected};
	}
	$lang_select .= qq{>$l_language ($l_lang)</option>\n};
    }
    $sth_lang->finish();
    $lang_select .= qq{</select>\n};
    return $lang_select;
}

sub update_password {
    my $self = shift;
    my $uid = shift;
    my $password = shift;
    eval {
	my $sth_password_update = $self->{'dbh'}->prepare("update users set password = ? where id = ?");
	$sth_password_update->execute($password, $uid);
	$sth_password_update->finish();
	$self->{'dbh'}->commit();
    }
    if ($@) {
	$self->{'dbh'}->rollback();
	return 0;
    }

    return 1;
}

sub domain_stat {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select domain,owner from domains where id = ?", undef, $dom_id);
}

sub get_max_record_count {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select A_count, CNAME_count, MX_count, NS_count, TXT_count from rec_count where domain = ?", undef, $dom_id);
}

sub get_a_count {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_A where domain = ?", undef, $dom_id);
}

sub does_A_exist {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_A where domain = ? and name = ?", undef, $dom_id, $host)
}

sub is_duplicate_A {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    my $address = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_A where domain = ? and name = ? and address = ?", undef, $dom_id, $host, $address)
}

sub get_cname_count {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_CNAME where domain = ?", undef, $dom_id);
}
sub does_CNAME_exist {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_CNAME where domain = ? and name = ?", undef, $dom_id, $host);
}

sub is_duplicate_CNAME {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    my $cname = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_CNAME where domain = ? and name = ? and cname = ?", undef, $dom_id, $host, $cname);
}

sub get_mx_count {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_MX where domain = ?", undef, $dom_id);
}

sub does_MX_exist {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_MX where domain = ? and name = ?", undef, $dom_id, $host);
}

sub is_duplicate_MX {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    my $preference = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_MX where domain = ? and name = ? and preference = ?", undef, $dom_id, $host, $preference);
}

sub get_ns_count {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_NS where domain = ?", undef, $dom_id);
}

sub does_NS_exist {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_NS where domain = ? and name = ?", undef, $dom_id, $host);
}

sub is_duplicate_NS {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    my $nsdname = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_NS where domain = ? and name = ? and nsdname = ?", undef, $dom_id, $host, $nsdname);
}

sub get_txt_count {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_TXT where domain = ?", undef, $dom_id);
}

sub does_TXT_exist {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_TXT where domain = ? and name = ?", undef, $dom_id, $host);
}

sub is_duplicate_TXT {
    my $self = shift;
    my $dom_id = shift;
    my $host = shift;
    my $txtdata = shift;
    return $self->{'dbh'}->selectrow_array("select count(id) from records_TXT where domain = ? and name = ? and txtdata = ?", undef, $dom_id, $host, $txtdata);
}

sub get_lock_SOA {
    my $self = shift;
    my $dom_id = shift;
    return $self->{'dbh'}->selectrow_array("select rec_lock from soa where domain = ?", undef, $dom_id);
}

sub get_lock_A {
    my $self = shift;
    my $dom_id = shift;
    my $record_id = shift;
    return $self->{'dbh'}->selectrow_array("select rec_lock from records_A where id = ? and domain = ?", undef, $record_id, $dom_id);
}

sub get_lock_CNAME {
    my $self = shift;
    my $dom_id = shift;
    my $record_id = shift;
    return $self->{'dbh'}->selectrow_array("select rec_lock from records_CNAME where id = ? and domain = ?", undef, $record_id, $dom_id);
}

sub get_lock_MX {
    my $self = shift;
    my $dom_id = shift;
    my $record_id = shift;
    return $self->{'dbh'}->selectrow_array("select rec_lock from records_MX where id = ? and domain = ?", undef, $record_id, $dom_id);
}

sub get_lock_NS {
    my $self = shift;
    my $dom_id = shift;
    my $record_id = shift;
    return $self->{'dbh'}->selectrow_array("select rec_lock from records_NS where id = ? and domain = ?", undef, $record_id, $dom_id);
}

sub get_lock_TXT {
    my $self = shift;
    my $dom_id = shift;
    my $record_id = shift;
    return $self->{'dbh'}->selectrow_array("select rec_lock from records_TXT where id = ? and domain = ?", undef, $record_id, $dom_id);
}

sub list_domains_prepare {
    my $self = shift;
    my $owner_id = shift;
    my $sth = $self->{'dbh'}->prepare("select id, domain from domains where owner = ?");
    $sth->execute($owner_id);
    return $sth;
}

sub view_domain_A_prepare {
    my $self = shift;
    my $dom_id = shift;
    my $sth = $self->{'dbh'}->prepare("select id, name, address, ttl, rec_lock from records_A where domain = ?");
    $sth->execute($dom_id);
    return $sth;
}

sub view_domain_CNAME_prepare {
    my $self = shift;
    my $dom_id = shift;
    my $sth = $self->{'dbh'}->prepare("select id, name, cname, ttl, rec_lock from records_CNAME where domain = ?");
    $sth->execute($dom_id);
    return $sth;
}

sub view_domain_MX_prepare {
    my $self = shift;
    my $dom_id = shift;
    my $sth = $self->{'dbh'}->prepare("select id, name, exchanger, preference, ttl, rec_lock from records_MX where domain = ?");
    $sth->execute($dom_id);
    return $sth;
}

sub view_domain_NS_prepare {
    my $self = shift;
    my $dom_id = shift;
    my $sth = $self->{'dbh'}->prepare("select id, name, nsdname, ttl, rec_lock from records_NS where domain = ?");
    $sth->execute($dom_id);
    return $sth;
}

sub view_domain_TXT_prepare {
    my $self = shift;
    my $dom_id = shift;
    my $sth = $self->{'dbh'}->prepare("select id, name, txtdata, ttl, rec_lock from records_TXT where domain = ?");
    $sth->execute($dom_id);
    return $sth;
}

sub set_A {
    my $self = shift;
    my $domain_id = shift;
    my $name = shift;
    my $ip = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::set_A called});
    eval {
	my $sth = $self->{'dbh'}->prepare("insert into records_A (id, domain, name, address, ttl) values (records_A_id.nextval, ?, ?, ?, ?)");
	$sth->execute($domain_id, $name, $ip, $ttl);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::set_A failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    return 1;
}

sub update_serial_soa {
    my $self = shift;
    my $domain_id = shift;
    my $serial = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_serial_soa called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update soa set serial = ? where domain = ?");
	$sth->execute($serial, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_SOA failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    return 1;
}

sub update_SOA {
    my $self = shift;
    my $domain_id = shift;
    my $serial = shift;
    my $soa_email = shift;
    my $refresh = shift;
    my $retry = shift;
    my $expire = shift;
    my $default_ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_SOA called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update soa set email = ?, serial = ?, refresh = ?, retry = ?, expire = ?, default_ttl = ? where domain = ?");
	$sth->execute($soa_email, $serial, $refresh, $retry, $expire, $default_ttl, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_SOA failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    return 1;
}

sub update_A {
    my $self = shift;
    my $domain_id = shift;
    my $a_id = shift;
    my $name = shift;
    my $ip = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_A called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update records_A set name = ?, address = ?, ttl = ? where id = ? and domain = ?");
	$sth->execute($name, $ip, $ttl, $a_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_A failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub delete_A {
    my $self = shift;
    my $domain_id = shift;
    my $a_id = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::delete_A called});
    eval {
	my $sth = $self->{'dbh'}->prepare("delete from records_A where id = ? and domain = ?");
	$sth->execute($a_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::delete_A failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub set_CNAME {
    my $self = shift;
    my $domain_id = shift;
    my $name = shift;
    my $cname = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::set_CNAME called});
    eval {
	my $sth = $self->{'dbh'}->prepare("insert into records_CNAME (id, domain, name, cname, ttl) values (records_CNAME_id.nextval, ?, ?, ?, ?)");
	$sth->execute($domain_id, $name, $cname, $ttl);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::set_CNAME failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub update_CNAME {
    my $self = shift;
    my $domain_id = shift;
    my $cname_id = shift;
    my $name = shift;
    my $cname = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_CNAME called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update records_CNAME set name = ?, cname = ?, ttl = ? where id = ? and domain = ?");
	$sth->execute($name, $cname, $ttl, $cname_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_CNAME failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub delete_CNAME {
    my $self = shift;
    my $domain_id = shift;
    my $cname_id = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::delete_CNAME called});
    eval {
	my $sth = $self->{'dbh'}->prepare("delete from records_CNAME where id = ? and domain = ?");
	$sth->execute($cname_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::delete_CNAME failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub set_MX {
    my $self = shift;
    my $domain_id = shift;
    my $name = shift;
    my $exchanger = shift;
    my $preferece = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::set_MX called});
    eval {
	my $sth = $self->{'dbh'}->prepare("insert into records_MX (id, domain, name, exchanger, preference, ttl) values (records_MX_id.nextval, ?, ?, ?, ?, ?)");
	$sth->execute($domain_id, $name, $exchanger, $preferece, $ttl);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::set_MX failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub update_MX {
    my $self = shift;
    my $domain_id = shift;
    my $mx_id = shift;
    my $name = shift;
    my $exchanger = shift;
    my $preference = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_MX called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update records_MX set name = ?, exchanger = ?, preference = ?, ttl = ? where id = ? and domain = ?");
	$sth->execute($name, $exchanger, $preference, $ttl, $mx_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_MX failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub delete_MX {
    my $self = shift;
    my $domain_id = shift;
    my $mx_id = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::delete_MX called});
    eval {
	my $sth = $self->{'dbh'}->prepare("delete from records_MX where id = ? and domain = ?");
	$sth->execute($mx_id, $domain_id);
	$sth->prepare();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::delete_MX failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub set_NS {
    my $self = shift;
    my $domain_id = shift;
    my $name = shift;
    my $ns = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::set_NS called});
    eval {
	my $sth = $self->{'dbh'}->prepare("insert into records_NS (id, domain, name, nsdname, ttl) values (records_NS_id.nextval, ?, ?, ?, ?)");
	$sth->execute($domain_id, $name, $ns, $ttl);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::set_NS failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub update_NS {
    my $self = shift;
    my $domain_id = shift;
    my $ns_id = shift;
    my $name = shift;
    my $ns = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_NS called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update records_NS set name = ?, nsdname = ?, ttl = ? where id = ? and domain = ?");
	$sth->execute($name, $ns, $ttl, $ns_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_NS failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub delete_NS {
    my $self = shift;
    my $domain_id = shift;
    my $ns_id = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::delete_NS called});
    eval {
	my $sth = $self->{'dbh'}->prepare("delete from records_NS where id = ? and domain = ?");
	$sth->execute($ns_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::delete_NS failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub set_TXT {
    my $self = shift;
    my $domain_id = shift;
    my $name = shift;
    my $txt = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::set_TXT called});
    eval {
	my $sth = $self->{'dbh'}->prepare("insert into records_TXT (id, domain, name, txtdata, ttl) values (records_TXT_id.nextval, ?, ?, ?, ?)");
	$sth->execute($domain_id, $name, $txt, $ttl);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::set_TXT failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub update_TXT {
    my $self = shift;
    my $domain_id = shift;
    my $txt_id = shift;
    my $name = shift;
    my $txt = shift;
    my $ttl = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::update_TXT called});
    eval {
	my $sth = $self->{'dbh'}->prepare("update records_TXT set name = ?, txtdata = ?, ttl = ? where id = ? and domain = ?");
	$sth->execute($name, $txt, $ttl, $txt_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::update_TXT failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

sub delete_TXT {
    my $self = shift;
    my $domain_id = shift;
    my $txt_id = shift;
    Apache::DnsZone::Debug(5, qq{Apache::DnsZone::DB::delete_TXT called});
    eval {
	my $sth = $self->{'dbh'}->prepare("delete from records_TXT where id = ? and domain = ?");
	$sth->execute($txt_id, $domain_id);
	$sth->finish();
	$self->{'dbh'}->commit();
    };
    if ($@) {
        Apache::DnsZone::Debug(1, qq{Apache::DnsZone::DB::delete_TXT failed: $@});
	$self->{'dbh'}->rollback();
	return 0;
    }
    Apache::DnsZone::update_serial($domain_id);
    return 1;
}

1;
