use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME              => 'Catalyst::Engine::XMPP2',
   VERSION_FROM      => 'lib/Catalyst/Engine/XMPP2.pm',
   PREREQ_PM         => { Catalyst::Runtime => 5.7011,
                          URI => 0, HTTP::Response => 0,
                          HTTP::Request => 0, HTTP::Body => 1.03,
                          AnyEvent::XMPP => 0, Event => 0,
                          Catalyst::Engine::Embeddable => 0,
			  Catalyst::Plugin::ConfigLoader => 0,
                        },
   ABSTRACT_FROM  => 'lib/Catalyst/Engine/XMPP2.pm',
   AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>',
  );
