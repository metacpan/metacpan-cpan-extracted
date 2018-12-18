use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'App::padconsole',
    'VERSION_FROM'  => 'padconsole',
    'AUTHOR'        => 'Luc Didry <luc@didry.org>',
    'ABSTRACT'      => 'A console to manage your etherpad instance',

    'EXE_FILES'     =>  [ 'padconsole' ],

    'LICENSE'       => 'perl',

    'PREREQ_PM'     => {
        'Etherpad'       => '1.2.13.1',
        'Term::ReadLine' => 0,
        'Config::YAML'   => 0,
        'URI::Escape'    => 0,
        'DateTime'       => 0,
        'Browser::Open'  => 0,
    },

    'META_MERGE'    => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://framagit.org/luc/padconsole.git',
                web  => 'https://framagit.org/luc/padconsole',
            },
        },
    },

);
