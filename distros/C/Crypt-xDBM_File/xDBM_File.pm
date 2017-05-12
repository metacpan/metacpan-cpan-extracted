package Crypt::xDBM_File;

use strict;
use vars qw($VERSION);

$VERSION = '1.02';

# Preloaded methods go here.

sub _encrypt_string {
    my ($self, $string, $block_size) = @_;
    my ($i, $len, $tmp_string, $crypt_string);

    $string .= "+"; # pad marker
    $len = $block_size - (length($string) % $block_size);
    if ($len != $block_size) {
      $string .= "\0" x $len;
    }
    $len = length($string);
    $crypt_string = "";
    for ($i=0; $i < $len; $i += $block_size) {
	$tmp_string = $self->{'cipher'}->encrypt(substr($string, 
							$i, $block_size));
	$crypt_string .= $tmp_string;
    }
    return $crypt_string;
}

sub _decrypt_string { # should already be padded to block size
    my ($self, $crypted_string, $block_size) = @_;
    my ($i, $len, $tmp_string, $string);

    $len = length($crypted_string);
    $string = "";
    for ($i=0; $i < $len; $i += $block_size) {
	$tmp_string = $self->{'cipher'}->decrypt(substr($crypted_string, 
							$i, $block_size));
	$string .= $tmp_string;
    }
    return (substr($string, 0, rindex($string, "+")));
}

sub TIEHASH { # associate hash variable to these routines
    my ($pkg) = shift @_;
    my $self = {};

    $self->{'crypt_method'} = shift @_;
    $self->{'key'} = shift @_;

    $self->{'key_pad'} = keysize {$self->{'crypt_method'}};
    if ($self->{'key_pad'} == 0) { # pad to 8 byte boundary by default
   	$self->{'key_pad'} = 8;
    }
    $self->{'block_pad'} = blocksize {$self->{'crypt_method'}};
    if ($self->{'block_pad'} == 0) { # pad to 8 byte boundary by default
   	$self->{'block_pad'} = 8;
    }
#    print "key_pad = [$self->{'key_pad'}]\n";
#    print "block_pad = [$self->{'block_pad'}]\n";
#    print "crypt method [$self->{'crypt_method'}], key [$self->{'key'}]\n";

    my $len = length($self->{'key'}) % $self->{'key_pad'};
    $self->{'key'} .= ' ' x ($self->{'key_pad'} - $len);
    $self->{'key'} = substr($self->{'key'}, 0, $self->{'key_pad'});
    $self->{'cipher'} = new {$self->{'crypt_method'}} $self->{'key'};
    tie %{$self->{'localhash'}}, shift @_, @_;
    return (bless $self, $pkg);
}

sub FETCH { # get an encrypted item and decrypt it
    my ($self, $key) = @_;
    my $crypted_key = $self->_encrypt_string($key, $self->{'block_pad'});
    my $crypted_value = $self->{'localhash'}{$crypted_key};
    if (defined($crypted_value)) {
	return ($self->_decrypt_string($crypted_value, $self->{'block_pad'}));
    } else {
	return;
    }
}

sub STORE { # get an encrypted item and decrypt it
    my ($self, $key, $value) = @_; 
    my $crypted_key = $self->_encrypt_string($key, $self->{'block_pad'});
    my $crypted_value = $self->_encrypt_string($value, $self->{'block_pad'});
    return ($self->{'localhash'}{$crypted_key} = $crypted_value);
}

sub DELETE { # delete an item
    my ($self, $key) = @_;
    my $crypted_key = $self->_encrypt_string($key, $self->{'block_pad'});

    return (delete $self->{'localhash'}{$crypted_key});
}

sub EXISTS { # does it exist
    my ($self, $key) = @_;
    my $crypted_key = $self->_encrypt_string($key, $self->{'block_pad'});

    return (exists $self->{'localhash'}{$crypted_key});
}

sub FIRSTKEY { # first key request
    my $self = shift;
    my ($key, $crypted_key);

    keys(%{$self->{'localhash'}}); # reset eachness 
    return($self->NEXTKEY());
}

sub NEXTKEY {
    my $self = shift;
    my $crypted_key = each (%{$self->{'localhash'}});
    if (defined $crypted_key) {
	return ($self->_decrypt_string($crypted_key, $self->{'block_pad'}));
    } else {
	return;
    }
}

sub CLEAR {
    my $self = shift;
    return ($self->{'localhash'} = ());
}

sub DESTROY {
    my $self = shift;
    return (untie %{$self->{'localhash'}});
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Crypt::xDBM_File - encrypt almost any kind of dbm file

=head1 SYNOPSIS

 use Crypt::xDBM_File;
 use GDBM_File; # remember to only load those you really want
 use SDBM_File;
 use NDBM_File;
 use Fcntl; # neede by SDBM_File and NDBM_File
 
 tie %hash, 'Crypt::xDBM_File', crypt_method, key, 'GDBM_FILE', $filename, &GDBM_WRCREAT, 0640;

 tie %hash, 'Crypt::xDBM_File', 'IDEA', "my_key", 'NDBM_FILE', $filename, O_RDWR|O_CREAT, 0640;

 tie %hash, 'Crypt::xDBM_File', 'DES', "my_key", 'SDBM_FILE', $filename, O_RDWR|O_CREAT, 0640;

 tie %hash, 'Crypt::xDBM_File', 'Crypt::Blowfish', "my key", 'GDBM_FILE', $filename, &GDBM_WRCREAT, 0640;

=head1 DESCRIPTION

Crypt::xDBM_File encrypts/decrypts the data in a gdbm,ndbm,sdbm (and maybe even berkeleyDB, but I didn't test that) file.  It gets tied to a hash and you just access the hash like normal.  The crypt function can be any of the CPAN modules that use encrypt, decrypt, keysize, blocksize (so Crypt::IDEA, Crypt::DES, Crypt::Blowfish, ... should all work)

You can in a single dbm file mix encryption methods, just be prepared to handle the binary muck that you get from trying to decrypt with an algorithm different from the one a key was originally encrypted in (for example if you do a keys or values, you'll get all of the keys regardless of who encrypted them).

***IMPORTANT***
Encryption keys (the key you pass in on the tie line) will be padded or truncated to fit the keysize().  Data (the key/values of the hash) is padded to fill complete blocks of blocksize().  The padding is stripped before being returned to the user so you shouldn't need to worry about it (except truncated keys).  Read the doc that comes with crypt function to get an idea of what these sizes are.  If keysize or blocksize returns a zero the default is set to 8 bytes (64 bits).

=head1 AUTHOR

Eric Estabrooks, eric@urbanrage.com

=head1 SEE ALSO

perl(1).

=cut
