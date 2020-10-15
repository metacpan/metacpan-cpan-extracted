package App::SimpleBackuper;

use strict;
use warnings;

sub RestoreDB {
	my($options, $state) = @_;
	
	my $db_file = App::SimpleBackuper::RegularFile->new($options->{db}, $options);
	print "Downloading database file from storage.\n" if ! $options->{quiet};
	
	$db_file->data_ref(\$state->{storage}->get('db')->[0]);
	
	print "Downloading database keys from storage.\n" if ! $options->{quiet};
	my $db_key = $state->{storage}->get('db.key')->[0];
	
	print "Decrypting database keys with RSA private key.\n" if ! $options->{quiet};
	$db_key = $state->{rsa}->decrypt($db_key);
	my($key, $iv) = unpack("a32a16", $db_key);
	
	print "Decrypting database with AES database keys.\n" if ! $options->{quiet};
	$db_file->decrypt($key, $iv);
	
	print "Saving database.\n" if ! $options->{quiet};
	$db_file->write();
}

1;
