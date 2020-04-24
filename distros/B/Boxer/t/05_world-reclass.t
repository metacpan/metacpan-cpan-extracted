#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use Test::Fatal;
use Test::Deep qw(:v1);
use Path::Tiny;
use Log::Any::Test;
use Log::Any qw($log);

use strictures 2;
no warnings "experimental::signatures";

use_ok('Boxer::World::Reclass');

my $world = new_ok(
	'Boxer::World::Reclass' => [
		suite => 'buster',
		data  => path('examples'),
	]
);
cmp_deeply $world, all(
	obj_isa('Boxer::World::Reclass'),
	methods(
		parts => all(
			arraylength(3),
			array_each( obj_isa('Boxer::Part::Reclass') ),
		),
		[ 'get_part', 'lxp5' ] => obj_isa('Boxer::Part::Reclass'),
		[ 'get_part', 'foo' ]  => undef,
	),
	listmethods(
		list_parts => bag(qw( lxp5 parl-greens zsh )),
	),
	noclass(
		{   data             => obj_isa('Path::Tiny'),
			classdir         => obj_isa('Path::Tiny'),
			nodedir          => obj_isa('Path::Tiny'),
			parts            => ignore(),
			suite            => 'buster',
			_logger          => ignore(),
			_logger_category => ignore(),
		}
	)
	),
	'world contains expected methods and data';
$log->category_contains_ok(
	'Boxer::World::Reclass',
	qr/^Part "foo" does not exist\.$/, 'failure logged'
);
$log->empty_ok("no more logs");

subtest 'from explicit classdir' => sub {
	my $world = new_ok(
		'Boxer::World::Reclass' => [
			suite    => 'buster',
			data     => path('examples'),
			classdir => path('examples/classes'),
		]
	);
	cmp_deeply $world, obj_isa('Boxer::World::Reclass'),
		'world contains expected methods and data';
	$log->empty_ok("no more logs");
};

subtest 'from explicit nodedir' => sub {
	my $world = new_ok(
		'Boxer::World::Reclass' => [
			suite   => 'buster',
			data    => path('examples'),
			nodedir => path('examples/nodes'),
		]
	);
	cmp_deeply $world, obj_isa('Boxer::World::Reclass'),
		'world contains expected methods and data';
	$log->empty_ok("no more logs");
};

subtest 'from explicit dirs' => sub {
	my $world = new_ok(
		'Boxer::World::Reclass' => [
			suite    => 'buster',
			classdir => path('examples/classes'),
			nodedir  => path('examples/nodes'),
		]
	);
	cmp_deeply $world, obj_isa('Boxer::World::Reclass'),
		'world contains expected methods and data';
	$log->empty_ok("no more logs");
};

subtest 'from empty dirs' => sub {
	my $dir1  = Path::Tiny->tempdir;
	my $dir2  = Path::Tiny->tempdir;
	my $world = new_ok(
		'Boxer::World::Reclass' => [
			suite    => 'foo',
			classdir => $dir1,
			nodedir  => $dir2,
		]
	);
	cmp_deeply $world, all(
		obj_isa('Boxer::World'),
		methods(
			parts                  => arraylength(0),
			[ 'get_part', 'lxp5' ] => undef,
		),
		),
		'world contains expected methods and data';
	$log->category_contains_ok(
		'Boxer::World::Reclass',
		qr/^No parts exist\.$/, 'failure logged'
	);
	$log->empty_ok("no more logs");
};

subtest 'for empty suite' => sub {
	my $dir1 = Path::Tiny->tempdir;
	my $dir2 = Path::Tiny->tempdir;
	like exception {
		Boxer::World::Reclass->new(
			suite    => '',
			classdir => $dir1,
			nodedir  => $dir2,
		);
	}, qr/^Must be a single lowercase word/, 'Died as expected';
	$log->empty_ok("no more logs");
};

subtest 'from nonexistent classdir' => sub {
	my $tempdir = Path::Tiny->tempdir;
	like exception {
		Boxer::World::Reclass->new(
			suite    => 'foo',
			classdir => $tempdir->child('foo'),
			nodedir  => path('examples/nodes'),
		);
	},
		qr/Must be an existing directory containing boxer classes/,
		'Died as expected on non-existing classdir';
	$log->empty_ok("no more logs");
};

subtest 'from nonexistent nodedir' => sub {
	my $tempdir = Path::Tiny->tempdir;
	like exception {
		Boxer::World::Reclass->new(
			suite    => 'foo',
			classdir => path('examples/classes'),
			nodedir  => $tempdir->child('bar'),
		);
	},
		qr/Must be an existing directory containing boxer nodes/,
		'Died as expected on non-existing classdir';
	$log->empty_ok("no more logs");
};

