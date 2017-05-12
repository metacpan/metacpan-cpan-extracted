
print<<EOIntro;

To more thoroughly test this module, prior to install, you'll want the
following modules:

 Test::Output - to test autoprint => 1, autoprint => 2
 Test::Warn - to verify warnings on errant usages

With them, you should get following results from `make testcover`

----------------------------------- ------ ------ ------ ------ ------ ------
File                                  stmt branch   cond    sub   time  total
----------------------------------- ------ ------ ------ ------ ------ ------
blib/lib/Data/Dumper/EasyOO.pm       100.0   96.3  100.0  100.0  100.0   99.1
Total                                100.0   96.3  100.0  100.0  100.0   99.1
----------------------------------- ------ ------ ------ ------ ------ ------

Yes, Im pleased with myself :-) Even though its just a wrapper, I did
spend some time tweaking the tests to get the numbers up.

More to the point, if you bother to install those things & run
coverage, and you get results different than this on your platform,
I'd be interested to know.  Thanks.

If you dont bother, thats ok too.


EOIntro

use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Data::Dumper::EasyOO',
     license => 'perl',
     requires => {
	 'perl'           => '5.005_03',
	 'Data::Dumper'   => '2.00',
     },
     recommends => {
	 Test::Output => 0,
	 Test::Warn => 0,
       },
     create_readme => 1,
     );
$build->create_build_script;

