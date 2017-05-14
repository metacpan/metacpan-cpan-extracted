die(q{Kept as a reminder that too much doesn't work this way.});
package Carrot::Diversity::English::Builtins
# /type class
# /capability "Define specific aliases for multi-purpose builtins"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Long_Builtins./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;

	my $aliases = {
		'reference_type'   => 'ref',

		'list_grep'        => 'grep',
		'list_join'        => 'join',
		'list_map'         => 'map',
		'list_reverse'     => 'reverse',
#		'list_sort'        => 'sort', # not a subroutine

#		'hash_keys'        => 'keys', # refused
#		'hash_values'      => 'values', # refused
		'hash_delete'      => 'delete',
		'hash_exists'      => 'exists',
#		'hash_each'        => 'each', # refused

#		'array_pop'        => 'pop', # refused
#		'array_push'       => 'push', # refused
#		'array_shift'      => 'shift', # refused
#		'array_unshift'    => 'unshift', # refused
#		'array_splice'     => 'splice', # refused

#		're_match'         => 'm', # operator
#		're_substitution'  => 's', # operator

		'file_chdir'       => 'chdir',
		'file_chmod'       => 'chmod',
		'file_chown'       => 'chown',
		'file_chroot'      => 'chroot',
		'file_fcntl'       => 'fcntl',
		'file_glob'        => 'glob',
		'file_ioctl'       => 'ioctl',
		'file_link'        => 'link',
		'file_lstat'       => 'lstat',
		'file_mkdir'       => 'mkdir',
		'file_open'        => 'open',
		'file_opendir'     => 'opendir',
		'file_readlink'    => 'readlink',
		'file_rename'      => 'rename',
		'file_rmdir'       => 'rmdir',
		'file_stat'        => 'stat',
		'file_symlink'     => 'symlink',
		'file_sysopen'     => 'sysopen',
		'file_umask'       => 'umask',
		'file_unlink'      => 'unlink',
		'file_utime'       => 'utime',

	};
	my $aliases_re =
		'(?:[^\w>:\h]|[^\w>:]\h+)('
		. join('|', keys($aliases))
		. ')\(';

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub managed_modularity
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
#	definitions
# //returns
{
	my ($this, $meta_monad, $definitions) = @ARGUMENTS;

	my $source_code = $meta_monad->source_code;
	my $long_builtins = $source_code->unique_matches($aliases_re);

	return unless (@$long_builtins);

#	my $pkg_name = $meta_monad->package_name->value;
	my $code = join("\n", map(
		"\*$_ = \\&CORE::$aliases->{$_};",
		@$long_builtins));
	$definitions->add_code($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.67
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
