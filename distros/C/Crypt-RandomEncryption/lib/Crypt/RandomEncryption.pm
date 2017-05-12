package Crypt::RandomEncryption;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub _packit
{
        shift;
        my $phrase=shift;
        return pack("H*",$phrase);
}

sub _unpackit
{
        shift;
        my $phrase=shift;
        return unpack("H*",$phrase);
}

sub _random
{
        shift;
        my @range=('a'..'z', 'A'..'Z', 0..9);
        return $range[rand($#range+1)];
}

sub _RC4 {
        shift;
        my($plaintext, $key) = @_;
        
        my $keylen = length($key);
        my @keyarray;
        for(my $i=0; $i<=255; $i++) {
                $keyarray[$i]=ord(substr($key,($i % $keylen)+1, 1));
        }
        my @asciiarray;
        for(my $i=0; $i<=255; $i++) {
                $asciiarray[$i] = $i;
        }
        my $j=0;
        for(my $i=0; $i<=255; $i++) {
                $j=($j + $asciiarray[$i] + $keyarray[$i]) % 256;
                ($asciiarray[$i], $asciiarray[$j])=($asciiarray[$j], $asciiarray[$i]);
        }
        my $i=0;
        $j=0;
        my $t;
        my $y;
        my $RC4;
        for (my $x = 0; $x < length($plaintext); $x++) {
                $i=($i + 1) % 256;
                $j=($j + $asciiarray[$i])%256;
                $t = ($asciiarray[$i] + $asciiarray[$j]) % 256;
                ($asciiarray[$i], $asciiarray[$j])=($asciiarray[$j], $asciiarray[$i]);
                $y = $asciiarray[$t];
                $RC4=$RC4 . chr(ord(substr($plaintext, $x, 1))^$y);
        }
        return $RC4;
}

sub encrypt
{
        my $class=shift;
        my ($item, $key, $level)=@_;

        unless($level) { $level=1; }
        $item=$class->_unpackit($class->_RC4($item, $key));
        my @items=split(//, $item);

        my @bet;
        for(my $j=0; $j < $level; $j++) {
                for(my $i=0; $i <= $#items; $i++) {
                        my $r=$class->_random();
                        push(@bet, ($r, $items[$i]));
                        if($i == $#items) {
                                push(@bet, $r);
                        }
                }
                @items=@bet;
                @bet=();
        }
        my $bet=join('', @items);
        my $final=$class->_unpackit($class->_RC4($bet, $key));
        
        return $final;
}

sub decrypt
{
        my $class=shift;
        my ($encrypted, $key, $level)=@_;

        unless($level) { $level=1; }
        my $first=$class->_RC4($class->_packit($encrypted),$key);
        my @items=split(//, $first);

        my @bet;
        for(my $j=0; $j < $level; $j++) {
                for(my $i=1; $i <= $#items; $i=$i+2) {
                        push(@bet, $items[$i]);
                }
                @items=@bet;
                @bet=();
        }
        my $bet=join('', @items);
        my $plain=$class->_RC4($class->_packit($bet),$key);
        
        return $plain;
}

1;


__END__
# Author: Vipin Singh

=head1 NAME

Crypt::RandomEncryption - Use to generate random encrypted code. And even can decrypt the same.

=head1 SYNOPSIS

	use Crypt::RandomEncryption;
	my $rp=new Crypt::RandomEncryption;

	my $text="Hello World 123"; #this is the text to encrypt
	my $key="secret";  #this is the secret key
	my $level=5;  #this is the depth of encryption

	my $e=$rp->encrypt($text, $key, $level);

	print "$e\n";

	my $d=$rp->decrypt($e, $key, $level);
	print "$d\n";

=head1 DESCRIPTION

This module generate random encrypted code. And can decrypt the code using same key and level.

Here, level define the depth of encryption(minimum is 0). Depth of encryption is directly proportional to length of encryption code and delay in generation the code.

This, module is written above RC4 algorithm.

=over 4

=item encrypt()
Need to pass three parameters, plain text, key and level.

=item decrypt()
Need to pass three parameters, encrypted code(encrypted using the encrypt() function), key(same used for encryption) and level(same passed while encryption).

=back

=head1 SEE ALSO

To know more on RC4 algorithm see, http://en.wikipedia.org/wiki/RC4 .

=head1 AUTHOR

Vipin Singh, E<lt>qwer@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Vipin Singh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
