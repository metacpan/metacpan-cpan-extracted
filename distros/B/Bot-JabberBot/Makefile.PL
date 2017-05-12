use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Bot::JabberBot',
    'VERSION_FROM'	=> 'JabberBot.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			Jabber::Connection  => '0.02',
			Class::MethodMaker  => '1.05',
    			},
     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Jo Walsh <jo@london.pm.org>') : ()),
);
