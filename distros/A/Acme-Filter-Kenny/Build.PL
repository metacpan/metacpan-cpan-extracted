use Module::Build;

eval q{
	use Module::Signature;
};
my $sign = !$@;

Module::Build->new (
	module_name => "Acme::Filter::Kenny",
	license => "gpl",
	requires => {
		perl => '5.6.0',
		Filter::Util::Call => 0,
	},
	scripts => [ 'bin/kennyfy' ],
	dist_author => 'Gergely Nagy <algernon@bonehunter.rulez.org>',
	create_readme => 1,
	dist_version_from => "lib/Acme/Filter/Kenny.pm",
	create_makefile_pl => 'passthrough',
	recursive_test_files => 1,
	sign => $sign,
)->create_build_script;

# arch-tag: 42d4eef9-762b-4ad3-bdeb-f783a0deb40b
