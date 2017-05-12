#!perl

use 5.008;

use ModPerl::MM ();
use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

# configure tests based on incoming arguments
Apache::TestMM::filter_args();

# provide the test harness
Apache::TestRunPerl->generate_script();

my @extra;
if ($ExtUtils::MakeMaker::VERSION >= 6.36) {
    push @extra, ('EXTRA_META' => <<EOF);
resources:
    license: http://dev.perl.org/licenses/
    Repository: http://svn.ectoplasm.org/projects/perl/Apache2-Layout/trunk/
EOF
}

# now, write out the Makefile
ModPerl::MM::WriteMakefile(
    NAME          => 'Apache2::Layout',
    AUTHOR        => 'Philippe M. Chiasson <gozer@ectoplasm.org>',
    SIGN          => 1,
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Apache2/Layout.pm',
    ABSTRACT_FROM => 'lib/Apache2/Layout.pm',
    INC =>
      "-I/usr/include/httpd -I/usr/include/apache2/ -I/usr/include/apr-1",
    PREREQ_PM => {
                  mod_perl2    => 0,
                  'Test::More' => 0,
                 },
    @extra,
);

sub MY::dist {
    my $orig = shift->MM::dist;
    $orig =~ s/(DIST_DEFAULT\s*=)(.*)/$1 autogen-dist $2/g;
    $orig .= <<'EOF';
autogen-dist: README Changes
README: lib/Apache2/Layout.pm
	pod2text lib/Apache2/*.pm > README
Changes: Changes.yml
	changes -f Changes.yml --ff > Changes
EOF
    return $orig;
}
