package main;

use utf8;
use warnings;
use strict;
use Module::Build ();
use Config ();
use File::Which qw/ which /;
use IPC::Run qw/ run timeout /;

my $has_cpp_compiler = scalar(which("c++"));
my $arch;

if (my $which =(which("uname"))[0]) {
    my ($out, $err);
    my $is_success = run(
        [$which, '-m'],
        \undef, \$out, \$err,
        timeout(1)
    );
    chomp($out);
    $arch = $out if $out;
}

my %not_sse_archs = map { $_ => 1 } qw/ armv7l aarch64 /;

my %Config = %Config::Config;
my @cc_flags = split(/ /, $Config{'ccflags'});

push(@cc_flags, "-O3", "-msse2", "-msse4.2") if $arch && !$not_sse_archs{$arch};
push(@cc_flags, "-DCPP=1", "-std=c++17") if $has_cpp_compiler;
push(@cc_flags, "-std=c17") if !$has_cpp_compiler;

my $build = Module::Build->new(
    module_name         => 'Crypt::xxHash',
    license             => 'bsd',
    create_readme       => 1,
    configure_requires  => {
        'Module::Build' => 0.19, # xs
    },
    config => {
        $has_cpp_compiler ? (cc => 'c++', ld => 'c++') : (),
    },
    build_requires       => {
        'File::Which'        => 1.21,
        'IPC::Run'           => '20200505.0',
        'ExtUtils::CBuilder' => 0.280225,
        'Test::More'         => 1.302171,
        'Math::Int64'        => '0.54' # 32bit perl without int64 :\
    },
    requires       => {
	},
    needs_compiler => 1,
    extra_compiler_flags => [@cc_flags],
    extra_linker_flags   => [@cc_flags],
    include_dirs   => ['.', 'src', 'ext/xxHash'], # ext/xxHash/tests/collisions/allcodecs
    c_source       => ['.', 'src'],
    xs_files       => {
        './xs/xxHash.xs' => './lib/Crypt/xxHash.xs' 
    },
    meta_merge     => {
        'resources' => {
            'bugtracker' => 'https://github.com/KalessinD/perl_crypt_xxhash/issues',
            'repository' => 'https://github.com/KalessinD/perl_crypt_xxhash',
        },
    }
);

$build->create_build_script;

1;
__END__
