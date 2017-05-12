#
# Module::Build build script for Courier::Filter
#
# (C) 2005-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Build.PL 211 2008-03-23 01:25:20Z julian $
#
###############################################################################

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Courier::Filter',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        # Core requirements:
        perl                => '5.008',
        Error               => 0
    },
    recommends      => {
        # Filter module requirements:
        Net::RBLClient      => 0,
        Mail::SPF           => 0,
        Net::Address::IP::Local
                            => 0,
        DateTime            => 0,
        DateTime::Format::Mail
                            => 0,
        MIME::Tools         => '5.400',
        IO::InnerFile       => '2.110',
        Archive::Zip        => 0,
        ClamAV::Client      => 0,
        Mail::SpamAssassin  => 0
    },
    build_requires  => {
        # Build requirements:
        Module::Build       => 0
    },
    script_files    => [
        'bin/test-filter-module'
    ],
    install_path    => {
        lib                 => '/usr/share/courier-filter-perl/perl5'
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();
