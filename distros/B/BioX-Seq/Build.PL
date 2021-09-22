use 5.012;

use strict;
use warnings;
use Module::Build;

my $deployer = Module::Build->subclass(
      class => 'Module::Build::Deploy',
      code => <<'SUBCLASS' );
sub ACTION_deploy {

    require CPAN::Uploader;
    my $self = shift;
    $self->depends_on("dist");

    my $tarball = $self->dist_dir() . '.tar.gz';
    die "tarball not found"
        if (! -e $tarball);
    print "Uploading $tarball\n";
    CPAN::Uploader->upload_file( $tarball, {
        user     => $ENV{PAUSE_USER},
        password => $ENV{PAUSE_PASS},
    } );
}
SUBCLASS

my $builder = $deployer->new(
    module_name        => 'BioX::Seq',
    license            => 'GPL_3',
    dist_author        => q{Jeremy Volkening <volkening@cpan.org>},
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Compress::BGZF'  => 0,
        'IPC::Cmd'        => 0,
        'Test::Exception' => 0,
        'Test::More'      => 0,
    },
    requires => {
        'IPC::Cmd'       => 0,
        'Scalar::Util'   => 0,
        'POSIX'          => 0,
        'Cwd'            => 0,
        'File::Basename' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/jvolkening/p5-BioX-Seq'
        }
    },
    add_to_cleanup => [ 'BioX-Seq-*' ],
    create_license => 1,
);
$builder->create_build_script;
