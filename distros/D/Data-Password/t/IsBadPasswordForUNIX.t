# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use Test::More qw(no_plan);

use Data::Password qw(IsBadPasswordForUNIX $MAXLEN @DICTIONARIES); 

ok(1,'Module Loaded');

eval {
	$_=getpwnam('IsBadPassword');
	};

my $have_getpwnam = $@ ? 0 :1;

my %tests = qw(BlaBla 1 blabla 0 cleaner 0 qwerTy 0 
   aB1234 0 xxxZZZ 1 xxxxZZ 0 
   Abramson 0 
   noboXX 1 MAxLEN1288457 0 MAXlen12r45f7 1
);
my $have_dic =0;
my $dic_name = '';

#@DICTIONARIES = undef;
@DICTIONARIES = qw(t/words words);
foreach (@DICTIONARIES){
	if (-r $_ && /words$/) {
	 	$have_dic = 1;
		$dic_name=$_;
		last;
	 };
}

ok($have_dic eq 1,"Dictionary '$dic_name' loaded");

SKIP: {
   skip 'No getpwnam on this platform',scalar(keys(%tests)) unless $have_getpwnam;
   $tests{Abramson} = $have_dic ? 0 : 1;

   while (my ($pass, $good) = each %tests) {
        $MAXLEN = $pass eq 'MAXlen12r45f7' ? 0 : 8;	
	my $reason = IsBadPasswordForUNIX('IsBadPassword',$pass) || '';
	my $got = $reason ? 0 : 1;
	ok($got eq $good,"$pass: $reason");
   }
}
