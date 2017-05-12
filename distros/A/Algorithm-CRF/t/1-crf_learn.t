# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1-crf_learn.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Algorithm::CRF') };

my $s = new Algorithm::CRF;
#ok($s->CRFpp_Learn("-t -c 10.0 template train.data model")==0, "crfpp_learn");
ok(Algorithm::CRF::crfpp_learn("t/template",
	"t/train.data",
	"t/model",
	1, #textmodelfile
	100000, # maxitr
	1, # freq
	0.0001, # eta
	10, # C
	1, # threads
	20, # shrinking_size
        0, # algorithm , 0 for CRF
        0)==0, "CRFPP_LEARN");

