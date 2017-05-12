

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Bot::BasicBot::Pluggable::Module::HTTPIRCGW',
    VERSION_FROM => 'lib/Bot/BasicBot/Pluggable/Module/HTTPIRCGW.pm', # finds \$VERSION
    AUTHOR       => 'Franck Cuny (franck@breizhdev.net)',
    ABSTRACT     => 'A Simple HTTP Action for Bot::BasicBot::Pluggable',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'LWP::UserAgent' => 2.033,
                     'URI::Escape' => 3.28,
                    },
);
