use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

our ($INC, $PREREQ_PM);

BEGIN {
    $INC = '',
    $PREREQ_PM = {
        'Apache::Test'  => 1,
        'Test::More'    => 0,
    };

    eval { require mod_perl };
    if (!$@) {
        if ($mod_perl::VERSION >= 1.99) {
            # sorry we can't do pre-rc5 mod_perl2.
            die "Incompatible version of mod_perl. Please upgrade.";
        }

        # last sane mod_perl 1?
        $PREREQ_PM->{'mod_perl'} = 1.24_01;

        # i don't think we need the following right now.
        
        # mod_perl 1.x command table xs generator
        #require Apache::src;
        #$INC = Apache::src->new->inc;
        #require Apache::ExtUtils;
        #Apache::ExtUtils->import('command_table');

        #require Apache::LogF::Engine;
        #command_table('Apache::LogF', \@Apache::LogF::Engine::DIRECTIVES);
    }

    eval { require mod_perl2 };
    if (!$@) {
        # mod_perl2 rc5 namespace switch
        $PREREQ_PM->{'mod_perl2'} = 1.999022;
    }
}

use Apache::TestMM qw(test clean);

Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME                => 'Apache::LogF',
    AUTHOR              => 'dorian taylor <dorian@cpan.org>',
    VERSION_FROM        => 'lib/Apache2/LogF.pm',
    ABSTRACT_FROM       => 'lib/Apache2/LogF.pm',
    INC                 => $INC,
    PREREQ_PM           => $PREREQ_PM,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-LogF-* t/TEST' },
);
