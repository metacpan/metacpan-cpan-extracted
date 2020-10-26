package App::SimpleBackuper;

use strict;
use warnings;
use App::SimpleBackuper::BackupDB;
use App::SimpleBackuper::_format;
use App::SimpleBackuper::_BlocksInfo;

sub StorageCheck {
	my($options, $state, $fix) = @_;
	
	my %fails;
	
	print "Fetching files listing from storage...\t" if $options->{verbose};
	my $listing = $state->{storage}->listing();
	print keys(%$listing)." files done\n" if $options->{verbose};
	
	if(@{ $state->{db}->{backups} } and (! exists $listing->{db} or ! exists $listing->{'db.key'})) {
		if($fix) {
			App::SimpleBackuper::BackupDB($options, $state);
		} else {
			push @{ $fails{'Storage lost file'} }, grep {! exists $listing->{ $_ }} qw(db db.key);
		}
	}
	delete @$listing{qw(db db.key)};
	
	
	my %blocks2delete;
	for(my $q = 0; $q <= $#{ $state->{db}->{parts} }; $q++) {
		my $part = $state->{db}->{parts}->unpack($state->{db}->{parts}->[ $q ]);
		my $name = fmt_hex2base64($part->{hash});
		if(! exists $listing->{ $name }) {
			if($fix) {
				$blocks2delete{ $part->{block_id} } = 1;
			} else {
				push @{ $fails{'Storage lost file'} }, $name;
			}
		}
		elsif($part->{size} != $listing->{ $name }) {
			if($fix) {
				$blocks2delete{ $part->{block_id} } = 1;
			} else {
				push @{ $fails{'Storage corrupted'} }, "$name weights $listing->{ $name } instead of $part->{size}";
			}
		}
		delete $listing->{ $name };
	}
	if(%blocks2delete) {
		print "Preparing to delete ".keys(%blocks2delete)." blocks...\t";
		my $blocks_info = App::SimpleBackuper::_BlocksInfo($options, $state);
		print "done\n";
		
		foreach my $block_id (keys %blocks2delete) {
			my $block = $state->{db}->{blocks}->find_row({ id => $block_id });
			print "Removing block # $block_id\n";
			App::SimpleBackuper::_BlockDelete($options, $state, $block, $blocks_info->{$block_id}->[2]);
		}
		App::SimpleBackuper::BackupDB($options, $state);
	}
	
	if(%$listing) {
		if($fix) {
			foreach my $name (keys %$listing) {
				print "Removing unknown extra file $name...\t";
				$state->{storage}->remove($name);
				print "done.\n";
			}
		} else {
			$fails{'Storage has unknown extra file'} = [ keys %$listing ];
		}
	}

	if(%fails) {
		print "Storage data was corrupted:\n";
		while(my($error, $list) = each %fails) {
			print "\t$error (".@$list."):\n";
			print "\t\t$_\n" foreach @$list;
		}
		print "Please run `simple-backuper storage-fix` to sync database about storage state.\n";
		print "But the lost data will remain lost.\n";
		exit -2;
	} else {
		print "Storage checking done.\n" if $options->{verbose};
	}
}

1;
