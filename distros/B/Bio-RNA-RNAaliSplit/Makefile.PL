use 5.010;
use lib 'inc';
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

my $github    = 'https://github.com/mtw/Bio-RNA-RNAaliSplit';
my @scripts = qw (RNAalisplit.pl eval_alignment.pl);

WriteMakefile(
	      NAME               => 'Bio::RNA::RNAaliSplit',
	      VERSION_FROM       => 'lib/Bio/RNA/RNAaliSplit.pm',
	      ABSTRACT_FROM      => 'lib/Bio/RNA/RNAaliSplit.pm',
	      LICENSE            => 'agpl_3',
	      AUTHOR             => q{Michael T. Wolfinger <michael@wolfinger.eu>},
	      MIN_PERL_VERSION   => 5.010,
	      CONFIGURE_REQUIRES => {
				     'ExtUtils::MakeMaker' => '6.64',
				    },
	      BUILD_REQUIRES     => {
				    },
	      "TEST_REQUIRES" => {
				  'Test2::V0' => '0.000060',
				  'Test::More' => 0,
				  'Test::Prereq' => 0,
				  },
	      PREREQ_PM          => {
				     "Cwd" => "0",
				     "diagnostics" => "0",
				     "lib" => "0",
				     "strict" => "0",
				     "warnings" => "0",
				     "version" => "0",
				     "Array::Set"=> '0',
				     "Bio::Root::Version" => '1.00690001',
				     "Bio::AlignIO" => '0',
				     "Carp" => '0',
				     "constant" => '0',
				     "Data::Dumper" => '0',,
				     "Digest::MD5" => '0',
				     "File::Basename" => '0',
				     "File::Path" => '0',
				     "File::Share" => '0',
				     "File::Spec" => '0',
				     "FindBin" => '0',
				     "Getopt::Long" => '2.0',
				     "IO::Dir" => '0',
				     "IPC::Cmd" => '0',
				     "Moose" => '0',
				     "Moose::Role" => '0',
				     "Moose::Util::TypeConstraints" => '0',
				     "Path::Class" => '0',
				     "Path::Class::Dir" => '0',
				     "Path::Class::File" => '0',
				     "Pod::Usage" => '0',
				     "RNA" => "2.3.4",
				     "Storable" => '0',
				     "Test::Script" => '1.25',
				     "FileDirUtil" => '0',
				     "namespace::autoclean" => '0',
				    },
	      'EXE_FILES'        => [ map { "scripts/$_" } @scripts ],
	      'META_MERGE'       => {
				     'meta-spec' => { version => 2 },
				     resources => {
						   repository => {
								  type => 'git',
								  url  => "https://github.com/mtw/Bio-RNA-RNAaliSplit.git",
								  web  => "https://github.com/mtw/Bio-RNA-RNAaliSplit",
								 },
						   bugtracker => {
								  web    => "https://github.com/mtw/Bio-RNA-RNAaliSplit/issues",
								 },
						   homepage => $github,
						  },
				    },
	      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean => { FILES => 'Bio-RNA-AliSplit-*' },
	     );

package MY;
use File::ShareDir::Install qw(postamble);

no warnings;
__PACKAGE__;
