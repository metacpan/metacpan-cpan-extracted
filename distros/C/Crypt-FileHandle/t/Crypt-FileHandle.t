# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-FileHandle.t'

#########################

use Test;
BEGIN { plan tests => 47 };
use Crypt::FileHandle;
ok(1);
$|=1;

############################################################

# inline package for testing a Crypt::CBC compatible cipher
# without the dependency of Crypt::CBC
{ 
	package CryptXOR;
	sub new {
		my $class = shift;
		my $self = bless({}, $class);
		# ensure non-zero
		$self->{'xor'} = chr(int(rand()*10) + 1);
		return $self;
	}
	sub start { return 1; }
	sub crypt {
		my $self = shift;
		my $data = shift;
		return undef if (! defined $data);
		my $xor = "";
		for (my $i = 0; $i < length($data); $i++) {
			my $ch = substr($data, $i, 1);
			$xor .= chr(ord($ch) ^ ord($self->{'xor'}));
		}
		return $xor;
	}
	sub finish { return ""; }
	sub xor {
		my $self = shift;
		return $self->{'xor'};
	}
	1;
}

############################################################

# temporary file (must have write access to test!)
my $filename = 'make_test.tmp';

# create test data
my @data;
push @data, "!";
push @data, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
push @data, "THIS IS A LINE.\r\n";
push @data, "THIS IS A ANOTHER LINE AT THE END OF THE FILE";
my $total_len = 0;
foreach (@data) {
	$total_len += length($_);
}

# create new random XOR cipher
my $cipher = CryptXOR->new();

# new / verify_cipher / readsize
my $fh = Crypt::FileHandle->new($cipher);
ok(Crypt::FileHandle->verify_cipher($cipher));
ok(Crypt::FileHandle->readsize() == 4096);
ok(Crypt::FileHandle->readsize(2048) == 2048);
ok($fh);

# OPEN
eval { open($fh, '>>', $filename); };
ok($@ =~ /^APPEND mode not supported/);
$@ = undef;

eval { open($fh, ">>$filename"); };
ok($@ =~ /^APPEND mode not supported/);
$@ = undef;

eval { open($fh, '+>', $filename); };
ok($@ =~ /^READ\/WRITE mode not supported/);
$@ = undef;

eval { open($fh, "+>$filename"); };
ok($@ =~ /^READ\/WRITE mode not supported/);
$@ = undef;

eval { open($fh, '+<', $filename); };
ok($@ =~ /^READ\/WRITE mode not supported/);
$@ = undef;

eval { open($fh, "+<$filename"); };
ok($@ =~ /^READ\/WRITE mode not supported/);
$@ = undef;

eval { open($fh); };
ok($@ =~ /^Use of uninitialized value in open/);
$@ = undef;

ok (! open($fh, $filename));

ok(open($fh, '>', $filename));
ok(binmode($fh));

# FILENO
ok(fileno($fh));

# PRINT / PRINTF / WRITE
ok(print $fh $data[0]);
ok(print $fh $data[1]);
ok(printf $fh "%s", $data[2]);
ok(syswrite($fh, $data[3]));

# TELL
ok(tell($fh) == $total_len);

# CLOSE / EOF
ok(close($fh));
ok(eof($fh));

# confirm data is "encrypted"
my $pfh = new FileHandle;
open($pfh, '<', $filename);
binmode($pfh);
foreach my $data (@data) {
	my $len = length($data);
	my $buf;
	sysread $pfh, $buf, $len;
	ok($len, length($buf));
	ok($data ne $buf);

	my $buf_xor = "";
	for (my $i = 0; $i < length($buf); $i++) {
		my $ch = substr($buf, $i, 1);
		$buf_xor .= chr(ord($ch) ^ ord($cipher->xor()));
	}
	ok($data eq $buf_xor);
}
close($pfh);

# OPEN
ok(open($fh, '<', $filename));
ok(binmode($fh));

# FILENO
ok(fileno($fh));

# GETC / READ / READLINE / <>
ok(getc($fh) eq $data[0]);
my $buf;
ok(sysread($fh, $buf, length($data[1])));
ok($buf eq $data[1]);
ok(readline($fh) eq $data[2]);
ok(<$fh> eq $data[3]);

# TELL
ok(tell($fh) == $total_len);

# EOF
ok(eof($fh));

# CLOSE / EOF
ok(close($fh));
ok(eof($fh));

# remove temporary file
unlink($filename);
