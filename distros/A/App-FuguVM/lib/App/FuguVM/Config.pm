# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2024 Dick Olsson <hi@senzilla.io>
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

package App::FuguVM::Config;
our $VERSION = '0.2.0';

use Fugu::Config;
use Fugu::File;
use Fugu::Log;
use App::FuguVM::Arch;

# App::FuguVM::Config - the VM defaults over Fugu::Config.
#
# The grammar, the tilde expansion and the yes/no spellings come from
# Fugu::Config. This file holds only what is true of FuguVM: the
# defaults for a machine, the merge of the global and the project
# file, and the switch that turns the installed-image cache off.

use constant {
	DEFAULT_ARCH         => 'arm64',
	DEFAULT_MEMORY       => 2048,
	DEFAULT_DISK_SIZE    => '8G',
	DEFAULT_SSH_PORT     => 2222,
	DEFAULT_CONSOLE_PORT => 4444,
	DEFAULT_BIND_ADDRESS => '127.0.0.1',
	DEFAULT_VERSION      => '7.8',

	# The word that makes a port directive take a free host port.
	# This constant is the one home of the word.
	AUTO_PORT => 'auto',

	# The size of each automatic port range. A range starts at the
	# default port of its directive, so the bounds need no constant
	# of their own.
	AUTO_PORT_COUNT => 100,

	DATA_DIR       => '.fuguvm',
	GLOBAL_CONFIG  => '.fuguvmrc',
	PROJECT_CONFIG => '.fuguvmrc',
};

sub new ( $class, $project_root )
{
	my $self = bless {
		project_root => $project_root,
		data_dir     => "$project_root/" . DATA_DIR,
	}, $class;

	$self->_load_configs;

	return $self;
}

# $class->find_project_root:
#	Walk up to the directory that holds .fuguvmrc.
sub find_project_root ($class)
{
	return Fugu::Config->find_project_root(PROJECT_CONFIG);
}

sub _load_configs ($self)
{
	my $home = $ENV{HOME} // '/root';

	$self->{global} = $self->_parse( "$home/" . GLOBAL_CONFIG );
	$self->{project} =
	    $self->_parse( "$self->{project_root}/" . PROJECT_CONFIG );

	return $self;
}

# $self->_parse($path):
#	Parse one configuration file. An absent file is normal: a
#	checkout has no global file, and a global-only setup has no
#	project file. A file that exists but does not parse is an error
#	that names the line, and the caller gets empty settings rather
#	than half of them.
sub _parse ( $self, $path )
{
	return Fugu::Config->new( file => $path ) unless -f $path;

	my $config = Fugu::Config->new( file => $path );
	unless ( $config->load ) {
		Fugu::Log->default->error( '%s', $config->error );
	}

	return $config;
}

# $self->_setting($key):
#	Return a top-level setting. The project file wins over the
#	global one.
sub _setting ( $self, $key )
{
	return $self->{project}->get($key) // $self->{global}->get($key);
}

