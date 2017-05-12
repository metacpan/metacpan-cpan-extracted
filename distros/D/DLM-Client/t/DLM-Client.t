# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DLM-Client.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('DLM::Client') };


my $fail = 0;
foreach my $constname (qw(
	DLM_LOCKSPACE_LEN DLM_LSFL_FS DLM_LSFL_NEWEXCL DLM_LSFL_NODIR
	DLM_LSFL_TIMEWARN DLM_LVB_LEN DLM_RESNAME_MAXLEN DLM_SBF_ALTMODE
	DLM_SBF_DEMOTED DLM_SBF_VALNOTVALID ECANCEL EINPROG EUNLOCK LKF_ALTCW
	LKF_ALTPR LKF_CANCEL LKF_CONVDEADLK LKF_CONVERT LKF_EXPEDITE
	LKF_FORCEUNLOCK LKF_HEADQUE LKF_IVVALBLK LKF_NODLCKBLK LKF_NODLCKWT
	LKF_NOORDER LKF_NOQUEUE LKF_NOQUEUEBAST LKF_ORPHAN LKF_PERSISTENT
	LKF_QUECVT LKF_TIMEOUT LKF_VALBLK LKF_WAIT LKM_CRMODE LKM_CWMODE
	LKM_EXMODE LKM_NLMODE LKM_PRMODE LKM_PWMODE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined DLM::Client macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

