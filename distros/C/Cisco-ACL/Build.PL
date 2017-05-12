#
# $Id: Build.PL 86 2004-06-18 20:18:01Z james $
#

use Module::Build;

my $build = Module::Build->new(
	module_name         => 'Cisco::ACL',
    dist_version_from   => 'lib/Cisco/ACL.pm',
	license             => 'perl',
    create_makefile_pl  => 'passthrough',
    create_readme       => 1,
    script_files        => [ 'bin/aclmaker.pl' ],
    requires            => {
        Class::MethodMaker => 0,
        Params::Validate   => '0.65',
    },
    recommends          => {
        CGI             => 0,
    },
    build_requires      => {
        Test::More      => 0,
        Test::Exception => 0,
    },
);

$build->create_build_script;

#
# EOF
