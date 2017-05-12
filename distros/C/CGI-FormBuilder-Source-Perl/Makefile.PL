use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME         => 'CGI::FormBuilder::Source::Perl',
    VERSION_FROM => 'lib/CGI/FormBuilder/Source/Perl.pm',

    PREREQ_PM => {
        'CGI::FormBuilder' => 0,
        'File::Slurp'      => 0,
    },
);

