use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker qw/WriteMakefile prompt/;

my ( @program, @extra_modules );
print <<"END_NOTE";

The 'aiprolog' shell is optional.  If you choose to install it, Term::ReadLine
and Term::ReadKey will be added to your list of prerequisites.

END_NOTE

if (prompt( "Do you wish to install the 'aiprolog' shell?", "y" ) =~ /^[Yy]/ )
{
    @program = ( EXE_FILES => ["bin/aiprolog"] );
    @extra_modules = (
        'Term::ReadLine' => 1.01,
        'Term::ReadKey'  => 2.21,
    );
}

WriteMakefile(
    'NAME'         => 'AI::Prolog',
    'VERSION_FROM' => 'lib/AI/Prolog.pm',
    @program,
    'PREREQ_PM' => {
        'aliased'        => 0.11,
        'Clone'          => 0.15,
        'Exporter::Tidy' => 0.06,
        'Hash::AsObject' => 0.05,
        'Pod::Usage'     => 1.12,
        'Regexp::Common' => 2.119,
        'Text::Balanced' => 1.95,
        'Text::Quote'    => 0.03,
        'Scalar::Util'   => 0,
        'Hash::Util'     => 0,
        @extra_modules
    },
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/AI/Prolog.pm',
            AUTHOR        => 'Curtis "Ovid" Poe'
            )
        : ()
    ),
);
