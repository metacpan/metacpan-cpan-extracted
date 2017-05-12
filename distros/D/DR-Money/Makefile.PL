use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'DR::Money',
    VERSION_FROM      => 'lib/DR/Money.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DR/Money.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry E. Oboukhov <unera@>') : ()),
    LICENSE           => 'Perl',
    META_MERGE => {
        resources => {
            homepage => 'https://github.com/dr-co/dr-money',
            bugtracker => 'https://github.com/dr-co/dr-money/issues',
        }
    }
);

open my $fh, '>>', 'Makefile';
print $fh "\nTEST_VERBOSE=1\n";

