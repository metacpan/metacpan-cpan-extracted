# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@dickolsson.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

# App::FuguVM::Arch - the architecture table of the supported guests.
#
# The names are the OpenBSD architecture names, amd64 and arm64,
# because the guest is OpenBSD. The QEMU spellings stay inside the
# table. The module uses core Perl only, and it loads no other module
# of the distribution.

package App::FuguVM::Arch;
our $VERSION = '0.2.0';

my %TABLE = (
	arm64 => {
		qemu_binary    => 'qemu-system-aarch64',
		machine        => 'virt,highmem=off',
		tcg_cpu        => 'cortex-a57',
		host_machines  => [ 'aarch64', 'arm64' ],
		firmware_paths => [
			'/opt/homebrew/share/qemu/edk2-aarch64-code.fd',
			'/usr/local/share/qemu/edk2-aarch64-code.fd',
			'/usr/share/qemu-efi-aarch64/QEMU_EFI.fd',
			'/usr/share/AAVMF/AAVMF_CODE.fd',
			'/usr/share/qemu/edk2-aarch64-code.fd',
		],
		firmware_glob =>
'/opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd',
	},
	amd64 => {
		qemu_binary    => 'qemu-system-x86_64',
		machine        => 'q35',
		tcg_cpu        => 'qemu64',
		host_machines  => [ 'x86_64', 'amd64' ],
		firmware_paths => [
			'/opt/homebrew/share/qemu/edk2-x86_64-code.fd',
			'/usr/local/share/qemu/edk2-x86_64-code.fd',
			'/usr/share/qemu/edk2-x86_64-code.fd',
			'/usr/share/OVMF/OVMF_CODE_4M.fd',
			'/usr/share/OVMF/OVMF_CODE.fd',
			'/usr/share/edk2/ovmf/OVMF_CODE.fd',
		],
		firmware_glob =>
'/opt/homebrew/Cellar/qemu/*/share/qemu/edk2-x86_64-code.fd',

		# The x86 code files are split flash images, and -bios
		# cannot load them. Each code file boots through two
		# pflash devices, with the variable-store template that
		# sits beside it in the same directory.
		firmware_vars => {
			'edk2-x86_64-code.fd' => 'edk2-i386-vars.fd',
			'OVMF_CODE_4M.fd'     => 'OVMF_VARS_4M.fd',
			'OVMF_CODE.fd'        => 'OVMF_VARS.fd',
		},
	},
);

# $class->new($name):
#	Return the architecture object for amd64 or arm64. Return
#	undef for every other name. The comparison is case sensitive:
#	AMD64 is an unknown value.
sub new ( $class, $name )
{
	return if !defined $name || !exists $TABLE{$name};

	return bless { name => $name, %{ $TABLE{$name} } }, $class;
}

# $class->names:
#	Return the supported names, sorted. A diagnostic names them,
#	so the message and the table cannot disagree.
sub names ($)
{
	my @names = sort keys %TABLE;

	return @names;
}

sub name ($self)
{
	return $self->{name};
}

sub qemu_binary ($self)
{
	return $self->{qemu_binary};
}

sub machine ($self)
{
	return $self->{machine};
}

sub tcg_cpu ($self)
{
	return $self->{tcg_cpu};
}

# $arch->firmware_paths:
#	Return the ordered list of absolute firmware paths.
sub firmware_paths ($self)
{
	return @{ $self->{firmware_paths} };
}

# $arch->firmware_glob:
#	Return one glob pattern for the versioned Homebrew paths.
sub firmware_glob ($self)
{
	return $self->{firmware_glob};
}

# $arch->firmware_vars_path($code_path):
#	Return the variable-store template beside a firmware code
#	file. Return undef when the architecture boots the code file
#	with -bios alone.
sub firmware_vars_path ( $self, $code_path )
{
	my $vars = $self->{firmware_vars};
	return if !defined $vars;

	my $slash = rindex( $code_path, '/' );
	my $name  = substr( $code_path, $slash + 1 );
	return if !exists $vars->{$name};

	return substr( $code_path, 0, $slash + 1 ) . $vars->{$name};
}

# $arch->accelerator($os, $host_machine, $kvm):
#	Return kvm, hvf or tcg for one host. QEMU cannot accelerate a
#	guest whose instruction set is not the host's, so a host
#	machine of an other architecture always gives tcg. The caller
#	gives $^O, the uname machine, and whether /dev/kvm is
#	writable. The method calls no syscall, so a test proves every
#	branch on any host.
sub accelerator ( $self, $os, $host_machine, $kvm )
{
	return 'tcg' if !$self->_host_matches($host_machine);
	return 'kvm' if $os eq 'linux' && $kvm;
	return 'hvf' if $os eq 'darwin';

	return 'tcg';
}

# $arch->_host_matches($host_machine):
#	Report if the host machine name belongs to this architecture.
#	A host machine has more than one name: Linux says aarch64
#	where Darwin and OpenBSD say arm64.
sub _host_matches ( $self, $host_machine )
{
	return 0 if !defined $host_machine;

	return ( grep { $_ eq $host_machine } @{ $self->{host_machines} } )
	    ? 1
	    : 0;
}

1;
