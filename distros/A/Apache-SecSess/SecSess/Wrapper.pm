#
# Wrapper.pm - data encryption-wrapper w/ strong checksum
#
# $Id: Wrapper.pm,v 1.6 2002/05/08 02:14:59 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess::Wrapper
# (c) 2001, 2002 John Pliam
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess::Wrapper;

use IO::File;
use MIME::Base64;
use Digest::MD5 qw(md5);
use Crypt::Rijndael;

$VERSION = sprintf("%d.%02d", q$Name: SecSess_Release_0_09 $ =~ /\d+/g);

sub new {
	my($class, $method, $keyarg) = @_;

	# derive key from argument
	my $key = $class->_initkey($method, $keyarg);
		
	# crunch key and instantiate cipher object
	my $cipher = Crypt::Rijndael->new(
		pack('a16 a16', md5('1'.$key), md5('2'.$key)),
		Crypt::Rijndael::MODE_CBC
	);
	return bless({cipher => $cipher}, $class);
}

#
# How to make the key from a key argument.  Two methods defined:
#	1. $class->new(key => 'passphrase') passes key directly
#	2. $class->new(file => 'filename') takes first line as key
#
sub _initkey {
	my $class = shift;
    my($method, $keyarg) = @_;
    my($fh, $key);

	if ($method eq 'key') { return $keyarg; }
	if ($method eq 'file') { 
        unless ($fh = IO::File->new($keyarg)) { die "Cannot open keyfile."; }
        chomp($key = <$fh>);
    	return $key;
    }
	return undef;
}

# wrap string
sub wrap {
	my $self = shift;
	my($m) = @_;
	my($l,$blk,$byt,$pad,$ct);

	# form plaintext record
	$l = length($m); 					# length of plaintext message
	$blk = int((length($m)+2-1)/16)+1;	# total blocks for rec. w/o digest
	$byt = 16*$blk-2;					# total bytes for message part
	$pad = $byt-$l;						# number of padding bytes
	$dig = md5($m);
	$pt = pack("a16 n a$l a$pad", $dig, $l, $m, $dig);

	# encrypt and encode
	$ct = encode_base64($self->{cipher}->encrypt($pt), '');
	$ct =~ tr/\+\/\=/-._/;
	return $ct;
}

# unwrap string, checking integrity
sub unwrap {
	my $self = shift;
	my($ct) = @_;
	my($pt,$dig,$l,$mm,$m);

	# decode and decrypt
	$ct =~ tr/\-\.\_/+\/=/;
	$pt = $self->{cipher}->decrypt(decode_base64($ct));
	($dig, $l, $mm) = unpack("a16 n a*", $pt);
    $m = unpack("a$l", $mm);

	# caller must check validity
	return (md5($m) eq $dig) ? $m : undef;
}

# wrap a hash "uniquely"
sub wraphash {
	my $self = shift;
	my($h) = @_;
	my(@k) = sort keys %$h;
	my($n) = scalar(@k);
	my($pk,@pk,$k,$v,$sv,$lk,$lv);

	# form pack command
	$pk = "w"; @pk = ($n);
	for $k (@k) {
		$v = $h->{$k}; $sv = "$v"; 
		$lk = length($k); $lv = length($sv);
		$pk .= " w a$lk w a$lv";
		push(@pk, $lk, $k, $lv, $sv);
	}

	# encrypt
	return $self->wrap(pack($pk, @pk));
}

# unwrap a hash
sub unwraphash {
	my $self = shift;
	my($ct) = @_;
	my($n,$pt,$h,$lk,$k,$lv,$v);

	unless (defined($pt = $self->unwrap($ct))) { return undef; }

	($n, $pt) = unpack("w a*", $pt);
	$h = {};
	for $i (1..$n) {
		($lk, $pt) = unpack("w a*", $pt);
		($k, $pt) = unpack("a$lk a*", $pt);
		($lv, $pt) = unpack("w a*", $pt);
		($v, $pt) = unpack("a$lv a*", $pt);
		$h->{$k} = $v;
	}

	return $h;
}

1;
