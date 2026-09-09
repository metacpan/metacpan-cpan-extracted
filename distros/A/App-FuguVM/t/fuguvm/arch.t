#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('App::FuguVM::Arch');

# Construction: the two supported names, and nothing else
{
	for my $name (qw(amd64 arm64)) {
		my $arch = App::FuguVM::Arch->new($name);
		ok(defined $arch, "new answers for $name");
		is($arch->name, $name, "and name reports $name");
	}

	is(App::FuguVM::Arch->new('riscv64'), undef,
	    'an unknown name returns undef');
	is(App::FuguVM::Arch->new(''), undef,
	    'the empty string returns undef');
	is(App::FuguVM::Arch->new(undef), undef, 'undef returns undef');
	is(App::FuguVM::Arch->new('AMD64'), undef,
	    'the comparison is case sensitive: AMD64 is unknown');
}

# names: sorted, and in agreement with new
{
	is_deeply([App::FuguVM::Arch->names], ['amd64', 'arm64'],
	    'names returns amd64 and arm64, sorted');
}

# The table: binary, machine and TCG model of each architecture
{
	my $arm64 = App::FuguVM::Arch->new('arm64');
	is($arm64->qemu_binary, 'qemu-system-aarch64', 'arm64 QEMU binary');
	is($arm64->machine, 'virt,highmem=off', 'arm64 machine type');
	is($arm64->tcg_cpu, 'cortex-a57', 'arm64 TCG CPU model');

	my $amd64 = App::FuguVM::Arch->new('amd64');
	is($amd64->qemu_binary, 'qemu-system-x86_64', 'amd64 QEMU binary');
	is($amd64->machine, 'q35', 'amd64 machine type');
	is($amd64->tcg_cpu, 'qemu64', 'amd64 TCG CPU model');
}

# The firmware lists: non-empty, and no list names the other
# architecture
{
	my @arm64 = App::FuguVM::Arch->new('arm64')->firmware_paths;
	my @amd64 = App::FuguVM::Arch->new('amd64')->firmware_paths;

	ok(@arm64, 'the arm64 firmware list is not empty');
	ok(@amd64, 'the amd64 firmware list is not empty');

	is(scalar(grep { /x86_64/ } @arm64), 0,
	    'no arm64 firmware path names x86_64');
	is(scalar(grep { /aarch64/ } @amd64), 0,
	    'no amd64 firmware path names aarch64');

	like(App::FuguVM::Arch->new('arm64')->firmware_glob, qr/aarch64/,
	    'the arm64 glob names aarch64');
	like(App::FuguVM::Arch->new('amd64')->firmware_glob, qr/x86_64/,
	    'the amd64 glob names x86_64');
}

# The variable-store pairing: every amd64 code file carries a template
# in the same directory, and arm64 boots with -bios alone
{
	my $arm64 = App::FuguVM::Arch->new('arm64');
	my $amd64 = App::FuguVM::Arch->new('amd64');

	for my $code ($amd64->firmware_paths) {
		my $vars = $amd64->firmware_vars_path($code);
		ok(defined $vars, "$code has a variable-store template");
		is(substr($vars, 0, rindex($vars, '/')),
		    substr($code, 0, rindex($code, '/')),
		    'and the template sits in the same directory');
	}

	is($amd64->firmware_vars_path('/usr/share/OVMF/OVMF_CODE_4M.fd'),
	    '/usr/share/OVMF/OVMF_VARS_4M.fd',
	    'the 4M code file pairs with the 4M template');
	is($amd64->firmware_vars_path(
	    '/opt/homebrew/Cellar/qemu/10.0.0/share/qemu/edk2-x86_64-code.fd'),
	    '/opt/homebrew/Cellar/qemu/10.0.0/share/qemu/edk2-i386-vars.fd',
	    'a glob result pairs with the edk2 template');

	for my $code ($arm64->firmware_paths) {
		is($arm64->firmware_vars_path($code), undef,
		    "$code boots with -bios alone");
	}
}

# The accelerator rule. Each architecture carries a list of host
# machine names, and the rule compares the host machine with the
# guest.
{
	my %hosts = (
	    arm64 => ['aarch64', 'arm64'],
	    amd64 => ['x86_64', 'amd64'],
	);

	for my $name (sort keys %hosts) {
		my $arch = App::FuguVM::Arch->new($name);
		my $other = App::FuguVM::Arch->new(
		    $name eq 'amd64' ? 'arm64' : 'amd64');

		for my $machine (@{ $hosts{$name} }) {
			is($arch->accelerator('linux', $machine, 1), 'kvm',
			    "$name on Linux host $machine with /dev/kvm is kvm");
			is($other->accelerator('linux', $machine, 1), 'tcg',
			    "the other guest on host $machine is tcg");
			is($arch->accelerator('linux', $machine, 0), 'tcg',
			    "$name on Linux host $machine without /dev/kvm is tcg");
		}
	}

	my $arm64 = App::FuguVM::Arch->new('arm64');
	my $amd64 = App::FuguVM::Arch->new('amd64');

	is($arm64->accelerator('darwin', 'arm64', 0), 'hvf',
	    'arm64 on an arm64 Mac is hvf');
	is($amd64->accelerator('darwin', 'x86_64', 0), 'hvf',
	    'amd64 on an Intel Mac is hvf');
	is($arm64->accelerator('darwin', 'x86_64', 0), 'tcg',
	    'arm64 on an Intel Mac is tcg');
	is($amd64->accelerator('darwin', 'arm64', 0), 'tcg',
	    'amd64 on an arm64 Mac is tcg');

	# QEMU has no accelerator on OpenBSD
	is($arm64->accelerator('openbsd', 'arm64', 0), 'tcg',
	    'an OpenBSD host always emulates');
	is($amd64->accelerator('openbsd', 'amd64', 0), 'tcg',
	    'also for amd64');
}

done_testing();
