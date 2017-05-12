use 5.006;
use strict;
use ExtUtils::MakeMaker;

# minimum Apache::Test version.
# 1.26 fixes Test::Builder problems
use constant MIN_APACHE_TEST_VERSION => 1.26;

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= MIN_APACHE_TEST_VERSION
};

my @CleanFiles;

if (HAVE_APACHE_TEST) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));

    push @CleanFiles, 't/TEST';
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
}
else {
    print "Skipping Apache::Test setup (Apache::Test 1.26 or later required)\n";
}

my %conf = (
    NAME         => 'Apache::Singleton',
    VERSION_FROM => 'lib/Apache/Singleton.pm',
    PREREQ_PM    => {
        'Test::More'   => 0.32,
        'Apache::Test' => MIN_APACHE_TEST_VERSION,
    },
    clean => { FILES => join ' ', @CleanFiles }
);

if (mod_perl_version() == 2) {
    # require 2.0 RC5 (Apache -> Apache2)
    $conf{PREREQ_PM}{mod_perl2} = 1.999022;
}
else {
    $conf{PREREQ_PM}{mod_perl} = 0;
}

if (MM->can('signature_target')) {
    $conf{SIGN} = 1;
}

if ($] >= 5.005) {
    $conf{ABSTRACT_FROM} = 'lib/Apache/Singleton.pm';
    $conf{AUTHOR}        = 'Michael Schout <mschout@cpan.org>';
}

if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $conf{META_MERGE} = {
        no_index => { directory => [qw(t)] },
        resources => {
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache-Singleton',
            repository => 'http://github.com/mschout/apache-singleton',
            homepage   => 'http://github.com/mschout/apache-singleton/downloads'
        }
    };
}

WriteMakefile(%conf);

sub mod_perl_version {
    # try to figure out what version of mod_perl is installed.
    eval {
        require mod_perl
    };
    unless ($@) {
        if ($mod_perl::VERSION < 1.99) {
            return 1;
        }
        elsif ($mod_perl::VERSION < 1.999022) {
            # this is mod_perl2 < 2.0 RC5 (1.999_21 or earlier).
            # Apache renamed to Apache2 in 1.999_22
            die "mod_perl 2.0.0 RC5 (1.999022) or later is required ",
                "for this module\n",
                "   found version $mod_perl::VERSION at ", $INC{'mod_perl.pm'};
        }
    }

    eval {
        require mod_perl2;
    };
    unless ($@) {
        return 2;
    }

    # we didn't fine a supported version issue a warning, and assume version 2.
    warn "no supported mod_perl version was found.  assuming version 2\n";

    return 2;
}
