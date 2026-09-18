use 5.012;

use strict;
use warnings;
use Module::Build;

my $deployer = Module::Build->subclass(
      class => 'Module::Build::Deploy',
      code => <<'SUBCLASS' );
sub ACTION_deploy {

    require CPAN::Uploader;
    require MetaCPAN::Client;
    use version;

    my $self = shift;
    $self->depends_on("dist");

    # check that this is a newer version
    my $name = $self->dist_name;
    my $mpan = MetaCPAN::Client->new();
    my $existing = $mpan->release($name)->version;
    if (version->parse($existing) >= version->parse($self->dist_version)) {
        warn "This version is <= the version on CPAN, aborting nicely\n";
        return 1;
    }

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
    license            => 'Perl_5',
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
);
$builder->create_build_script;
