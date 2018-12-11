use Backup::EZ;
use File::Path qw(make_path remove_tree);
use File::RandomGenerator;

###

use constant DATA_DIR => '/tmp/backup_ez_testdata';

###

sub nuke {

	my $data_dir = shift @ARGV;
	if (!$data_dir) {
    	$data_dir = DATA_DIR;
	}

	# delete previous backup dir if exists
	my $ez = Backup::EZ->new(
    	conf         => 't/ezbackup.conf',
    	exclude_file => 'share/ezbackup_exclude.rsync',
		dryrun       => 1
	);
	die if !$ez;
	
	remove_tree( $ez->{conf}->{dest_dir} );

	# delete previous test data dir if exists
	remove_tree($data_dir);
}

sub pave {

	my $data_dir = shift @ARGV;
	if (!$data_dir) {
		$data_dir = DATA_DIR;
	}

	make_path("$data_dir/dir1");

	my $frg = File::RandomGenerator->new(
		root_dir => "$data_dir/dir1",
		unlink   => 0,
		depth => 2,
	);
	$frg->generate;

	make_path("$data_dir/dir2");

	$frg->root_dir("$data_dir/dir2");
	$frg->generate;
}

1;
