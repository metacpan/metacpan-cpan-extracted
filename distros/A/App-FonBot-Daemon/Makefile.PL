use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::FonBot::Daemon',
	VERSION_FROM      => 'lib/App/FonBot/Daemon.pm',
	ABSTRACT_FROM     => 'lib/App/FonBot/Daemon.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => ['fonbotd'],
	MIN_PERL_VERSION  => "5.14.0",
	LICENSE           => 'open_source', # AGPL_3 to be exact, but that requires META version 2
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Apache2::Authen::Passphrase             0
		   Email::Sender::Simple                   0
		   Email::Simple                           0
		   Email::MIME                             0
		   File::Slurp                             0
		   HTTP::Status                            0
		   IRC::Utils                              0
		   JSON                                    0
		   Linux::Inotify2                         0
		   Log::Log4perl                           0
		   POE                                     0
		   POE::Component::IRC                     0
		   POE::Component::IRC::Plugin::AutoJoin   0
		   POE::Component::IRC::Plugin::Connector  0
		   POE::Component::IRC::Plugin::NickServID 0
		   POE::Component::Server::HTTP            0
		   POE::Component::SSLify                  0

		   DB_File          0
		   File::Glob       0
		   MIME::Base64     0
		   Storable         0
		   Text::ParseWords 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=app-fonbot-daemon.git',
			IRC          => 'irc://irc.oftc.net/#fonbot',
		},
	}
);
