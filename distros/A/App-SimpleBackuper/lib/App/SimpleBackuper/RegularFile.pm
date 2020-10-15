package App::SimpleBackuper::RegularFile;

use strict;
use warnings;
use Fcntl qw(:DEFAULT :flock);
use Carp;

sub new {
	my($class, $filepath, $options, $state) = @_;
	
	confess "No filepath" if ! $filepath;
	
	my $self = bless {
		options	=> $options,
		state	=> $state,
		filepath=> $filepath,
		readable=> 1,
		writable=> 0,
		offset	=> 0,
	} => $class;
	
	my($handler);
	eval { sysopen($handler, $filepath, O_RDONLY) // die "$!\n" };
	if($@) {
		if($!{ENOENT}) {
			$self->{readable} = 0;
		} else {
			die "$@\n";
		}
	}
	$self->{handler} = $handler;
	
	return $self;
}

sub set_write_mode {
	my($self) = @_;
	return if $self->{writable};
	
	sysopen(my $handler, $self->{filepath}, O_RDWR|O_CREAT) or die "$!\n";
	flock($handler, LOCK_EX|LOCK_NB) or die "$!\n";
	$self->{writable} = 1;
	$self->{handler} = $handler;
	sysseek($handler, $self->{offset}, 0) // die "$!\n";
}

sub _num2offset { ! $_[0] ? 0 : $_[0] < 3 ? 10 ** ($_[0] - 1) * 1e6 : ($_[0] - 2) * 100e6 }

sub read {
	my($self, $num) = @_;
	
	confess "File '$self->{filepath}' doesn't exists" if ! $self->{readable};
	
	$self->{data} = '';
	if(! defined $num) {
		my $read = sysread($self->{handler}, $self->{data}, -s $self->{filepath}) // die "$!\n";
		#printf "\t%d bytes of whole file '$self->{filepath}' read\n", $read;
		$self->{offset} += $read;
		return !! $read;
	} else {
		# Parts: 0-1M, 1M-10M, 10M-100M, 100M-200M, 200M-300M,..
		
		my $offset = _num2offset($num);
		my $length = _num2offset($num + 1) - $offset;
		
		sysseek($self->{handler}, $offset, 0) // die "$!\n";
		my $read = sysread($self->{handler}, $self->{data}, $length) // die "$!\n";
		#printf "\t%d bytes of %d bytes from %d offset of part #%d read\n", $read, $length, $offset, $num;
		
		$self->{offset} += $read;
		return $read;
	}
}

sub write {
	my($self, $num) = @_;
	
	$self->set_write_mode();
	
	if(! defined $num) {
		# TODO: замерить время FS
		syswrite($self->{handler}, $self->{data}) // die "$!\n";
		
		#printf "\t%d bytes written to %s\n", length( $self->{data} ), $self->{filepath};
		$self->{offset} += length $self->{data};
	} else {
		my $offset = _num2offset($num);
		my $length = _num2offset($num + 1) - $offset;
		sysseek($self->{handler}, $offset, 0) // die "$!\n";
		
		syswrite($self->{handler}, $self->{data}) // die "$!\n";
		#printf "\t%d bytes written to part #%d of %s\n", length( $self->{data} ), $num, $self->{filepath};
		
		$self->{offset} = $offset + $length;
	}
}

use Digest::SHA qw(sha512_hex); # apt install libdigest-sha-perl
sub hash {
	my($self) = @_;
	my $hash = sha512_hex($self->{data});
	#printf "\tsha512 is %s\n", $hash;
	return $hash;
}

use Compress::Raw::Lzma; # apt install libcompress-raw-lzma-perl
sub compress {
	my($self) = @_;
	
	my($z, $status) = Compress::Raw::Lzma::EasyEncoder->new(
		Preset			=> $self->{options}->{compression_level},
		Check			=> LZMA_CHECK_SHA256,
		AppendOutput	=>1,
	);
	die "$status\n" if $status != LZMA_OK;
	
	$status = $z->code($self->{data}, my $out);
	die "$status\n" if $status != LZMA_OK;
	
	$status = $z->flush($out);
	die "$status\n" if $status != LZMA_STREAM_END;
	
	my $ratio = length($out) / length($self->{data});
	$self->{data} = $out;
	
	return $ratio;
}

sub decompress {
	my($self) = @_;
	
	my($z, $status) = Compress::Raw::Lzma::AutoDecoder->new();
	die "$status\n" if $status != LZMA_OK;
	
	$status = $z->code($self->{data}, my $out);
	confess $status if $status != LZMA_STREAM_END;
	
	my $ratio = length($self->{data}) / length($out);
	$self->{data} = $out;
	
	return $ratio;
}

# key, iv
sub gen_keys { pack("C32", map {int rand 256} 1..32), pack("C16", map {int rand 256} 1..16) }

use Crypt::Rijndael; # apt install libcrypt-rijndael-perl
srand(time ^ $$ ^ (unpack("%L*", `head /dev/urandom`) * unpack("%L*", `head /dev/urandom`))); # For randomness
sub encrypt {
	my($self, $key, $iv) = @_;
	
	my $cipher = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());
	$cipher->set_iv($iv);
	
	$self->{data} = $cipher->encrypt($self->{data}
		. "\0" x (length($self->{data}) % length($key) ? length($key) - length($self->{data}) % length($key) : 0)
	) # aligning data for crypt. decompressor ignores it.
	;
	
	return;
}

sub decrypt {
	my($self, $key, $iv) = @_;
	
	my $cipher = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());
	$cipher->set_iv($iv);
	
	$self->{data} = $cipher->decrypt($self->{data});
	
	return;
}

sub size { length shift->{data} }

sub data_ref {
	my $self = shift;
	if(@_) {
		$self->{data} = shift;
		confess if ref($self->{data}) ne 'SCALAR';
		$self->{data} = ${ $self->{data} };
		return $self;
	} else {
		return \$self->{data};
	}
}

sub truncate {
	my($self, $size) = @_;
	$self->set_write_mode();
	truncate($self->{handler}, $size) // die "$!\n";
	return $self;
}

1;
