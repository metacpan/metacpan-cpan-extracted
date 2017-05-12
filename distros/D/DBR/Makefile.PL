use ExtUtils::MakeMaker;
use strict;

my $version = '1.5';

my $has_mysql = eval "require DBD::mysql";

WriteMakefile(
	      NAME            => 'DBR',
	      VERSION         => $version,
              EXE_FILES    => [qw'bin/dbr-admin bin/dbr-dump-spec bin/dbr-load-spec bin/dbr-scan-db bin/dbr-config'],
	      PREREQ_PM       => {
				  'Carp'               => 0,
				  'Class::Std'         => 0,
				  'Clone'              => 0,
				  'Curses::UI'         => 0,
				  'Data::Dumper'       => 0,
				  'DateTime'           => 0,
				  'DateTime::Locale'   => 0,
				  'DateTime::TimeZone' => 0,
				  $has_mysql ? (# If we have mysql, it needs to be a good version
				    'DBD::mysql' => '4.002',
				  ) : (),
				  'DBD::SQLite'        => '1.20',
				  'DBI'                => 0,
				  'Digest::MD5'        => 0,
				  'File::Path'         => '1.08',
				  'FileHandle'         => 0,
				  'Getopt::Long'       => 0,
				  'Moose'              => 0,
				  'POSIX'              => 0,
				  'Scalar::Util'       => 0,
				  'Switch'	           => 0,
				  'Symbol'             => 0,
				  'Test::More'         => '0.87',
				  'Time::HiRes'        => 0,
				  'Time::ParseDate'    => 0,
				  'Text::SimpleTable::AutoWidth' => 0
				 },

	     );
