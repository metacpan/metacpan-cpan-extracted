

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Bot::BasicBot::Pluggable::Module::Delicious',
    VERSION_FROM => 'lib/Bot/BasicBot/Pluggable/Module/Delicious.pm', # finds \$VERSION
    AUTHOR       => 'Franck Cuny (franck@breizhdev.net)',
    ABSTRACT     => 'A Simple URL catcher for Bot::BasciBot::Pluggable',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
					 'Net::Delicious' => 0.92,
					 'Regexp::Common' => 2.120,
                    },
);
