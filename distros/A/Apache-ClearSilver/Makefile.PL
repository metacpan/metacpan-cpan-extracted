package Apache::ClearSilver;

use ExtUtils::MakeMaker;
use lib './lib';
use Apache::ClearSilver;
use Apache::src ();
use Apache::ExtUtils qw(command_table);

my @directives = (
    {
        name         => 'HDFLoadPath',
        args_how     => 'ITERATE',
        req_override => 'RSRC_CONF | ACCESS_CONF',
    },
    {
        name         => 'HDFFile',
        args_how     => 'ITERATE',
        req_override => 'RSRC_CONF | ACCESS_CONF',
    },
    {
        name         => 'HDFSetValue',
        args_how     => 'TAKE12',
        req_override => 'RSRC_CONF | ACCESS_CONF',
    },
    {
        name         => 'CSContentType',
        args_how     => 'TAKE1',
        req_override => 'RSRC_CONF | ACCESS_CONF',
    },
);

__PACKAGE__->command_table(\@directives);

WriteMakefile(
    NAME          => 'Apache::ClearSilver',
    AUTHOR        => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM  => 'lib/Apache/ClearSilver.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'           => 0.32,
        'mod_perl'             => 1.20,
        'ClearSilver'          => 0,
        'Apache::ModuleConfig' => 0,
    },
    PMLIBDIRS => ['lib'],
    INC       => Apache::src->new->inc,
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'Apache-ClearSilver-*' },
);


sub MY::test {
    if (eval "require Apache::TestMM") {
        Apache::TestMM::generate_script('t/TEST');
        return Apache::TestMM->test;
    }

    return <<EOF;
test::
\t\@echo This test suite requires Apache::Test
\t\@echo available from the mod_perl 2.0 sources
\t\@echo or the httpd-test distribution.
EOF
    ;
}
