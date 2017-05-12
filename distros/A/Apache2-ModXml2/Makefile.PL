use 5.010001;
use ExtUtils::MakeMaker;


use constant PROMPT_SKIP => 
'Testing this module requires Apache::Test.
Do you want to skip testing? [y/N]';

use constant HAVE_APACHE_TEST => eval {
    require Apache::Test && Apache::Test->VERSION >= 1.22
};

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
    NAME              => 'Apache2::ModXml2',
    VERSION_FROM      => 'lib/Apache2/ModXml2.pm', # finds $VERSION
    PREREQ_PM         => {'XML::LibXML' => 1.89}, # We need Devel
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache2/ModXml2.pm', # retrieve abstract from module
       AUTHOR         => 'Joachim Zobel <jz-2011@heute-morgen.de>') : ()),
    LIBS              => ['-lxml2 -laprutil-1'],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => join(' ', qw(
                            -I. 
                            -I/usr/include/libxml2 
                            -I/usr/include/apache2 
                            -I/usr/include/apr-1.0)), 
    OBJECT            => '$(O_FILES)', # link all the C files too
);

