use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Alien::Packages',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/Alien/Packages.pm',
    build_requires      => {
        'Test::More' => "0.90",
    },
    requires            => {
	'IPC::Open3'        => 0,
	'IPC::Cmd'          => 0,
	'Module::Pluggable' => '4.5',
    },
    recommends          => {
	'IPC::Run'    => 0,
	'Module::Pluggable' => '4.8',
        ( $^O eq 'MSWin32' ? ( 'Win32::Registry' => 0, ) : () ),
    },
    create_readme       => 1,
    meta_merge =>
	{ resources => { repository => "https://github.com/rehsack/Alien-Packages", }, },
    test_files => join( ' ' => 't/*.t xt/*.t' ),
    add_to_cleanup      => [ 'Alien-Packages-*' ],
);

$builder->create_build_script();