# $self->load_vm($name):
#	Return the merged configuration of one VM. Return undef when
#	no file declares it, or when a value does not validate. In the
#	second case, error() reports the reason.
sub load_vm ( $self, $name )
{
	delete $self->{error};

	# First check for a VM block in the project config. Then check
	# the global config.
	my $block = $self->{project}->block( 'vm', $name )
	    // $self->{global}->block( 'vm', $name );
	my $vm = $block ? { %{ $block->{settings} } } : undef;

	# Then look for a file of its own under vms/. This is not a
	# fallback: 'fuguvm init' writes vms/default.conf, and
	# fuguvm(1) documents the directory. A vm block in the
	# project or global config wins over it.
	if ( !defined $vm ) {
		my $vm_file = "$self->{data_dir}/vms/$name.conf";
		if ( -f $vm_file ) {
			my $file = $self->_parse($vm_file);
			$vm = { map { $_ => $file->get($_) }
				    $file->setting_names };
		}
	}

	return if !defined $vm;

	# Apply the defaults
	$vm->{name}         //= $name;
	$vm->{arch}         //= DEFAULT_ARCH;
	$vm->{version}      //= DEFAULT_VERSION;
	$vm->{memory}       //= DEFAULT_MEMORY;
	$vm->{disk_size}    //= DEFAULT_DISK_SIZE;
	$vm->{ssh_port}     //= DEFAULT_SSH_PORT;
	$vm->{console_port} //= DEFAULT_CONSOLE_PORT;

	# This loader is the boundary of the arch directive. No module
	# downstream repeats the check.
	if ( !App::FuguVM::Arch->new( $vm->{arch} ) ) {
		$self->{error} =
		    sprintf( "VM '%s': unknown arch '%s' (accepted values: %s)",
			$name, $vm->{arch},
			join( ', ', App::FuguVM::Arch->names ) );
		return;
	}

	# This loader is also the boundary of the two port directives
	# and of the bind address. No module downstream repeats these
	# checks.
	for my $directive (qw(ssh_port console_port)) {
		next if _valid_port( $vm->{$directive} );
		$self->{error} = sprintf(
			"VM '%s': %s '%s' is not a port from 1 to 65535"
			    . " and not '%s'",
			$name, $directive, $vm->{$directive}, AUTO_PORT );
		return;
	}

	# The bind address follows the same fallback chain as
	# ssh_pubkey and cache_dir below.
	$vm->{bind_address} //= $self->bind_address;
	if ( !_valid_ipv4( $vm->{bind_address} ) ) {
		$self->{error} = sprintf(
			"VM '%s': bind_address '%s' is not an IPv4 address"
			    . " in dotted-decimal form",
			$name, $vm->{bind_address} );
		return;
	}

	# The version gate of the guest reads the directive from the
	# per-VM config. The directive lives in the enclosing files
	# only: the pinned binary is a fact of the host, not of one
	# guest. A pin inside a VM declaration would silently not
	# apply, so it is an error.
	if ( exists $vm->{qemu_version} ) {
		$self->{error} = sprintf(
			"VM '%s': qemu_version lives in the project or the"
			    . " global .fuguvmrc, not in a VM declaration",
			$name
		);
		return;
	}
	$vm->{qemu_version} = $self->qemu_version;
	if ( defined $vm->{qemu_version}
		&& $vm->{qemu_version} !~ /^[0-9]+(?:\.[0-9]+)*$/ )
	{
		$self->{error} =
		    sprintf( "VM '%s': qemu_version '%s' is not a version"
			    . " of dot-separated decimal numbers",
			$name, $vm->{qemu_version} );
		return;
	}

	# Include ssh_pubkey from the global or project config
	$vm->{ssh_pubkey} //= $self->ssh_pubkey;

	# Include the fixed ports of every VM declaration. The port
	# probe of the guest skips them, so an automatic port cannot
	# take the number of a declared sibling, stopped or not.
	$vm->{declared_ports} = $self->declared_ports;

	# Include the resolved cache_dir. Then the VM operations, the
	# proxy cache and the installed-image cache, all use the
	# configured location. Without it, 'fuguvm up' would write its
	# images under $HOME while the cache subcommands worked on a
	# different tree.
	$vm->{cache_dir} //= $self->cache_dir;

	# Normalize the installed-image cache switch, whether it came from
	# the VM block or the enclosing configuration
	$vm->{image_cache} =
	    defined $vm->{image_cache}
	    ? $self->_bool( $vm->{image_cache}, 1 )
	    : $self->image_cache;

	# Normalize the verification switch the same way
	$vm->{verify} =
	    defined $vm->{verify}
	    ? $self->_bool( $vm->{verify}, 1 )
	    : $self->verify;

	# Resolve the signify_dir directive, from the VM block or the
	# enclosing configuration. This loader is the boundary of the
	# directive: an absent or unreadable directory fails here, not
	# deep inside an install.
	$vm->{signify_dir} =
	    defined $vm->{signify_dir}
	    ? $self->_resolve_path( $vm->{signify_dir} )
	    : $self->signify_dir;
	if ( defined $vm->{signify_dir} && !-d $vm->{signify_dir} ) {
		$self->{error} =
		    sprintf( "VM '%s': signify_dir is not a directory: %s",
			$name, $vm->{signify_dir} );
		return;
	}

	# Include the distfile cap of the project. The distfile tree is
	# one tree under cache_dir, and each guest of a project shares
	# it, so the cap is a project fact and not a per-guest
	# directive. A cap in a VM block would silently not apply, so
	# the operator hears about it, like an unrecognized switch.
	Fugu::Log->default->warning(
		"VM '%s': distfile_cache lives in the project or the"
		    . ' global .fuguvmrc, not in a VM declaration',
		$name
	) if defined $vm->{distfile_cache};
	$vm->{distfile_cache} = $self->distfile_cache;

	return if !$self->_validate_origin( $name, $vm );

	return $vm;
}

