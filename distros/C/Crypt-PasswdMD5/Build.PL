use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'Crypt::PasswdMD5',
	license        => 'perl',
	dist_abstract  => 'Provide interoperable MD5-based crypt() functions',
	dist_author    => 'Luis E. Muñoz <luismunoz@cpan.org>',
	build_requires =>
	{
		'Test::More' => 0.94,
#		'Test::Pod'  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		'Module::Build' => 0,
	},
	requires =>
	{
		'Digest::MD5' => 2.53,
		'strict'      => 0,
		'warnings'    => 0,
	},
) -> create_build_script();
