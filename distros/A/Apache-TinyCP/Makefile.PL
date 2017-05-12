use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Apache::TinyCP',
    'ABSTRACT_FROM' => 'lib/Apache/TinyCP.pm',
    'AUTHOR'        => 'Ian Langworth <ian@cpan.org>',
    'VERSION_FROM'  => 'lib/Apache/TinyCP.pm',
    dist => {
        'PREOP'     => 'pod2text lib/Apache/TinyCP.pm >README',
    },
    'PREREQ_PM'     => {qw(
        Apache::Constants           0
        Apache::FakeRequest         0
        Test::More                  0
        Cache::File                 0
        POSIX                       0
        Template                    0
        Text::KwikiFormatish        0
    )},
);