# $self->_validate_origin($name, $vm):
#	Validate the three image-lifecycle directives, and derive
#	install_mode: expect, autoinstall or import. This loader is the
#	boundary of each directive, so no module downstream repeats a
#	check. Return 1 when the configuration loads, and 0 with the
#	reason in error() otherwise.
sub _validate_origin ( $self, $name, $vm )
{
	if ( defined $vm->{autoinstall} && defined $vm->{base_disk} ) {
		$self->{error} = sprintf(
			"VM '%s': autoinstall and base_disk contradict each"
			    . " other; one guest has one origin",
			$name
		);
		return 0;
	}

	# Each path directive resolves against the project root, and the
	# file must be readable now. A path that fails at 'up' time, deep
	# inside an install, is a path that failed too late.
	for my $directive (qw(autoinstall base_disk root_password_file)) {
		next if !defined $vm->{$directive};
		my $path = $self->_resolve_path( $vm->{$directive} );
		if ( !-f $path || !-r $path ) {
			$self->{error} =
			    sprintf( "VM '%s': %s file is not readable: %s",
				$name, $directive, $path );
			return 0;
		}
		$vm->{$directive} = $path;
	}

	$vm->{install_mode} =
	      defined $vm->{autoinstall} ? 'autoinstall'
	    : defined $vm->{base_disk}   ? 'import'
	    :                              'expect';

	if ( $vm->{install_mode} eq 'import' && !$vm->{image_cache} ) {
		$self->{error} = sprintf(
			"VM '%s': base_disk needs the image cache;"
			    . " remove 'image_cache no'",
			$name
		);
		return 0;
	}

	# Outside the expect mode the tool does not know the root
	# password of the image, and it cannot install a key without
	# one.
	if (       $vm->{install_mode} ne 'expect'
		&& defined $vm->{ssh_pubkey}
		&& $vm->{ssh_pubkey} ne ''
		&& !defined $vm->{root_password_file} )
	{
		$self->{error} = sprintf(
			"VM '%s': ssh_pubkey needs root_password_file in the"
			    . " %s mode; add the directive, or unset"
			    . " ssh_pubkey and bake the key into the image",
			$name, $vm->{install_mode} );
		return 0;
	}

	return 1;
}

# $self->_resolve_path($value):
#	Expand a leading tilde, then make a relative path absolute
#	against the project root. The result is always absolute: the
#	project root itself can be relative, from a --project option,
#	and a daemonized child can read the path from an other working
#	directory.
sub _resolve_path ( $self, $value )
{
	my $path = Fugu::File->expand_tilde($value);
	$path = "$self->{project_root}/$path" if $path !~ m{^/};

	require File::Spec;
	return File::Spec->rel2abs($path);
}

# $self->error:
#	Return the reason of the last failed load_vm, or undef.
sub error ($self)
{
	return $self->{error};
}

# _valid_port($value):
#	Report if a port directive holds the word AUTO_PORT or a
#	decimal number from 1 to 65535.
sub _valid_port ($value)
{
	return 0 if !defined $value;
	return 1 if $value eq AUTO_PORT;

	# A leading zero is not decimal, and the string-keyed port sets
	# of the probe would not match it.
	return 0 if $value !~ /^[1-9][0-9]*$/;

	return $value <= 65535 ? 1 : 0;
}

# _valid_ipv4($value):
#	Report if a value is one IPv4 address in dotted-decimal form.
#	A host name is not: a name resolves once for QEMU and once for
#	the tool, and the two answers can differ.
sub _valid_ipv4 ($value)
{
	return 0 if !defined $value;

	my @parts = split /\./, $value, -1;
	return 0 if @parts != 4;

	for my $part (@parts) {

		# A leading zero reads as octal in inet_aton, so such a
		# component is not decimal.
		return 0 if $part !~ /^(?:0|[1-9][0-9]{0,2})$/;
		return 0 if $part > 255;
	}

	return 1;
}

sub cache_dir ($self)
{
	my $dir = $self->_setting('cache_dir') // '~/.cache/fuguvm';

	return Fugu::File->expand_tilde($dir);
}

# $self->image_cache:
#	Return whether 'fuguvm up' may use the installed-image cache.
#	The project configuration wins over the global one. The default
#	is on.
sub image_cache ($self)
{
	my $value = $self->_setting('image_cache');
	return 1 if !defined $value;

	return $self->_bool( $value, 1 );
}

