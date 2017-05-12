# package Apache::EnvDir;
use ExtUtils::MakeMaker;

use Apache::ExtUtils qw(command_table);
use Apache::src ();

my @directives = ( { name         => 'EnvDir',
                     errmsg       => 'Directory path and optional prefix',
		     args_how     => 'TAKE12',
		     req_override => 'RSRC_CONF' } );

command_table(\@directives);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	  => 'Apache::EnvDir',
    VERSION_FROM  => 'EnvDir.pm', # finds $VERSION
    PREREQ_PM	  => {}, # e.g., Module::Name => 1.1
    ABSTRACT      => 'Set ENV variables from a directory of files.',
    AUTHOR        => 'Mike Cramer <cramer@webkist.com>',
    INC		  => Apache::src->new->inc,
    clean         => { FILES => "t/TEST t/envdir main.xs main.xs.orig t/conf/apache_test_config.pm t/conf/extra.conf t/conf/httpd.conf t/conf/modperl_inc.pl t/conf/modperl_startup.pl t/logs t/core t/cgi/all.pl t/cgi/content-type.pl t/cgi/env.pl t/cgi/mysql.pl" },
);

sub MY::test {
  eval {
    require Apache::Test;
    require Apache::TestMM;
    require Apache::TestRunPerl;
    require File::Find;

    Apache::TestMM->import(qw(test clean));
    Apache::TestMM::filter_args();
                                                                                
    my @scripts = ("t/TEST");
    File::Find::finddepth(sub {
      return unless /(.*?\.pl)\.PL$/;
      push @scripts, "$File::Find::dir/$1";
    }, '.');

    for my $script (@scripts) {
      Apache::TestMM::generate_script($script);
    }

    return Apache::TestMM->test;
  }

  or return <<EOF;
test::
\t\@echo This test suite requires Apache-Test,
\t\@echo which is available from the mod_perl 2.0 
\t\@echo sources, CPAN, or the httpd-test distribution.
EOF
}

