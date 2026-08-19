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
our $VERSION = '0.1.1';

use Fugu::Config;
use Fugu::File;
use Fugu::Log;

# App::FuguVM::Config - the VM defaults over Fugu::Config.
#
# The grammar, the tilde expansion and the yes/no spellings come from
# Fugu::Config. This file holds only what is true of FuguVM: the
# defaults for a machine, the merge of the global and the project
# file, and the switch that turns the installed-image cache off.

use constant {
	DEFAULT_MEMORY       => 2048,
	DEFAULT_DISK_SIZE    => '8G',
	DEFAULT_SSH_PORT     => 2222,
	DEFAULT_CONSOLE_PORT => 4444,
	DEFAULT_VERSION      => '7.8',
	DATA_DIR             => '.fuguvm',
	GLOBAL_CONFIG        => '.fuguvmrc',
	PROJECT_CONFIG       => '.fuguvmrc',
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
#	Return the merged configuration of one VM, or undef when no
#	file declares it.
sub load_vm ( $self, $name )
{
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
	$vm->{version}      //= DEFAULT_VERSION;
	$vm->{memory}       //= DEFAULT_MEMORY;
	$vm->{disk_size}    //= DEFAULT_DISK_SIZE;
	$vm->{ssh_port}     //= DEFAULT_SSH_PORT;
	$vm->{console_port} //= DEFAULT_CONSOLE_PORT;

	# Include ssh_pubkey from the global or project config
	$vm->{ssh_pubkey} //= $self->ssh_pubkey;

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

	return $vm;
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

1;