# $self->verify:
#	Return whether the tool verifies each mirror download. The
#	project configuration wins over the global one. The default is
#	on.
sub verify ($self)
{
	my $value = $self->_setting('verify');
	return 1 if !defined $value;

	return $self->_bool( $value, 1 );
}

# $self->signify_dir:
#	Return the resolved directory of the signify public keys, or
#	undef without the directive. A leading tilde expands, and a
#	relative path resolves against the project root.
sub signify_dir ($self)
{
	my $dir = $self->_setting('signify_dir');
	return if !defined $dir;

	return $self->_resolve_path($dir);
}

# $self->distfile_cache:
#	Return the distfile cap in bytes. The default is 0, and 0
#	turns the distfile cache off. An unparsable value gives one
#	warning and the value 0: an unrecognized spelling must not
#	silently mean its opposite, and off is the closed state for a
#	cache.
sub distfile_cache ($self)
{
	my $value = $self->_setting('distfile_cache');
	return 0 if !defined $value;

	my $bytes = _parse_size($value);
	if ( !defined $bytes ) {
		Fugu::Log->default->warning(
			"distfile_cache '%s' is not a size; the cache is off",
			$value );
		return 0;
	}

	return $bytes;
}

# _parse_size($value):
#	Return the byte count of a size, or undef. The value is a bare
#	number of bytes, or a number with a K, M or G suffix. The
#	suffix is 1024-based, and the letter case does not matter.
sub _parse_size ($value)
{
	my ( $number, $suffix ) = $value =~ /\A([0-9]+)([KkMmGg]?)\z/;
	return if !defined $number;

	my %scale = ( '' => 1, k => 1024, m => 1024**2, g => 1024**3 );

	return $number * $scale{ lc $suffix };
}

# $self->_bool($value, $default):
#	Read a switch, and report a value that is neither yes nor no.
#	An unrecognized spelling must not silently mean its opposite,
#	so the operator hears about it.
sub _bool ( $self, $value, $default )
{
	my $parser = $self->{project};
	my $result = $parser->parse_bool( $value, $default );

	Fugu::Log->default->warning( '%s', $parser->error )
	    if defined $parser->error;

	return $result;
}

sub state_dir ($self)
{
	my $dir = $self->{project}->get('state_dir')
	    // "$self->{data_dir}/state";

	# Make relative paths absolute to the project root
	if ( $dir !~ m{^/} ) {
		$dir = "$self->{project_root}/$dir";
	}

	return $dir;
}

sub default_vm ($self)
{
	return $self->_setting('default_vm') // 'default';
}

sub ssh_pubkey ($self)
{
	return $self->_setting('ssh_pubkey');
}

# $self->declared_ports:
#	Return the fixed ports of every VM declaration of the project,
#	as a hash reference keyed by port. A declaration that omits a
#	port directive holds the default port of that directive. The
#	set covers the vm blocks of both files and the files under
#	vms/.
sub declared_ports ($self)
{
	my @declarations =
	    map { $_->{settings} }
	    ( $self->{project}->blocks('vm'), $self->{global}->blocks('vm') );

	my $vms_dir = "$self->{data_dir}/vms";
	if ( opendir my $dh, $vms_dir ) {
		for my $file ( sort grep { /\.conf$/ } readdir $dh ) {
			my $parsed = $self->_parse("$vms_dir/$file");
			push @declarations,
			    { map { $_ => $parsed->get($_) }
				    $parsed->setting_names };
		}
		closedir $dh;
	}

	my %defaults = (
		ssh_port     => DEFAULT_SSH_PORT,
		console_port => DEFAULT_CONSOLE_PORT,
	);

	my %ports;
	for my $settings (@declarations) {
		for my $directive (qw(ssh_port console_port)) {
			my $value = $settings->{$directive}
			    // $defaults{$directive};
			$ports{$value} = 1 if $value =~ /^[0-9]+$/;
		}
	}

	return \%ports;
}

# $self->bind_address:
#	Return the host address of the forwarded ports. The project
#	file wins over the global one, and the default is loopback.
sub bind_address ($self)
{
	return $self->_setting('bind_address') // DEFAULT_BIND_ADDRESS;
}

# $self->qemu_version:
#	Return the pinned QEMU version, or undef. With no directive
#	the tool checks nothing.
sub qemu_version ($self)
{
	return $self->_setting('qemu_version');
}

1;
