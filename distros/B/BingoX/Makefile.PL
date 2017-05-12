
use ExtUtils::MakeMaker;
WriteMakefile(
				NAME		=> 'BingoX',
				VERSION 	=> '1.93',
				PREREQ_PM	=> {
								DBI			=> 0,
								'Date::Parse'	=> 0,
								'Time::Object'	=> 0
								}
			);
