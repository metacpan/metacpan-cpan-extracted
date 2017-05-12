# Build.PL for Business-DK-CVR

# $Id: Build.PL,v 1.3 2008-06-11 08:08:00 jonasbn Exp $

use Module::Build;
my $build = Module::Build->new(
    dist_author          => 'Jonas B. Nielsen, (jonasbn) <jonasbn@cpan.org>',
    module_name          => 'Business::DK::CVR',
    dist_version_from    => 'lib/Business/DK/CVR.pm',
    license              => 'artistic',
    create_makefile_pl   => 'traditional',
    create_readme        => 1,
    recursive_test_files => 1,
    requires             => {
        'Exporter'         => '0',       #core
        'Carp'             => '0',       #core
        'Scalar::Util'     => '0',
        'Class::InsideOut' => '0',
        'English'          => '0',
        'Params::Validate' => '0',
        'Readonly'         => '0',
        'perl'             => '5.008',
    },
    build_requires => {
        'Test::More'          => '0',    #core
        'Test::Exception'     => '0',
        'Test::Perl::Critic'  => '0',
        'Test::Prereq::Build' => '0',
        'Test::Taint'         => '0',
        'Test::Kwalitee'      => '0',
        'Taint::Runtime'      => '0',
        'Data::FormValidator' => '0',
    },
    meta_merge => {
        resources => {
            homepage => 'http://logicLAB.jira.com/browse/BDKCVR',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-CVR',
            repository => 'https://github.com/jonasbn/bdkcvr',
            ProjectChangelog =>
                'http://logiclab.jira.com/browse/BDKCVR#selectedTab=com.atlassian.jira.plugin.system.project%3Achangelog-panel',
            ProjectSite => 'http://logicLAB.jira.com/browse/BDKCVR',
            ProjectWiki =>
                'http://logiclab.jira.com/wiki/display/BDKCVR/Home',
        }
    },
);
$build->create_build_script();
