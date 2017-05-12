use strict;
use Module::Build;

print << 'HERE';
This Makefile.PL of CPAN::Test::Dummy::Perl5::Make::FailLate
demonstrates what happens when a distribution dies during
'make' or 'Build'.

This can be avoided by touching a file 'SURVIVE' in the current
directory.

HERE

my $class = Module::Build->subclass(
    class => "Module::Build::FailLate",
    code => <<'SUBCLASS', );

    sub ACTION_build {
        die "Problem making this distribution" unless -e 'SURVIVE';
    }
SUBCLASS

$class->new( 
    module_name         => "CPAN::Test::Dummy::Perl5::Make::FailLate",
    dist_author         => 'David A. Golden <dagolden@cpan.org>',
    PL_files            => { 'Die.PL' => 'impossible_file.pm' },
    license             => 'perl',
    create_readme       => 1,
)->create_build_script;
