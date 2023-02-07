use warnings;
use strict;

use Test::More;

use Crypt::Bcrypt qw/bcrypt bcrypt_check bcrypt_check_hashed/;

use MIME::Base64 'decode_base64';

sub de_base64($) {
	my($text) = @_;
	$text =~ tr#./A-Za-z0-9#A-Za-z0-9+/#;
	return decode_base64($text);
}

my @wrong_passwords = qw(foo quux supercalifragilisticexpialidocious);
while(<DATA>) {
	chomp;
	my ($settings, $hash, $password) = split ' ', $_;
	my ($type, $cost, $encoded_salt) = $settings =~ / ^ \$ (2\w?) \$ (\d+) \$ (.*) $ /x or die $settings;
	my $salt = de_base64($encoded_salt);
	is(bcrypt($password, $type, $cost, $salt), $settings.$hash);
	ok(bcrypt_check($password, $settings.$hash));
	foreach my $wrong_password (@wrong_passwords) {
		isnt(bcrypt($wrong_password, $type, $cost, $salt), $settings.$hash)
	}
}

ok(bcrypt_check_hashed('password', '$bcrypt-sha256$v=2,t=2b,r=12$n79VH.0Q2TMWmt3Oqt9uku$Kq4Noyk3094Y2QlB8NdRT8SvGiI4ft2'));
ok(bcrypt_check_hashed('password', '$bcrypt-sha256$v=2,t=2b,r=13$AmytCA45b12VeVg0YdDT3.$IZTbbJKgJlD5IJoCWhuDUqYjnJwNPlO'));

done_testing;

1;

__DATA__
$2a$05$CCCCCCCCCCCCCCCCCCCCC. E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW U*U
$2a$05$CCCCCCCCCCCCCCCCCCCCC. VGOzA784oUp/Z0DY336zx7pLYAy0lwK U*U*
$2a$05$XXXXXXXXXXXXXXXXXXXXXO AcXxm9kjPGEMsLznoKqmqw7tc8WCx4a U*U*U
$2a$05$CCCCCCCCCCCCCCCCCCCCC. 7uG0VCzI2bS7j6ymqJi9CdcdxiRTWNy 
$2a$05$abcdefghijklmnopqrstuu 5s2v8.iXieOjg/.AySBTTZIIVFJeBui 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
