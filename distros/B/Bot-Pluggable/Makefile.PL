use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Bot::Pluggable',
    'VERSION_FROM' => 'lib/Bot/Pluggable.pm',
    'PREREQ_PM' => { POE::Component::IRC::Object => 0.02 },
    'ABSTRACT_FROM' => 'lib/Bot/Pluggable.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);
