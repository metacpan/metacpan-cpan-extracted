package Crypt::OFB;

########################################
# general module startup things
########################################

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;

use Crypt::ECB;

@ISA=qw(Crypt::ECB);

@EXPORT_OK = qw(encrypt decrypt encrypt_hex decrypt_hex);

$VERSION   = 0.01;

########################################
# basic methods
########################################

#
# sets iv if given
# returns iv
#
sub iv (\$;$)
{
    my $crypt = shift;
    $crypt->{Iv} = shift if @_;
    return $crypt->{Iv};
}

#
# calls the crypting module
# returns the en-/decrypted data
#
sub crypt (\$;$)
{
    my $crypt = shift;
    my $data  = shift || $_ || '';

    my $errmsg = $crypt->{Errstring};
    my $bs     = $crypt->{Blocksize};
    my $mode   = $crypt->{Mode};

    die $errmsg if $errmsg;

    unless ($mode)
    {
	die "You tried to use crypt() without calling start()"
	  . " before. Use '\$your_obj->start(\$mode)' first,"
	  . " \$mode being one of 'decrypt' or 'encrypt'.\n";
    }

    $data = $crypt->{buffer}.$data;

    # data is split into blocks of proper size which is reported
    # by the cipher module
    my @blocks = $data=~/(.{1,$bs})/gs;

    $crypt->{buffer} = pop @blocks;

    my $cipher = $crypt->_getcipher;
    my $text = '';

    # OFB Implementation here.
    my $skey = $crypt->iv;
    foreach my $block (@blocks) {
	$skey  = $cipher->encrypt($skey);
	$text .= $block ^ $skey;
    }
    #
    return $text;
}

########################################
# convenience functions/methods
########################################

#
# magic convenience encrypt function/method
#
sub encrypt ($$;$$)
{
    if (ref($_[0]) =~ /^Crypt/)
    {
	my $crypt = shift;

	$crypt->start('encrypt') || die $crypt->errstring;

	my $text = $crypt->crypt(shift)
	         . $crypt->finish;

	return $text;
    }
    else
    {
	my ($key, $cipher, $data, $padstyle) = @_;

	my $crypt = Crypt::OFB->new($key);

	$crypt->padding($padstyle || 0);
	$crypt->cipher($cipher)  || die $crypt->errstring;
	$crypt->start('encrypt') || die $crypt->errstring;

	my $text = $crypt->crypt($data || $_)
	         . $crypt->finish;

	return $text;
    }
}

#
# magic convenience decrypt function/method
#
sub decrypt ($$;$$)
{
    if (ref($_[0]) =~ /^Crypt/)
    {
	my $crypt = shift;

	$crypt->start('decrypt') || die $crypt->errstring;

	my $text = $crypt->crypt(shift)
	         . $crypt->finish;

	return $text;
    }
    else
    {
	my ($key, $cipher, $data, $padstyle) = @_;

	my $crypt = Crypt::OFB->new($key);

	$crypt->padding($padstyle || 0);
	$crypt->cipher($cipher)  || die $crypt->errstring;
	$crypt->start('decrypt') || die $crypt->errstring;

	my $text = $crypt->crypt($data || $_)
	         . $crypt->finish;

	return $text;
    }
}

#
# calls encrypt, returns hex packed data
#
sub encrypt_hex ($$;$$)
{
    if (ref($_[0]) =~ /^Crypt/)
    {
	my $crypt = shift;
	join('',unpack('H*',$crypt->encrypt(shift)));
    }
    else
    {
	join('',unpack('H*',encrypt($_[0], $_[1], $_[2], $_[3])));
    }
}

#
# calls decrypt, expected input is hex packed
#
sub decrypt_hex ($$;$$)
{
    if (ref($_[0]) =~ /^Crypt/)
    {
	my $crypt = shift;
	$crypt->decrypt(pack('H*',shift));
    }
    else
    {
	decrypt($_[0], $_[1], pack('H*',$_[2]), $_[3]);
    }
}


########################################
# finally, to satisfy require
########################################

1;
__END__


=head1 NAME

Crypt::OFB - Encrypt Data using OFB Mode

=head1 SYNOPSIS

Use Crypt::OFB OO style

  use Crypt::OFB;

  $crypt = Crypt::OFB->new;
  $crypt->padding(PADDING_AUTO);
  $crypt->cipher("Blowfish") || die $crypt->errstring;
  $crypt->key("some_key"); 

  $enc = $crypt->encrypt("Some data.");
  print $crypt->decrypt($enc);

=head1 DESCRIPTION

This module is a Perl-only implementation of the OFB mode.
It is a inheritance class of B<Crypt::ECB>. 
Please read Crypt::ECB(3) for the default function description.

=head1 COPYING

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>.

=head1 SEE ALSO

perl(1), Crypt::DES(3), Crypt::IDEA(3), Crypt::CBC(3), Crypt::ECB(3)

=cut
