#!perl
use strict;
use warnings;

use inc::MyBuilder;
use Module::Build::Compat;
use File::Path qw(rmtree);
use IO::Handle;

use LWP::Simple;

STDOUT->autoflush(1);

my $name    = 'rrdtool';
my $rrdtool = "http://oss.oetiker.ch/rrdtool/pub/${name}.tar.gz";

if (!grep { $_ eq '--no-upgrade' } @ARGV) {
    print "# donwloading $rrdtool\n";
    print "# => ", scalar mirror($rrdtool, "$name.tar.gz"), "\n";
}

print "# unpacking $name.tar.gz\n";
system("tar", "xzf",  "$name.tar.gz");
rmtree($name);

my $version = do {
    my @dirs = <rrdtool-*>;
    @dirs == 1 or die "XXX: too many rrdtool-*/: @dirs";
    ( $dirs[0] =~ m/ (\d+ (?: \. \d+)+ ) /xms )[0];
};
print "# rrdtool version $version\n";
symlink "$name-$version" => $name;

if (-e (my $patch = "patch/v$version.patch")) {
    print "# applying $patch\n";
    system("cd '$name' && patch -p1 < '../$patch'");
}

print "# witing Makefile\n";
my $builder = inc::MyBuilder->new(
    module_name => 'Alien::RRDtool',
    dist_author => 'Fuji, Goro (gfx) <gfuji(at)cpan.org>',
    license     => 'perl',

    requires    => {
        perl => 5.008_001,

        'File::ShareDir' => 0,
    },

    configure_requires => {
        'File::chdir'   => 0,
        'File::Which'   => 0,
        'LWP::Simple'   => 0,
        'Module::Build' => 0,
    },
    build_requires => {
        'File::ShareDir' => 0,
    },
    test_requires => {
        'Test::More'     => 0.88,
        'Test::Requires' => 0.06,
    },

    share_dir => 'alien',

    needs_compiler => 1,

    dist_meta => 1, # to make `cpanm .` happy

    no_index => {
        directory =>  [
            'inc',
            'author',
        ],
    },

    add_to_cleanup => [
        $name,
        "$name-$version",
        'Makefile',
        'blib',
    ],
);

$builder->notes( rrdtool    => $rrdtool );
$builder->notes( name       => $name    );
$builder->notes( version    => $version );
$builder->notes( installdir => 'alien' );

$builder->create_build_script();

# write Makefile for an easy interface to the build script
Module::Build::Compat->write_makefile(build_class => ref $builder);

