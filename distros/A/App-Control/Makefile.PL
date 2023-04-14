use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'App::Control',
    'VERSION_FROM'	=> 'Control.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/avewrigley/App-Control.git',
                 web  => 'https://github.com/avewrigley/App-Control/',
             },
             bugtracker => {
                 web => 'https://github.com/avewrigley/App-Control/issues',
             },
         },
    },
);
