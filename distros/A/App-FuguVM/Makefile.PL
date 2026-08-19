use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::FuguVM',
	VERSION          => '0.1.1',
	ABSTRACT         => 'install and manage OpenBSD virtual machines under QEMU',
	LICENSE          => 'open_source',
	MIN_PERL_VERSION => '5.036',
	EXE_FILES        => [
		'bin/fuguvm'
	],
	PREREQ_PM        => {
		'Net::SSH2' => 0,
		'HTTP::Daemon' => 0,
		'HTTP::Message' => 0,
		'LWP::UserAgent' => 0,
		'URI' => 0
	},
	PM               => {
		'lib/App/FuguVM.pm' => '$(INST_LIB)/App/FuguVM.pm',
		'lib/App/FuguVM.pod' => '$(INST_LIB)/App/FuguVM.pod',
		'lib/App/FuguVM/CLI.pm' => '$(INST_LIB)/App/FuguVM/CLI.pm',
		'lib/App/FuguVM/CLI.pod' => '$(INST_LIB)/App/FuguVM/CLI.pod',
		'lib/App/FuguVM/Config.pm' => '$(INST_LIB)/App/FuguVM/Config.pm',
		'lib/App/FuguVM/Config.pod' => '$(INST_LIB)/App/FuguVM/Config.pod',
		'lib/App/FuguVM/Console.pm' => '$(INST_LIB)/App/FuguVM/Console.pm',
		'lib/App/FuguVM/Console.pod' => '$(INST_LIB)/App/FuguVM/Console.pod',
		'lib/App/FuguVM/Disk.pm' => '$(INST_LIB)/App/FuguVM/Disk.pm',
		'lib/App/FuguVM/Disk.pod' => '$(INST_LIB)/App/FuguVM/Disk.pod',
		'lib/App/FuguVM/DiskCache.pm' => '$(INST_LIB)/App/FuguVM/DiskCache.pm',
		'lib/App/FuguVM/DiskCache.pod' => '$(INST_LIB)/App/FuguVM/DiskCache.pod',
		'lib/App/FuguVM/Guest.pm' => '$(INST_LIB)/App/FuguVM/Guest.pm',
		'lib/App/FuguVM/Guest.pod' => '$(INST_LIB)/App/FuguVM/Guest.pod',
		'lib/App/FuguVM/Miniroot.pm' => '$(INST_LIB)/App/FuguVM/Miniroot.pm',
		'lib/App/FuguVM/Miniroot.pod' => '$(INST_LIB)/App/FuguVM/Miniroot.pod',
		'lib/App/FuguVM/Proxy.pm' => '$(INST_LIB)/App/FuguVM/Proxy.pm',
		'lib/App/FuguVM/Proxy.pod' => '$(INST_LIB)/App/FuguVM/Proxy.pod',
		'lib/App/FuguVM/QMP.pm' => '$(INST_LIB)/App/FuguVM/QMP.pm',
		'lib/App/FuguVM/QMP.pod' => '$(INST_LIB)/App/FuguVM/QMP.pod',
		'lib/App/FuguVM/State.pm' => '$(INST_LIB)/App/FuguVM/State.pm',
		'lib/App/FuguVM/State.pod' => '$(INST_LIB)/App/FuguVM/State.pod',
		'scripts/ftp' => '$(INST_LIB)/auto/share/dist/App-FuguVM/scripts/ftp',
		'share/fuguvm/cache-generation' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/cache-generation',
		'share/fuguvm/expect/command.exp' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/expect/command.exp',
		'share/fuguvm/expect/install.exp' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/expect/install.exp',
		'share/fuguvm/expect/login.exp' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/expect/login.exp',
		'share/fuguvm/fuguvm.conf.sample' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/fuguvm.conf.sample',
		'share/fuguvm/vms/default.conf.sample' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/vms/default.conf.sample',
		'share/fuguvm/vms/minimal.conf.sample' => '$(INST_LIB)/auto/share/dist/App-FuguVM/fuguvm/vms/minimal.conf.sample'
	},
	test             => { TESTS => 't/fuguvm/*.t' },
);
