package App::SimpleBackuper;

use strict;
use warnings;

sub BackupDB {
	my($options, $state) = @_;
	
	print "Backuping database...\t" if $options->{verbose};
	
	my $db_file = App::SimpleBackuper::RegularFile->new($options->{db}, $options);
	$db_file->data_ref( $state->{db}->dump() );
	
	$db_file->compress();
	$db_file->write();
	
	my($key, $iv) = $db_file->gen_keys();
	$db_file->encrypt( $key, $iv );
	
	$state->{storage}->put(db => $db_file->data_ref);
	
	my $db_key = $state->{rsa}->encrypt(pack("a32a16", $key, $iv));
	
	$state->{storage}->put('db.key' => \$db_key);
	
	print "done.\n" if $options->{verbose};
}

1;
