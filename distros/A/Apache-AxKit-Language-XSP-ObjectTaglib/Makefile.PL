# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/Makefile.PL 1518 2008-03-08T22:17:31.628142Z claco  $
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Apache-AxKit-Language-XSP-ObjectTaglib';
license 'artistic';
perl_version '5.008000';
all_from 'lib/Apache/AxKit/Language/XSP/ObjectTaglib.pm';

requires 'AxKit' => 1.62;

tests 't/*.t';
clean_files 'smoke-report-* t/TEST t/SMOKE t/logs';

eval {
    system 'pod2text lib/Apache/AxKit/Language/XSP/ObjectTaglib.pm > README';
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
