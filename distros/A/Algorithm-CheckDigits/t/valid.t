# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use vars qw(@testcases);
use Test;
BEGIN {
        do 't/valid.data';
	plan(tests => ($#testcases + 1) * 5); 
};
use Algorithm::CheckDigits;

my $checkdigit;

foreach my $tcase (@testcases) {
	if ($checkdigit = CheckDigits($tcase->[0])) {
		my $is_valid = $checkdigit->is_valid($tcase->[1]);
		ok($is_valid
		  ,1
		  ,"is_valid $tcase->[0] $tcase->[1]"
		  );
		my $skip = not $is_valid;
		skip($skip
		    ,$checkdigit->complete($tcase->[2])
		    ,$tcase->[1]
		    ,"complete $tcase->[0]"
		    );
		skip($skip
		    ,$checkdigit->basenumber($tcase->[1])
		    ,$tcase->[2]
		    ,"basenumber $tcase->[0]"
		    );
		skip($skip
		    ,$checkdigit->checkdigit($tcase->[1])
		    ,$tcase->[3]
		    ,"checkdigit $tcase->[0]"
		    );
		skip($skip
		    ,(not $checkdigit->is_valid($tcase->[4]))
		    ,1
		    ,"not is_valid $tcase->[0]: $tcase->[4]"
		    );
	}
}
