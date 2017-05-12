use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'CGI::Form2XML',
    'VERSION_FROM'	=> 'lib/CGI/Form2XML.pm', 
    'PREREQ_PM'		=> {
            'CGI'   => undef,
        },
    'LICENSE'       => 'perl',
    'ABSTRACT'      => 'Render CGI form input as XML',
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jonathanstowe/CGI-Form2XML.git',
                web  => 'https://github.com/jonathanstowe/CGI-Form2XML',
            },
        },
    },
    AUTHOR     => [ 'Jonathan Stowe <jns@gellyfish.co.uk>'],
);
