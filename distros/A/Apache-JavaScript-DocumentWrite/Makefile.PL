use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Apache::JavaScript::DocumentWrite',
    'VERSION_FROM' => 'lib/Apache/JavaScript/DocumentWrite.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	mod_perl => 1.20,
    },
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
