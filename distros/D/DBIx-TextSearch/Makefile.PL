use ExtUtils::MakeMaker;
use English;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      NAME	     => 'DBIx::TextSearch',
	      VERSION_FROM => 'lib/DBIx/TextSearch.pm',
	      PREREQ_PM    => {'DBI', 'Carp', 'Env', 'English', 'Net::FTP',
			      'LWP::Simple', 'LWP::UserAgent',
			       'HTTP::Response', 'SGML::StripParser',
			       'Text::Query::BuildSQL', 'URI', 
			       'File::Basename',
			       'HTML::TokeParser', 'Socket', 'Sys::Hostname',
			       'Digest::MD5'
			      },
	      PM           => {'lib/DBIx/TextSearch.pm'
				   => '$(INST_LIBDIR)/TextSearch.pm',
			       'lib/DBIx/TextSearch/developing.pod'
			           => '$(INST_LIBDIR)/TextSearch/developing.pod',
			       'lib/DBIx/TextSearch/Pg.pm'
			           => '$(INST_LIBDIR)/TextSearch/Pg.pm'
			       },
	      ($] >= 5.005 ?
	       (ABSTRACT => "Database independent text indexing, Postgres, mysql and DB2 on;y at the moment",
		AUTHOR     => 'Stephen Patterson <steve@patter.mine.nu>') :())
	      );
