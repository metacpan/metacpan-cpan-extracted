use 5.006;
use strict;
use ExtUtils::MakeMaker;
use inc::My::Util qw(mod_perl_version);

use constant MIN_APACHE_TEST_VERSION => 1.26;

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= MIN_APACHE_TEST_VERSION
};

my @CleanFiles;

if (HAVE_APACHE_TEST) {
    require Apache::TestMM;

    Apache::TestMM->import(qw(test clean));
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');

    push @CleanFiles, 't/TEST';
}
else {
    print "Skipping Apache::Test setup (Apache::Test ",
        MIN_APACHE_TEST_VERSION, " or later required)\n";
}

my %conf = (
    NAME          => 'Apache::Profiler',
    VERSION_FROM  => 'lib/Apache/Profiler.pm',
    AUTHOR        => 'Michael Schout <mschout@cpan.org>',
    ABSTRACT_FROM => 'lib/Apache/Profiler.pm',
    PREREQ_PM     => {
        'Test::More'   => 0.32,
        'Time::HiRes'  => 0,
        'Apache::Test' => MIN_APACHE_TEST_VERSION
    },
    clean           => { FILES => join ' ', @CleanFiles },
);

if (mod_perl_version() == 2) {
    # 2.0 RC5 (Apache -> Apache2)
    $conf{PREREQ_PM}{mod_perl2} = 1.999022;
}
else {
    $conf{PREREQ_PM}{mod_perl} = 1.20;
}

if (MM->can('signature_target')) {
    $conf{SIGN} = 1;
}

if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $conf{META_MERGE} = {
        no_index => { directory => [qw(t)] },
        resources => {
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache-Profiler',
            repository => 'http://github.com/mschout/apache-profiler',
            homepage   => 'http://github.com/mschout/apache-profiler/downloads'
        }
    };
}

WriteMakefile(%conf);
