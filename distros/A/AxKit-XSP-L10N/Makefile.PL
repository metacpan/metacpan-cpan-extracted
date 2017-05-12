# $Id: /local/CPAN/AxKit-XSP-L10N/Makefile.PL 1402 2008-03-08T20:28:41.664717Z claco  $
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'AxKit-XSP-L10N';
license 'artistic';
perl_version '5.008000';
all_from 'lib/AxKit/XSP/L10N.pm';

requires 'AxKit'             => 1.61;
requires 'Locale::Maketext'  => 1.08;
requires 'mod_perl';

tests 't/*.t';
clean_files 'smoke-report-* t/TEST t/SMOKE t/logs';

eval {
    system 'pod2text lib/AxKit/XSP/L10N.pm > README';
};

eval 'use Apache::Test 1.16';
if (!$@) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));

    ## for whatever reason, use AxKit causes issues
    ## use-ing A::A::Exception doesn't
    eval 'use Apache::AxKit::Exception';
    if (!$@) {
        push(@ARGV, '-defines', 'AXKIT');
    };

    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    Apache::TestMM::generate_script('t/SMOKE');
};

auto_install;
WriteAll;
