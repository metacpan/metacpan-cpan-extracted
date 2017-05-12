use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'CGI::XMLPost',
    'VERSION_FROM'	=> 'lib/CGI/XMLPost.pm', 
    'PREREQ_PM'		=> {
        },
    'LICENSE'       => 'perl',
    'ABSTRACT'      => 'Receive XML data as an HTTP POST',
    'AUTHOR'        => ['Jonathan Stowe <gellyfish@gellyfish.co.uk'],
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jonathanstowe/CGI-XMLPost.git',
                web  => 'https://github.com/jonathanstowe/CGI-XMLPost',
            },
        },
    },
);
