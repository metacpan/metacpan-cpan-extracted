package Data::Radius::Util;

use v5.10;
use strict;
use warnings;
use Digest::MD5 ();

use Exporter qw(import);
our @EXPORT_OK = qw(encrypt_pwd decrypt_pwd is_enum_type);

my %ENUM_TYPES = map { $_ => 1 } (qw(integer byte short signed));

sub is_enum_type { $ENUM_TYPES{ $_[0] } ? 1 : 0 }

my $md5;

# encode User-Password attribute
sub encrypt_pwd {
    my ($value, $secret, $authenticator) = @_;

    $md5 //= Digest::MD5->new;

    # padding
    my $len = length($value);
    my $pad16 = $len % 16;
    $value .= "\x0" x (16 - $pad16) if($pad16);
    my @v = unpack('a16' x ( (16 + $len - $pad16) / 16), $value);

    my $ep = $authenticator;
    my @list = ();
    foreach my $p (@v) {
        $md5->add($secret, $ep);
        $ep = $p ^ $md5->digest();
        push @list, $ep;
    }

    return join('', @list);
}

# decrypt value of User-Password attribute
sub decrypt_pwd {
    my ($value, $secret, $authenticator) = @_;

    $md5 //= Digest::MD5->new;

    my $p = $authenticator;
    my $result;
    for (my $i = 0; $i < length($value); $i += 16) {
        $md5->add($secret, $p);
        $p = substr($value, $i, 16);
        $result .= $p ^ $md5->digest();
    }

    # clear padding
    $result =~ s/\000*$//;
    return $result;
}

1;
