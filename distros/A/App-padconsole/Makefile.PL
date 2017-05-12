use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'App::padconsole',
    'VERSION_FROM'  => 'padconsole',
    'AUTHOR'        => 'Luc Didry <luc@didry.org>',
    'ABSTRACT'      => 'A console to manage your etherpad instance',

    'EXE_FILES'     =>  [ 'padconsole' ],

    'LICENSE'       => 'perl',

    'PREREQ_PM'     => {
        'Etherpad'       => '1.2.10.3',
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
                url  => 'git://github.com/ldidry/padconsole.git',
                web  => 'https://github.com/ldidry/padconsole',
            },
        },
    },

);
