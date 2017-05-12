use strict;
use warnings;
use ExtUtils::MakeMaker;

our ($INC, $PREREQ_PM);

BEGIN {
    $INC = '';
    $PREREQ_PM = {
        'Apache::LogF'  => 0.01,
        'Apache::Test'  => 1,
        'Test::More'    => 0,
    };

    eval { require mod_perl };
    if (!$@) {
        die "Incompatible version of mod_perl 2. Please upgrade."
            if ($mod_perl::VERSION >= 1.99);


        # earliest sane mod_perl 1?
        $PREREQ_PM->{'mod_perl'} = 1.24_01;

        # add command table api, etc
        require Apache::src;
        $INC = Apache::src->new->inc;

        require Apache::ExtUtils;
        # la la cargo cult, import "does something".
        Apache::ExtUtils->import('command_table');

        require 'lib/Apache/DebugLog/Config.pm';
        command_table
            ('Apache::DebugLog', \@Apache::DebugLog::Config::DIRECTIVES);
    }

    eval { require mod_perl2 };
    if (!$@) {
        # earliest sane mod_perl 2?
        $PREREQ_PM->{'mod_perl2'} = 1.999022;
    }
}

use Apache::TestMM qw(test clean);
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME                => 'Apache::DebugLog',
    AUTHOR              => 'dorian taylor <dorian@cpan.org>',
    VERSION_FROM        => 'lib/Apache/DebugLog/Config.pm',
    INC                 => $INC,
    PREREQ_PM           => $PREREQ_PM,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-DebugLog-* DebugLog.xs* t/TEST' },
);
