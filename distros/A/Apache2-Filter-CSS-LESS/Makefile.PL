require 5.008;

use ExtUtils::MakeMaker;

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= 1.22
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
    print "Skipping Apache::Test setup (Apache::Test 1.22 or later required)\n";
}

my %conf = (
    NAME         => 'Apache2::Filter::CSS::LESS',
    VERSION_FROM => 'lib/Apache2/Filter/CSS/LESS.pm',
    PREREQ_PM    => {
        'mod_perl2'    => '1.9922',    # 2.0 RC5
        'CSS::LESSp'   => 0,
        'Apache::Test' => 1.22
    },
    clean => { FILES => join ' ', @CleanFiles }
);

if (MM->can('signature_target')) {
    $conf{SIGN} = 1;
}

if ($] >= 5.005) {
    $conf{ABSTRACT_FROM} = 'lib/Apache2/Filter/CSS/LESS.pm',
    $conf{AUTHOR} = 'Michael Schout <mschout@cpan.org>'
}

if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $conf{META_MERGE} = {
        no_index  => { directory => [qw(t)] },
        resources => {
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-Filter-CSS-LESS',
            repository => 'http://github.com/mschout/apache2-filter-css-less',
        }
    };
}

WriteMakefile(%conf);
