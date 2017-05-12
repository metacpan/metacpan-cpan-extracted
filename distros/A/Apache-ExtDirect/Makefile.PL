use 5.012000;
use strict;
use warnings;
no  warnings 'uninitialized';

use ExtUtils::MakeMaker;

eval "require Apache::TestMM" or
    die "Required module Apache::TestMM not found. Is mod_perl2 installed?\n";

Apache::TestMM->import( qw(test clean) );

# Try to find apxs
my $have_apxs = !(system "which apxs >/dev/null 2>&1")
             || $ENV{APACHE_TEST_APXS}
             || grep { /^-apxs/ } @ARGV;

die "You must explicitly specify -httpd and/or -apxs options, or set \$ENV{APACHE_TEST_HTTPD} and \$ENV{APACHE_TEST_APXS}, or set your \$PATH to include the httpd and apxs binaries.\n"
    unless $have_apxs;

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

my @scripts = qw(t/TEST t/SMOKE);

WriteMakefile(
    NAME              => 'Apache::ExtDirect',
    VERSION_FROM      => 'lib/Apache/ExtDirect.pm', # finds $VERSION

    ($ExtUtils::MakeMaker::VERSION >= 6.55
        ? ( BUILD_REQUIRES => {
                'LWP::UserAgent' => 0,
            },
            PREREQ_PM => {
                'mod_perl2' => '2.0',
                'Apache2::Request' => '2.0',
                'RPC::ExtDirect' => '2.0',
            },
          )
        : ( PREREQ_PM {
                'LWP::UserAgent' => 0,
                'mod_perl2' => '2.0',
                'Apache2::Request' => '2.0',
                'RPC::ExtDirect' => '2.0',
            },
          )
    ),
    ABSTRACT => 'RPC::ExtDirect gateway for Apache2/mod_perl',
    AUTHOR   => 'Alexander Tokarev <tokarev@cpan.org>',
    LICENSE  => 'perl',
    META_MERGE => {
        resources => {
            bugtracker => 'http://github.com/nohuhu/Apache-ExtDirect/issues',
            repository => 'http://github.com/nohuhu/Apache-ExtDirect',
        },
    },

    clean => { FILES => join(' ', @scripts), },

    MIN_PERL_VERSION => 5.012000,
);

