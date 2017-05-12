
use POSIX qw(strftime);
use Authen::Krb5::KDB_H qw(:Attributes);

sub check_principals ($$) {
    my $pr = shift;
    my $no_tl = shift;

    my $found_princ = 0;
    my $found_tl = 0;
    my $found_tl2 = 0;
    my $found_key = 0;
    my $found_key1 = 0;
    my $found_keydata = 0;

    print "not " unless (ref($pr) eq "ARRAY");
    print "ok 6\n";
    print "not " unless (scalar @{$pr} == 9);
    print "ok 7\n";

    foreach my $p (@{$pr}) {
	if ($p->name eq 'foo@TEST.ORG') {
	    $found_princ++;
	    print "not " unless ($p->name_len == length($p->name));
	    print "ok 8\n";

	    print "not " unless ($p->attributes == 128);
	    print "ok 9\n";

	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_POSTDATED);
	    print "ok 10\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_FORWARDABLE);
	    print "ok 11\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_TGT_BASED);
	    print "ok 12\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_RENEWABLE);
	    print "ok 13\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_PROXIABLE);
	    print "ok 14\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_DUP_SKEY);
	    print "ok 15\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_ALL_TIX);
	    print "ok 16\n";
	    print "not " unless ($p->attributes & KRB5_KDB_REQUIRES_PRE_AUTH);
	    print "ok 17\n";
	    print "not " unless ($p->attributes | KRB5_KDB_REQUIRES_HW_AUTH);
	    print "ok 18\n";
	    print "not " unless ($p->attributes | KRB5_KDB_REQUIRES_PWCHANGE);
	    print "ok 19\n";
	    print "not " unless ($p->attributes | KRB5_KDB_DISALLOW_SVR);
	    print "ok 20\n";
	    print "not " unless ($p->attributes | KRB5_KDB_PWCHANGE_SERVICE);
	    print "ok 21\n";
	    print "not " unless ($p->attributes | KRB5_KDB_SUPPORT_DESMD5);
	    print "ok 22\n";
	    print "not " unless ($p->attributes | KRB5_KDB_NEW_PRINC);
	    print "ok 23\n";

	    print "not " unless ($p->max_life == 36000);
	    print "ok 24\n";

	    print "not " unless ($p->max_renew_life == 604800);
	    print "ok 25\n";

	    print "not " unless ($p->expiration == 0);
	    print "ok 26\n";

	    print "not " unless ($p->pw_expiration == 0);
	    print "ok 27\n";

	    print "not " unless ($p->last_success == 0);
	    print "ok 28\n";

	    print "not " unless ($p->last_success_dt eq '[never]');
	    print "ok 29\n";

	    print "not " unless ($p->last_failed == 0);
	    print "ok 30\n";

	    print "not " unless ($p->last_failed_dt eq '[never]');
	    print "ok 31\n";

	    print "not " unless ($p->fail_auth_count == 0);
	    print "ok 32\n";

	    foreach my $tl (@{$p->tl_data()}) {
		$found_tl++;
		if ($tl->type == 2) {
		    $found_tl2++;

		    print "not " unless ($tl->length == length($tl->contents)/2);
		    print "ok 33\n";

		    print "not "
			unless ($tl->contents eq
				'c124913c737465696e65722f61646d696e40544553542e4f524700');
		    print "ok 34\n";

		    # need to convert date to local timezone
		    my @tm = localtime(1016145089);
		    my $date = strftime("%a %b %d %H:%M:%S %Z %Y", @tm);
		    print "not "
			unless ($tl->parse_contents eq
				"$date: steiner/admin\@TEST.ORG\c@");
		    print "ok 35\n";
		}
	    }

	    foreach my $key (@{$p->key_data()}) {
		$found_key++;
		if ($key->version == 1) {
		    $found_key1++;
		    
		    print "not " unless( $key->kvno == 1);
		    print "ok 36\n";

		    while ($key->next_data()) {
			$found_keydata++;

			print "not " unless ($key->type == 1);
			print "ok 37\n";

			print "not " unless ($key->length == length($key->contents)/2);
			print "ok 38\n";

			print "not "
			    unless ($key->contents eq
				    '0800bcbd5223490356a299bc4f899d318a73ab66c2a751e8de58');
			print "ok 39\n";
		    }
		}
	    }

	    print "not " unless ($p->e_data == -1);
	    print "ok 40\n";
	}
    }

    print "not " unless ($found_princ);
    print "ok 41\n";

    print "not " unless ($found_tl == $no_tl);
    print "ok 42\n";
    print "not " unless ($found_tl2);
    print "ok 43\n";

    print "not " unless ($found_key == 2);
    print "ok 44\n";
    print "not " unless ($found_key1);
    print "ok 45\n";
    print "not " unless ($found_keydata);
    print "ok 46\n";
}

1;

