# $Id: Makefile.PL 73 2014-09-26 21:18:06Z jo $
use 5.006000;
use ExtUtils::MakeMaker;

use constant PROMPT_SKIP => 
'Testing this module requires Apache::Test.
Do you want to skip testing? [y/N]';

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= 1.22
};

my $prereq_pm = {
    'Cindy'	=> '0.22', 
    'mod_perl2' => '0', 
};

my @CleanFiles;

if (HAVE_APACHE_TEST) {
    # $Apache::TestTrace::Level = 'debug';

    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));

    push @CleanFiles, 't/TEST';
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
}
else {
    my $skip = prompt(PROMPT_SKIP, 'n');
    if ($skip !~ /^y/i) {
        $prereq_pm->{'Apache::Test'} = 0;
    } else {
        print "Skipping Apache::Test setup (Apache::Test 1.22 or later required)\n";
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Cindy::Apache2',
    VERSION_FROM      => 'lib/Cindy/Apache2.pm', # finds $VERSION
    PREREQ_PM         => $prereq_pm,
    clean             => {FILES => 't/TEST'}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Cindy/Apache2.pm', # retrieve abstract from module
       AUTHOR         => 'JZOBEL (jz-2009@heute-morgen.de)') : ()),
    INC               => join(' ', qw(
                            -I. 
                            -I/usr/include/apache2 
                            -I/usr/include/apr-1.0)), 
    OBJECT            => '$(O_FILES)', # link all the C files too
);

