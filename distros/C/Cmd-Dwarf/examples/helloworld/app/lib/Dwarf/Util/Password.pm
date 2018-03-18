package Dwarf::Util::Password;
use Dwarf::Pragma;
use Digest::SHA qw(sha512);
use MIME::Base64;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_valid gen_hashed_password gen_password);

sub SECRET_STRING { 'Jesus Bellido professor of guitar making' }

# パスワードが正しいかどうか
sub is_valid {
	my ($hashed, $raw) = @_;
	my $salt = substr($hashed, 0, 4);
	return ($hashed eq gen_hashed_password($raw, $salt));
}

# パスワードのハッシュ化
sub gen_hashed_password {
	my ($password, $salt) = @_;
	$salt ||= gen_password(1, 4);
	return $salt . encode_base64(sha512($salt . $password . SECRET_STRING), '');
}

# パスワード生成 (0: 全て, 1: 英数字のみ, 2: 英字のみ, 3: 数字のみ)
sub gen_password {
	my ($type, $length) = @_;
	$type = 0 if not defined $type or $type !~ /^[0123]$/;
	$length ||= 10;

	my @num    = ('0' .. '9');
	my @alpha  = ('a' .. 'z', 'A' .. 'Z');
	my @symbol = (
		'!', '"',  '#', '$', '%', '&', "'", '(', ')', '*', '+', ',',  '-', '.', '/', ':', ';',
		'=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~'
	);

	my @chars;
	push @chars, @num    if $type != 2;
	push @chars, @alpha  if $type < 3;
	push @chars, @symbol if $type < 1;

	return join('', map { $chars[ int(rand(scalar @chars)) ] } (1 .. $length));
}

1;