my $node_cmp_lxp5 = {
	doc => {
		admin => {
			headline => bag('Administration'),
			pkg      => bag(
				'include Backupninja hook to save to remote host',
				'include backup system Backupninja',
				'include hardening tools',
				'include passive account hardening PAM plugin cracklib',
				'include support and tools for Logical Volume Management',
				'include web-of-trust hardening tool Monkeysphere',
			),
			tweak => bag(
				'include config file VCS tracking tool etckeeper',
			),
		},
		console => {
			headline => bag('Console'),
			pkg      => bag(
				'install console editor ViM',
				'install console multiplexer GNU screen',
			),
		},
		'console-mail' => {
			headline => bag('Console mail'),
			pkg      => bag(
				'include console tool listadmin to moderate Mailman mailinglists',
			),
		},
		framework => {
			headline => bag('Framework'),
			pkg      => bag(
				'exclude WebKit GTK+ 1.0 library (used for maybe-risky PAC proxy parsing)',
			),
		},
		hardware => {
			headline => bag('Hardware'),
			pkg      => bag(
				'include core support for board with older 32bit Intel Atom CPU',
				'include low-level crypto hardening tools',
			),
			'pkg-nonfree' => bag(
				'include firmware for Realtek NIC drivers',
			),
		},
		service => {
			headline => bag('Service'),
			pkg      => bag(
				'include antispam service AMaViS (with SpamAssassin)',
				'include antivirus service ClamAV',
				'include authoritative domain name service BIND',
				'include DHCP client service',
				'include git service',
				'include intrusion detection system fail2ban',
				'include remote access to console (ssh)',
			),
		},
		'service-log' => {
			headline => bag('Syslog service'),
			pkg      => bag(
				'include syslog service Rsyslog',
			),
		},
		'service-mail' => {
			headline => bag('Mail service'),
			pkg      => bag(
				'include Dovecot Sieve filter and Managesieve service',
				'include IMAP mail access service using Dovecot',
				'include mailinglist service Mailman',
				'install mail delivery agent Dovecot',
				'install mail transport agent Postfix',
				'install SASL email authentication using Dovecot and Cyrus',
			),
		},
		'service-web' => {
			headline => bag('Web service'),
			pkg      => bag(
				'include webmail service CiderWebmail',
				'include wiki service MoinMoin',
				'install Apache2 plugin GnuTLS',
				'install uWSGI plugin for Perl PSGI interface',
				'install uWSGI plugin for Python WSGI interface',
				'install web service Apache2',
				'install web service uWSGI',
			),
		},
	},
	epoch => 'buster',
	id    => 'lxp5',
	pkg   => bag(
		'acpi-support-base',
		'amavisd-new',
		'apache2-mpm-worker',
		'arj',
		'backupninja',
		'bind9',
		'bzip2',
		'cabextract',
		'changetrack',
		'clamav-daemon',
		'debconf-utils',
		'dovecot-core',
		'dovecot-imapd',
		'dovecot-managesieve',
		'dovecot-sieve',
		'e2fsck-static',
		'etckeeper',
		'fail2ban',
		'firmware-linux-free',
		'git-daemon-sysvinit',
		'gitweb',
		'harden',
		'haveged',
		'isc-dhcp-client',
		'lhasa',
		'libpam-cracklib',
		'linux-image-686',
		'listadmin',
		'lvm2',
		'lzop',
		'mailman',
		'miscfiles',
		'molly-guard',
		'monkeysphere',
		'nomarch',
		'p7zip',
		'postfix',
		'pyzor',
		'razor',
		'rdiff-backup',
		'rkhunter',
		'rsyslog',
		'samhain',
		'sash',
		'sasl2-bin',
		'screen',
		'spamassassin',
		'sudo',
		'systraq',
		'task-ssh-server',
		'unhide.rb',
		'unrar-free',
		'uwsgi',
		'uwsgi-plugin-psgi',
		'uwsgi-plugin-python',
		'vim',
		'zoo',
	),
	'pkg-auto' => bag(
		'ciderwebmail',
		'dovecot-core',
		'miscfiles',
		'ncurses-term',
		'openssh-blacklist',
		'openssh-blacklist-extra',
		'openssh-client',
		'openssh-server',
		'python-moinmoin',
		'samhain',
		'sash',
		'unhide.rb',
	),
	'pkg-avoid' => bag(
		'libwebkitgtk-1.0-0',
		'spamc',
	),
	'pkg-nonfree' => bag(
		'firmware-linux',
		'firmware-realtek',
	),
	'pkg-nonfree-auto' => bag(
		'firmware-linux-free',
	),
};
my $node_lxp5 = $world->get_part('lxp5');
cmp_deeply $node_lxp5,
	all(
	obj_isa('Boxer::Part'),
	noclass($node_cmp_lxp5),
	),
	'node "lxp5" contains expected data';
$log->empty_ok("no more logs");

my $node_cmp_zsh = {
	doc => {
		console => {
			pkg => bag(
				'include terminal shell zsh',
			),
		},
	},
	epoch => 'buster',
	id    => 'zsh',
	pkg   => bag(
		'zsh',
	),
};
my $node_zsh = $world->get_part('zsh');
cmp_deeply $node_zsh,
	all(
	obj_isa('Boxer::Part'),
	noclass($node_cmp_zsh),
	),
	'node "zsh" contains expected data';
$log->empty_ok("no more logs");

done_testing();
