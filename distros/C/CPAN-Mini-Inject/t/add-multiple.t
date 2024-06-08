use strict;
use warnings;

use Test::More;

use CPAN::Mini::Inject;
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use File::Temp ();

use lib qw(t/lib);
use Local::utils;

my $class = 'CPAN::Mini::Inject';

$SIG{'INT'} = sub { print "\nCleaning up before exiting\n"; exit 1 };
my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "Could not load $class: $@" );
	isa_ok $class->new, $class;
	};

subtest 'setup directories in temp dir' => sub {
	my @dirs = (
		[ qw(modules) ],
		[ qw(authors) ],
		[ qw(injects) ],
		);

	foreach my $dir ( @dirs ) {
		my $path = catfile $temp_dir, @$dir;
		make_path( $path );
		ok -d $path, "Path for <@$dir> exists";
		}
	};

my $t_local = catfile qw(t local);
subtest 'check local dir' => sub {
	ok -d $t_local, 'local directory exists';
	};

subtest 'copy initial files' => sub {
	my $modules_base = catfile $temp_dir, 'modules';
	ok -d $modules_base, 'modules dir exists';

	my $authors_base = catfile $temp_dir, 'authors';
	ok -d $authors_base, 'authors dir exists';

	subtest 'packages' => sub {
		my $file = '02packages.details.txt.gz';
		my $destination = catfile $modules_base, $file;
		my $rc = copy(
		  catfile( $t_local, 'CPAN', 'modules', "$file.original" ),
		  $destination
		);
		ok $rc, 'File::Copy worked';
		ok -e $destination, 'Copied packages file to temp_dir';
		ok chmod(0666, $destination), 'chmod packages to 0666';
		};

	subtest 'mailrc' => sub {
		my $file = '01mailrc.txt.gz';
		my $destination   = catfile $authors_base, $file;
		my $rc = copy(
		  catfile( $t_local, "$file.original" ),
		  $destination
		);
		ok $rc, 'File::Copy worked';
		ok -e $destination, 'Copied mailrc file to temp_dir';
		ok chmod(0666, $destination), 'chmod mailrc to 0666';
		};
	};

sub get_module_details {
	my( $dist_sources ) = @_;
	my @modules = (
		{
		module   => 'CPAN::Mini::Inject',
		authorid => 'SSORICHE',
		version  => '0.01',
		file     => catfile( $dist_sources, 'CPAN-Mini-Inject-0.01.tar.gz' ),
		},
		{
		authorid => 'RWSTAUNER',
		file     => catfile( $dist_sources, 'Dist-Metadata-Test-MetaFile-2.2.tar.gz' ),
		},
		{
		module   => 'Dist::Metadata::Test::MetaFile',
		authorid => 'RWSTAUNER',
		version  => '2.3', # package versions do not match this
		file     => 't/local/mymodules/Dist-Metadata-Test-MetaFile-2.2.tar.gz'
		},
		{
		authorid => 'RWSTAUNER',
		file     => 't/local/mymodules/Dist-Metadata-Test-MetaFile-Only.tar.gz'
		},
		);
	}

subtest 'add modules' => sub {
	my $dist_sources = catfile $t_local, 'mymodules';
	ok -d $dist_sources, 'Dist sources directory exists';
	my @modules = get_module_details( $dist_sources );

	subtest 'check module sources are there' => sub {
		foreach my $module ( @modules ) {
			ok -e $module->{file}, "$module->{file} exists";
			}
		};

	my $tmp_config_file;
	subtest 'make config' => sub {
		$tmp_config_file = write_config(
			local      => $temp_dir,
			repository => catfile( $temp_dir, 'injects' ),
			);
		ok -e $tmp_config_file, 'configuration file exists';
		};

	my $mcpi = $class->new;
	isa_ok $mcpi, $class;

	$mcpi->loadcfg( $tmp_config_file )->parsecfg;

	foreach my $module ( @modules ) {
		my $basename = basename($module->{file});
		subtest $basename => sub {
			ok $mcpi->add( %$module ), "Added " . $basename;
			my $auth_path = catfile(
				substr($module->{authorid}, 0, 1),
				substr($module->{authorid}, 0, 2),
				$module->{authorid},
				);
			is( $mcpi->{authdir}, $auth_path, "author directory <$auth_path> exists in injects repo" );

			my $module_path = catfile $temp_dir, 'injects', 'authors', 'id', $auth_path, $basename;
			ok( -e $module_path, "Added module <$basename> exists" );
			ok( -r $module_path, "Added module <$basename> is readable" );
			};
		}

	is_deeply(
	  	[$mcpi->added_modules],
		[
			{ file => 'CPAN-Mini-Inject-0.01.tar.gz', authorid => 'SSORICHE', modules => {'CPAN::Mini::Inject' => '0.01'} },
			{ file => 'Dist-Metadata-Test-MetaFile-2.2.tar.gz', authorid => 'RWSTAUNER',
			  modules => { 'Dist::Metadata::Test::MetaFile::PM' => '2.0', 'Dist::Metadata::Test::MetaFile' => '2.1' } },
			# added twice (bug in usage not in reporting)
			{ file => 'Dist-Metadata-Test-MetaFile-2.2.tar.gz', authorid => 'RWSTAUNER',
			  modules => { 'Dist::Metadata::Test::MetaFile::PM' => '2.0', 'Dist::Metadata::Test::MetaFile' => '2.1' } },
			{ file => 'Dist-Metadata-Test-MetaFile-Only.tar.gz', authorid => 'RWSTAUNER',
			  modules => {'Dist::Metadata::Test::MetaFile::DiffName' => '0.02'} },
		],
		'added_modules returns expected data'
		);

	subtest 'packages entries' => sub {
		my @expected_lines = <DATA>;
		chomp(@expected_lines);
		my %expected_lines = map { $_, 1 } grep { /\S/ } @expected_lines;

		my %Seen;
		foreach my $line ( @{ $mcpi->{modulelist} } ) {
			my( $module ) = $line =~ /\A(\S+)/;
			ok exists $expected_lines{$line}, "Found line for $module";
			fail( "Saw $module multiple times" ) if exists $Seen{$module};
			$Seen{$module}++;
			}
		};
	};

done_testing();

__END__
CPAN::Mini::Inject                 0.01  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz
Dist::Metadata::Test::MetaFile::PM  2.0  R/RW/RWSTAUNER/Dist-Metadata-Test-MetaFile-2.2.tar.gz
Dist::Metadata::Test::MetaFile      2.1  R/RW/RWSTAUNER/Dist-Metadata-Test-MetaFile-2.2.tar.gz
Dist::Metadata::Test::MetaFile::DiffName 0.02  R/RW/RWSTAUNER/Dist-Metadata-Test-MetaFile-Only.tar.gz
