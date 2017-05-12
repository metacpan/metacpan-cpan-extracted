use Module::Build;

die "Clarion.pm works only on little-endian architecture!\n"
    unless 0x04030201==unpack('L', pack('C4', 1..4));

Module::Build->new
(
    module_name	=> 'Clarion',
    license	=> 'perl',
    requires	=> {
	perl	=> 5.006,
	FileHandle	=> 0,
    },
    build_requires	=> {
	Test::More	=> 0,
    },
    create_makefile_pl => 'small',
)->create_build_script;
