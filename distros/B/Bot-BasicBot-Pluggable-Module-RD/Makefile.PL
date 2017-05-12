

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Bot::BasicBot::Pluggable::Module::RD',
    VERSION_FROM => 'lib/Bot/BasicBot/Pluggable/Module/RD.pm', # finds \$VERSION
    AUTHOR       => 'Ivor Williams (ivorw@cpan.org)',
    ABSTRACT     => 'RecDescent grammar adaptor plugin',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Parse::RecDescent' => 0,
                     'Parse::RecDescent::Topiary' => 0.04,
                     'Parse::RecDescent::Deparse' => 0,
                     'Bot::BasicBot::Pluggable::Module' => 0,
                    },
);
