use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;
use File::Spec;
use File::Path qw(make_path);
use File::Copy qw(copy);

# In-tree development helper: if bundled/ doesn't exist but we are inside libhisto repo,
# automatically sync C source tree into bundled/ before building.
my $repo_root = File::Spec->rel2abs(File::Spec->catdir(File::Spec->curdir, '..', '..', '..'));
my $repo_cmake = File::Spec->catfile($repo_root, 'CMakeLists.txt');
my $bundled_dir = File::Spec->catdir(File::Spec->curdir, 'bundled');


sub copy_tree {
    my ($src, $dst) = @_;
    make_path($dst) unless -d $dst;
    opendir my $dh, $src or die "Cannot open $src: $!";
    while (my $entry = readdir $dh) {
        next if $entry eq '.' || $entry eq '..';
        my $src_path = File::Spec->catfile($src, $entry);
        my $dst_path = File::Spec->catfile($dst, $entry);
        if (-d $src_path) {
            copy_tree($src_path, $dst_path);
        } else {
            copy($src_path, $dst_path) or die "Cannot copy $src_path -> $dst_path: $!";
        }
    }
    closedir $dh;
}

if (-f $repo_cmake) {
    print "In-tree build: syncing libhisto source tree to bundled/...\n";
    make_path($bundled_dir) unless -d $bundled_dir;
    for my $dir (qw(include src cmake tools)) {
        my $src_dir = File::Spec->catdir($repo_root, $dir);
        if (-d $src_dir) {
            copy_tree($src_dir, File::Spec->catdir($bundled_dir, $dir));
        }
    }
    for my $file (qw(CMakeLists.txt libhisto.pc.in libhistocli.pc.in Doxyfile.in LICENSE)) {
        my $src_file = File::Spec->catfile($repo_root, $file);
        if (-f $src_file) {
            copy($src_file, File::Spec->catfile($bundled_dir, $file));
        }
    }
    # Clean stale Alien::Build cache so it rebuilds with fresh headers
    File::Path::remove_tree('_alien', 'blib');
    require ExtUtils::Manifest;
    ExtUtils::Manifest::mkmanifest();
}


my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME          => 'Alien::libhisto',
    DISTNAME      => 'Alien-libhisto',
    VERSION_FROM  => 'lib/Alien/libhisto.pm',
    ABSTRACT_FROM => 'lib/Alien/libhisto.pm',
    AUTHOR        => 'Steffen Mueller <cpan@steffen-mueller.net>',
    LICENSE       => 'mit',

    MIN_PERL_VERSION => '5.008001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'                => '6.52',
        'Alien::Build'                       => '2.00',
        'Alien::Build::MM'                   => '2.00',
        'Alien::Build::Plugin::Build::CMake' => '0.01',
        'File::Spec'                         => '0',
        'File::Path'                         => '0',
    },
    BUILD_REQUIRES => {
        'Alien::Build'                       => '2.00',
        'Alien::Build::MM'                   => '2.00',
        'Alien::Build::Plugin::Build::CMake' => '0.01',
    },
    PREREQ_PM => {
        'Alien::Base'                        => '2.00',
    },
    TEST_REQUIRES => {
        'Test2::V0'                          => '0.000060',
        'Test::Alien'                        => '2.00',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    META_MERGE => {

        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tsee/libhisto.git',
                web  => 'https://github.com/tsee/libhisto',
            },
            bugtracker => {
                web => 'https://github.com/tsee/libhisto/issues',
            },
        },
    },
));

sub MY::postamble {
    my $out = $abmm->mm_postamble(@_);
    $out .= "\ndistdir : manifest\n\n";
    return $out;
}

