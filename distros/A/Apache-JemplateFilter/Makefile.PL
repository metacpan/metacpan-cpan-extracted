use lib 't/lib';
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Apache::test qw(have_httpd);

my %params = Apache::test->get_test_params();
Apache::test->write_httpd_conf
    (%params,
     include => do {local $/; open FH, 't/config.incl'; <FH>});
*MY::test = sub { Apache::test->MM_test(%params) } if have_httpd();

WriteMakefile(
    NAME                => 'Apache::JemplateFilter',
    AUTHOR              => 'FUJIWARA Shunichiro <fujiwara@topicmaker.com>',
    VERSION_FROM        => 'lib/Apache/JemplateFilter.pm',
    ABSTRACT_FROM       => 'lib/Apache/JemplateFilter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'mod_perl'   => 1.21,
        'Jemplate'   => 0.12,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-JemplateFilter-* t/httpd t/httpd.conf t/error_log t/httpd.pid' },
);
