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
    NAME         => 'Apache2::WebApp::Plugin::DBI',
    VERSION_FROM => 'lib/Apache2/WebApp/Plugin/DBI.pm', # finds \$VERSION
    AUTHOR       => 'Marc S. Brooks (mbrooks@cpan.org)',
    PREREQ_PM => {
        'Apache::Test'     => 0,
        'Apache::DBI'      => 1.07,
        'Apache2::WebApp'  => 0.38,
        'DBI'              => 1.602,
        'Params::Validate' => 0,
        'Test::More'       => 0,
    },
    clean => {
        FILES => "@{ clean_files() }",
    }
  );

sub clean_files {
    return [@scripts];
}

# Install build script template dependencies (non-standard way)
sub MY::postamble {
'
install::
	cp -rv usr/share/webapp-toolkit/plugin* $(PREFIX)/share/webapp-toolkit
';
}
