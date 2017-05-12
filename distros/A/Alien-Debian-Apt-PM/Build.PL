use strict;
use warnings;

use Module::Build;
use File::Spec;

unless (eval { symlink("",""); 1 }) {
    print STDERR "This OS does not support symlinks.\n";
    exit 0;
}

my $create_symlinks = Module::Build->subclass(code => <<'EOF');
    sub ACTION_install {
        my $builder = shift;
        
        $builder->SUPER::ACTION_install(@_);
        
        my $script_dest = File::Spec->catdir(
            $builder->{'properties'}->{'destdir'},
            $builder->install_destination('script'),
        );
        
        foreach my $script_name (qw{apt-pm apt-cpan apt-pm-web dh-make-pm cpan-patches dpkg-scanpmpackages}) {
            my $alias = File::Spec->catfile($script_dest, $script_name);
            unless (-l $alias) {
                print "Symlinking $alias\n";
                unlink($alias) if -e $alias;
                symlink(
                    File::Spec->catfile($script_dest, 'alien-debian-apt-pm'),
                    File::Spec->catfile($alias)
                ) or die $!;
            }
        }
    }
EOF

my $builder = $create_symlinks->new(
    module_name         => 'Alien::Debian::Apt::PM',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Alien/Debian/Apt/PM.pm',
    configure_requires => {
        'Module::Build' => 0.36,
    },
    requires => {
    },
    build_requires => {
    },
    script_files => [
        'script/alien-debian-apt-pm',
    ],
    add_to_cleanup      => [ 'Alien-Debian-Apt-PM-*' ],
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/jozef/Alien-Debian-Apt-PM/',
            bugtracker => 'http://github.com/jozef/Alien-Debian-Apt-PM/issues',
        },
        keywords => [ qw/ alien / ],
    },
);
$builder->create_build_script();
