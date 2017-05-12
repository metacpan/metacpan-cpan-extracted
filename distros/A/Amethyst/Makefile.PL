use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Amethyst',
    'VERSION_FROM'	=> 'Amethyst.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			POE				=> 0.23,
			HTTP::Request	=> 1.30,
			HTTP::Response	=> 1.36,
			Math::BaseCalc	=> 1.011,
			Math::Trig		=> 1.0,
			Text::Soundex	=> 1.0,
			POE::Component::Client::DNS			=> 0.94,
			POE::Component::Client::UserAgent	=> 0.04,
			Net::DNS		=> 0.31,
			Parse::Lex		=> 2.15,
			URI				=> 1.22,
			WWW::Search		=> 2.36,
			},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Amethyst.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);
