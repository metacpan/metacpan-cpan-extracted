use ExtUtils::MakeMaker;

require 5.8.8;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Apache::TestMM qw( clean test );

my @scripts = qw( t/TEST );

# accept the configs from command line
Apache::TestMM::filter_args();

# generate test scripts
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME         => 'Apache2::WebApp::Plugin::Session::MySQL',
    VERSION_FROM => 'lib/Apache2/WebApp/Plugin/Session/MySQL.pm', # finds \$VERSION
    AUTHOR       => 'Marc S. Brooks (mbrooks@cpan.org)',
    PREREQ_PM => {
        'Apache::Test'                     => 0,
        'Apache::Session::MySQL'           => 1.01,
        'Apache::Session::Lock::MySQL'     => 1.01,
        'Apache2::WebApp'                  => 0.38,
        'Apache2::WebApp::Plugin::Cookie'  => 0.09,
        'Apache2::WebApp::Plugin::DBI'     => 0.09,
        'Apache2::WebApp::Plugin::Session' => 0.14,
        'Params::Validate'                 => 0,
    },
    clean => {
        FILES => "@{ clean_files() }",
    }
);

sub clean_files {
    return [@scripts];
}
