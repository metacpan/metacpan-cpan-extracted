use Module::Build;

my $build = Module::Build->new(
    module_name     => 'ClamAV::Client',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        # Core requirements:
        perl                => 0,
        IO::File            => 0,
        IO::Socket          => 0,
        IO::Socket::UNIX    => 0,
        IO::Socket::INET    => 0,
        Error               => 0
    },
    recommends      => {
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL,v 1.1 2005/01/11 23:15:30 julian Exp $
# vim:tw=79
