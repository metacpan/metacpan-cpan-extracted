use ExtUtils::MakeMaker;
use Apache::src;

my $inc = Apache::src->new->inc;

WriteMakefile(
    'NAME'      => 'Apache::DefaultCharset',
    'VERSION_FROM' => 'lib/Apache/DefaultCharset.pm', # finds $VERSION
    'INC' => $inc,
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

