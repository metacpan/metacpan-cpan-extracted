# $Id: test.pl,v 1.1.1.1 2002/07/26 18:58:46 root Exp $
# $Log: test.pl,v $
# Revision 1.1.1.1  2002/07/26 18:58:46  root
# initial
#
# Revision 0.3  1998/10/22 02:49:53  meltzek
# Added verbose begining and ending of test.
#
# Revision 0.2  1998/10/22 02:46:56  meltzek
# Added new checks.
#

BEGIN { $| = 1; print "Tests 1..20 begining\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::Htpasswd;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub report_result {
	my $ok = shift;
	$TEST_NUM ||= 2;
	print "not " unless $ok;
	print "ok $TEST_NUM\n";
	print "@_\n" if (not $ok and $ENV{TEST_VERBOSE});
	$TEST_NUM++;
}

sub report_skip {
        my $why = shift;
        print "not ok $TEST_NUM # SKIP $why\n";
	$TEST_NUM++;
}

# Create a test password file
my $File = "testpasswords.test";
open(TEST,">$File") || die "Can't run tests because I can't create $File [$!]";
print TEST "kevin:kjDqW.pgNIz3Ufoo:suvPq./X7Q8nk\n";
close TEST;



{
	
	# 2: Get file
	&report_result($pwdFile = new Apache::Htpasswd ($File), $! );

	# 3: store a value
	&report_result($pwdFile->htpasswd("foo","foobar") , $! );

	# 4: change value 
	&report_result(!$pwdFile->htpasswd("fooo", "goo","foobar" ) , $! );
	&report_result($pwdFile->htpasswd("foo", "goo","foobar" ) , $! );
	
	# 5: force change value
	&report_result($pwdFile->htpasswd("foo","ummm",{'overwrite' => 1}), $! );

	# 6: check the stored value
	&report_result($pwdFile->fetchPass("foo") , $!);

	# 7: check whether the empty key exists()
	&report_result($pwdFile->htCheckPassword("foo","ummm"),$!);

	# 8: add extra info
	&report_result($pwdFile->writeInfo("kevin", "Test info"),$!);
	
	# 9: fetch extra info
	&report_result($pwdFile->fetchInfo("kevin"),$!);
	
	# 10: Delete user
	&report_result($pwdFile->htDelete("kevin"),$!);
	
        # 11: get list
        my @list = $pwdFile->fetchUsers();
        &report_result($list[0] eq 'foo', $!);

	# 12: get number of users
        my $num  = $pwdFile->fetchUsers();
        &report_result($num == 1, $!);

	undef $pwdFile;

	# 13: Create in read-only mode
        &report_result($pwdFile = new Apache::Htpasswd({passwdFile => $File, ReadOnly => 1}), $! );

  # 14: store a value (should fail)
	# Should carp, but don't want to display it
	sub Apache::Htpasswd::carp {};
        &report_result(!$pwdFile->htpasswd("kevin","zog") , $! );

}

open(TEST,">>$File");
print TEST "cryptuser:Iao36C/TVmCRc\n";
print TEST "MD5user:\$apr1\$Yy.pS/..\$4bwpMUiVq/95BDr4kZ2lK.\n";
print TEST "SHA1user:{SHA}QL0AFWMIX8NRZTKeof9cXsvbvu8=\n";
print TEST "plainuser:123\n";
close TEST;

{
	# 16: Create in read-only mode with UsePlain
        &report_result($pwdFile = new Apache::Htpasswd({passwdFile => $File, ReadOnly => 1, UsePlain => 1}), $! );

	# 17: check whether crypt passwords work
	&report_result($pwdFile->htCheckPassword("cryptuser","123"),$!);

	# 18: check whether MD5 passwords work
        eval { require Crypt::PasswdMD5 };
        if ($@) {
            &report_skip('Crypt::PasswdMD5 required for this test');
        } else {
            &report_result($pwdFile->htCheckPassword("MD5user","123"),$!);
        }

	# 19: check whether SHA1 passwords work
        eval { require Digest::SHA; require MIME::Base64 };
        if ($@) {
            &report_skip('Digest::SHA and MIME::Base64 required for this test');
        } else {
            &report_result($pwdFile->htCheckPassword("SHA1user","123"),$!);
        }

	# 20: check whether plain passwords work
	&report_result($pwdFile->htCheckPassword("plainuser","123"),$!);

}

print "Test complete.\n";
