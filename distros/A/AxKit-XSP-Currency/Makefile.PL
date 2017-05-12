# $Id: /local/CPAN/AxKit-XSP-Currency/Makefile.PL 1486 2008-03-08T22:00:13.791163Z claco  $
use strict;
use warnings;
use inc::Module::Install 0.65;

name 'AxKit-XSP-Currency';
license 'artistic';
perl_version '5.008000';
all_from 'lib/AxKit/XSP/Currency.pm';

requires 'AxKit'                 => 1.62;
requires 'mod_perl';
requires 'Locale::Currency::Format';
requires 'Finance::Currency::Convert::WebserviceX';

tests 't/*.t';
clean_files 'smoke-report-* t/TEST t/SMOKE t/logs';

eval {
    system 'pod2text lib/AxKit/XSP/Currency.pm > README';
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
