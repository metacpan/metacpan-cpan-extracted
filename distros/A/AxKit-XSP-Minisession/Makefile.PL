# $Id: /local/CPAN/AxKit-XSP-Minisession/Makefile.PL 1430 2008-03-08T21:44:59.461106Z claco  $
use strict;
use warnings;
use inc::Module::Install 0.65;
use File::Spec::Functions;
use File::Path;

name 'AxKit-XSP-Minisession';
license 'artistic';
perl_version '5.008000';
all_from 'lib/AxKit/XSP/Minisession.pm';

requires 'AxKit'                 => 1.62;
requires 'Apache::Log';
requires 'Apache::Session::File';
requires 'Apache::Cookie';
requires 'mod_perl';

my $sessiondir = catfile('t', 'htdocs', 'session');
my $sessionlockdir = catfile('t', 'htdocs', 'sessionlock');

tests 't/*.t';
clean_files "smoke-report-* t/TEST t/SMOKE t/logs $sessiondir $sessionlockdir";

eval {
    system 'pod2text lib/AxKit/XSP/Minisession.pm > README';
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


    mkdir($sessiondir);
    mkdir($sessionlockdir);
};

auto_install;
WriteAll;
