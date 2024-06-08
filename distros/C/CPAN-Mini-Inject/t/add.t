use strict;
use warnings;

use Test::More;

use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use File::Temp;

use lib 't/lib';
use Local::localserver;
use Local::utils;

my $class = 'CPAN::Mini::Inject';

$SIG{'INT'} = sub { print "\nCleaning up before exiting\n"; exit 1 };
my $temp_dir = File::Temp::tempdir(CLEANUP=>1);

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "Could not load $class: $@" );
	can_ok $class, 'new';
	isa_ok $class->new, $class;
	};

my $repo_dir = catfile $temp_dir, 'injects';
subtest 'create directory' => sub {
	make_path $repo_dir;
	ok -e $repo_dir, 'repository dir exists'
	};

my $tmp_config_file = catfile $temp_dir, 'config';
subtest 'make config' => sub {
	my $fh;
	if( open $fh, '>', $tmp_config_file ) {
		print {$fh} <<"HERE";
local: $temp_dir
remote : http://localhost:11027
repository: $repo_dir
dirmode: 0775
passive: yes
HERE
		close $fh;
		pass( "created config file" );
		}
	else {
		fail("Could not create config file. Cannot continue");
		done_testing();
		exit;
		}
	};

subtest 'add' => sub {
	my $mcpi = $class->new;
	isa_ok $mcpi, $class;
	can_ok $mcpi, 'add';

	ok -e $tmp_config_file, 'config file exists';
	$mcpi->loadcfg( $tmp_config_file )->parsecfg;

	my $archive_file = 'CPAN-Mini-Inject-0.01.tar.gz';
	my $archive_path = catfile qw(t local mymodules), $archive_file;
	my $module = $class;
	ok( -e $archive_path, "file <$archive_file> exists" );

	my $author = 'SSORICHE';
	ok $mcpi->add(
		module   => $module,
		authorid => $author,
		version  => '0.01',
		file     => $archive_path
	)->add(
		module   => $module,
		authorid => $author,
		version  => '0.02',
		file     => $archive_path
	), 'adding twice succeeded';

	ok exists $mcpi->{modulelist}, 'modulelist key exists';
	isa_ok $mcpi->{modulelist}, ref [], 'modulelist value is an array ref';
	is scalar @{$mcpi->{modulelist}}, 1, 'modulelist array has one entry';
	like $mcpi->{modulelist}[0], qr/\A\Q$module\E/, "modulelist entry has $module";

	my $author_path = catfile
		$repo_dir,
		qw(authors id),
		substr( $author, 0, 1 ),
		substr( $author, 0, 2 ),
		$author;
	ok -e $author_path, "author directory for $author exists";
	is( mode($author_path), 0775, 'author dir mode is 775' ) if has_modes();

	my $repo_archive_path = catfile $author_path, $archive_file;
	ok -e $repo_archive_path, 'archive exists in repository';
	is( mode($repo_archive_path), 0664, 'archive path is mode is 664' ) if has_modes();
	ok -r $repo_archive_path, 'archive in repository is readable';
	};



done_testing();
