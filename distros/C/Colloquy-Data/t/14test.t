# $Id: 14test.t 528 2006-05-29 12:47:38Z nicolaw $

chdir('t') if -d 't';

use strict;
use Test::More;
eval "use Test::Deep";
if ($@) { plan skip_all => "Test::Deep required for testing parse_lin()"; }
else { plan tests => 3; }

use lib qw(./lib ../lib);
use Colloquy::Data qw(:all);

eval {
	for my $file (
		qw(users/jane users/john
		lists/vent lists/perl lists/girlsonly)
	  ) {
		chmod(0644, "data1.4/$file");
	}
};

my $data = _data();
cmp_deeply((users("data1.4"))[0], $data->{users}, "users()");
cmp_deeply((lists("data1.4"))[0], $data->{lists}, "lists()");

SKIP: {
	skip(  "Permissions test skipped for v1.15 or higher because of use of the Safe module",
		1)
	  if $Colloquy::Data::VERSION >= 1.15;

	eval {
		my $oldW = $^W;
		$^W = 0;
		chmod(0666, "data1.4/lists/girlsonly");
		my ($lists) = lists("data1.4");
		$^W = $oldW;
	};
	ok($@ =~ /insecure/, 'dies properly on insecure permissions');
}

sub _data {
	my $return = {
		'lists' => {
			'perl' => {  'owner'   => 'neech',
				'members' => [  'neech', 'zoe',    'goolies', 'tims',
					'pkent', 'botbot', 'milky',   'tomc',
					'flux'
				],
				'created'  => 'Sat Nov  5 22:04:49 2005',
				'flags'    => 'P',
				'masters'  => {},
				'listname' => 'perl',
				'used'     => 1132529518,
				'users'    => [ 'neech', 'zoe',    'goolies', 'tims',
					'pkent', 'botbot', 'milky',   'tomc',
					'flux'
				],
				'description' => 'For perl chat'
			},
			'girlsonly' => {
				'owner'   => 'jen',
				'members' => [  'neech', 'zoe',      'jen',    'becky',
					'sarah', 'heathers', 'botbot', 'neonkandi'
				],
				'created'  => 'Wed Nov  9 15:21:57 2005',
				'flags'    => 'PL',
				'masters'  => {},
				'listname' => 'GirlsOnly',
				'used'     => 1132857821,
				'users'    => [ 'neech', 'zoe',      'jen',    'becky',
					'sarah', 'heathers', 'botbot', 'neonkandi'
				],
				'description' => 'Just for girls.'
			},
			'vent' => {  'owner'   => 'heds',
				'members' => [  'neech', 'goolies', 'heathers', 'zoe',
					'bob',   'botbot',  'ricky',    'heds',
					'tims'
				],
				'created'  => 'Fri Nov 11 10:48:49 2005',
				'flags'    => 'P',
				'masters'  => {},
				'listname' => 'vent',
				'used'     => 1132957959,
				'users'    => [ 'neech', 'goolies', 'heathers', 'zoe',
					'bob',   'botbot',  'ricky',    'heds',
					'tims'
				],
				'description' => 'Moan moan moan moan moan'
			}
		},

		'users' => {
			'tims' => {'lists' => ['perl', 'vent']},
			'heds' => {'lists' => ['vent']},
			'tomc' => {'lists' => ['perl']},
			'neech' => {'lists' => ['perl', 'girlsonly', 'vent']},
			'flux'  => {'lists' => ['perl']},
			'heathers' => {'lists' => ['girlsonly', 'vent']},
			'botbot'   => {'lists' => ['perl',      'girlsonly', 'vent']},
			'jen'       => {'lists' => ['girlsonly']},
			'becky'     => {'lists' => ['girlsonly']},
			'milky'     => {'lists' => ['perl']},
			'ricky'     => {'lists' => ['vent']},
			'neonkandi' => {'lists' => ['girlsonly']},
			'goolies'   => {'lists' => ['perl', 'vent']},
			'jane' => {  'width'    => 79,
				'lastQuit' => '(brb)',
				'around'   => 'on the special bus',
				'restrict' => '',
				'failed'   => 0,
				'termType' => 'colour',
				'email'    => 'jane@doe.org',
				'password' => '801178f0439098fvd8808ewjj2o3j12d',
				'timeWarn' => 0,
				'colours'  =>
				  '!talk!brcyan:black!tell!green:none!list!brblue:none!listname!bryellow:none!shout!brred:none!message!bryellow:black!nick!bryellow:red!me!brwhite:none',
				'timeon'    => 2189220,
				'lastLogon' =>
				  'Sat Dec  3 01:57:25 2005 - Mon Dec  5 16:15:14 2005',
				'talkBytes'  => 236987,
				'birthday'   => '1982-01-15',
				'flags'      => 'ceBpSMLwI',
				'interests'  => 'hamsters, cookery',
				'location'   => 'London, UK',
				'lang'       => 'en-gb',
				'name'       => 'Jane Doe',
				'occupation' => 'Maker of awesome food',
				'privs'      => 'EGKNW',
				'sex'        => 'female',
				'totalIdle'  => '24933640665',
				'created'    => 'Thu Nov  3 23:04:18 2005 by neech',
				'homepage'   => 'http://www.janedoe.org/food/',
				'aliases'    => 'jooles',
				'lastSite'   => 'nice.server.foo.com'
			},
			'john' => {  'width'    => 79,
				'lastQuit' => '(new kernel)',
				'restrict' => '',
				'failed'   => 0,
				'termType' => 'colour',
				'email'    => 'john@foobar.co.uk',
				'password' => '38dfd7623iuhihu011559912413af995',
				'timeWarn' => 0,
				'colours'  =>
				  '!talk!white:none!tell!green:none!list!brblue:none!listname!bryellow:none!shout!brred:none!message!brwhite:none!nick!bryellow:red!me!brwhite:none',
				'timeon'    => 1902252,
				'lastLogon' =>
				  'Wed Nov 30 11:44:50 2005 - Sat Dec  3 00:28:16 2005',
				'talkBytes'  => 25972,
				'birthday'   => '1978-03-27',
				'flags'      => 'CeBpSMLwI',
				'lang'       => 'en-gb',
				'location'   => 'Scotland',
				'name'       => 'Andrew Berry',
				'occupation' => 'IT Manager',
				'sex'        => 'male',
				'totalIdle'  => '18127533640',
				'homepage'   => 'http://www.foobar.co.uk',
				'created'    => 'Mon Nov  7 13:23:00 2005 by neech',
				'aliases'    => 'todd richard',
				'lastSite'   => '82-40-3-237.cable.ubr01.uddi.foobar.co.uk'
			},
			'pkent' => {'lists' => ['perl']},
			'zoe'   => {'lists' => ['perl', 'girlsonly', 'vent']},
			'sarah' => {'lists' => ['girlsonly']},
			'bob'   => {'lists' => ['vent']}
		}};
	return $return;
}

1;

