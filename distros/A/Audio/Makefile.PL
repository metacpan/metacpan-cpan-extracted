use Config;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'     => 'Audio',
    'EXE_FILES' => [qw(morse pplay dial tkscope)],
    'clean' => {FILES => "*% *.bak *.bck Base/*% out*.au"},
    'linkext' => { LINKTYPE => ''},
#   'OBJECT'   => '$(O_FILES)',
    'dist'     => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
    'VERSION_FROM'  => "Data/Data.pm",
    'PMLIBDIRS'   => ['Tk'],
#   PREREQ_PM     => { 'Math::GSL' => 0 },
);


