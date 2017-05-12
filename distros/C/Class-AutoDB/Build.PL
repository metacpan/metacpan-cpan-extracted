use strict;
no warnings;
use Cwd;
use Module::Build;

use lib qw(t);
use t::Build;			# my Module::Build subclass
my $class='t::Build';
my $MYSQL_dir=File::Spec->catdir(cwd(),qw(t MYSQL));
my $SDBM_dir=File::Spec->catdir(cwd(),qw(t SDBM));

my $builder = $class->new
  (module_name         => 'Class::AutoDB',
   license             => 'perl',
   dist_author         => q{Nat Goodman <natg@shore.net>},
   configure_requires=>{'Cwd' => 3.40,
			'Module::Build' => 0.4007,
			},
   build_requires =>   {'Carp' => 1.20,
			'Class::AutoClass' => 1.56,
			'Cwd' => 3.40,
			'DBD::mysql' => 4.024,
			'DBI' => 1.628,
			'Data::Rmap' => 0.62,
			'Fcntl' => 1.11,
			'File::Basename' => 2.82,
			'File::Path' => 2.09,
			'File::Spec' => 3.40,
			'File::Spec::Functions' => 3.40,
			'FindBin' => 1.50,
			'FreezeThaw' => 0.5001,
			'Getopt::Long' => 2.38,
			'Graph' => 0.94,
			'Hash::AutoHash::Args' => 1.18,
			'List::MoreUtils' => 0.33,
			'List::Util' => 1.23,
			'Module::Build' => 0.4007,
			'SDBM_File' => 1.09,
			'Scalar::Util' => 1.23,
			'Storable' => 2.3,
			'TAP::Harness' => 3.28,
			'TAP::Parser::Aggregator' => 3.28,
			'Test::CheckManifest' => 1.26,
			'Test::Deep' => 0.11,
			'Test::More' => 0.98,
			'Test::Pod' => 1.48,
			'Test::Pod::Content' => '0.0.6',
		       },
   requires =>         {'Class::AutoClass' => 1.56,
			'Class::Singleton' => 1.4,
			'Cwd' => 3.40,
			'DBD::mysql' =>  4.024,
			'DBI' => 1.628,
			'Exporter' => 5.68,
			'Fcntl' => 1.11,
			'Hash::AutoHash' => 1.17,
			'Hash::AutoHash::Args' => 1.18,
			'List::MoreUtils' => 0.33,
			'List::Util' => 1.32,
			'Storable' => 2.30,
			'Text::Abbrev' => 1.02,
			'Tie::ToObject' => 0.03,
			'XSLoader' => 0.15,
		       },
   recommends =>       {'Test::mysqld' => 0.17,
		       },
   add_to_cleanup      => [ 'Class-AutoDB-*',
			    File::Spec->catfile($SDBM_dir,'*'),
			    File::Spec->catfile($MYSQL_dir,'*'),
			    '*.dir', '*.pag' ],
   create_makefile_pl => 'small',
   extra_compiler_flags => ['-DUSE_PPPORT_H'],
   use_tap_harness => 1,			  
   test_files => 't/autodb.*.t',
);

$builder->create_build_script();

