use Test::More;
use strict;
use warnings;
use FindBin;

use Crypt::CCM;
eval "use Crypt::Rijndael";
if ($@) {
    plan skip_all => 'Crypt::Rijndael not installed';
}
else {
    plan tests => 8;
}

while (defined(my $t = each_test_data())) {
    last if !exists $t->{K};
    my $c = Crypt::CCM->new(-key => $t->{K}, -cipher => 'Crypt::Rijndael');
    $c->set_tag_length($t->{TL}/8);
    $c->set_nonce($t->{N});
    $c->set_aad($t->{A});
    if ($t->{M} eq 'E') {
        my $ct = $c->encrypt($t->{PT});
        ok($ct eq $t->{CT});
    }
    else {
        my $pt = $c->decrypt($t->{CT});
        ok($pt eq $t->{PT});
    }
}

sub each_test_data {
    my %result;
    for (my $i = 0; $i < 7; $i++) {
        no warnings;
        my $l = scalar <DATA>;
        chomp $l;
        my ($key, $value) = split /\s+/, $l;
        $result{$key} = $value;
        next if $key eq 'M';
        next if $key eq 'TL';
        if ($value =~ /^file:(.+)/) {
            my $path = sprintf '%s/%s', $FindBin::Bin, $1;
            open my $f, $path or die $!;
            $result{$key} = '';
            while (read $f, my $buff, 1024*8) {
                $result{$key} .= $buff;
            }
            close $f;
        }
        else {
            $result{$key} = pack 'H*', $value;
        }
    }
    return undef if !exists $result{K};
    return \%result;
}

__DATA__
M  E
K  404142434445464748494a4b4c4d4e4f
TL 32
N  10111213141516
A  0001020304050607
PT 20212223
CT 7162015b4dac255d
M  D
K  404142434445464748494a4b4c4d4e4f
TL 32
N  10111213141516
A  0001020304050607
PT  20212223
CT  7162015b4dac255d
M  E
K  404142434445464748494a4b4c4d4e4f
TL 48
N  1011121314151617 
A  000102030405060708090a0b0c0d0e0f
PT 202122232425262728292a2b2c2d2e2f
CT d2a1f0e051ea5f62081a7792073d593d1fc64fbfaccd
M  D
K  404142434445464748494a4b4c4d4e4f
TL 48
N  1011121314151617 
A  000102030405060708090a0b0c0d0e0f
PT 202122232425262728292a2b2c2d2e2f
CT d2a1f0e051ea5f62081a7792073d593d1fc64fbfaccd
M  E
K  404142434445464748494a4b4c4d4e4f
TL 64
N  101112131415161718191a1b
A  000102030405060708090a0b0c0d0e0f10111213
PT 202122232425262728292a2b2c2d2e2f3031323334353637
CT e3b201a9f5b71a7a9b1ceaeccd97e70b6176aad9a4428aa5484392fbc1b09951
M  D
K  404142434445464748494a4b4c4d4e4f
TL 64
N  101112131415161718191a1b
A  000102030405060708090a0b0c0d0e0f10111213
PT 202122232425262728292a2b2c2d2e2f3031323334353637
CT e3b201a9f5b71a7a9b1ceaeccd97e70b6176aad9a4428aa5484392fbc1b09951
M  E
K  404142434445464748494a4b4c4d4e4f 
TL 112
N  101112131415161718191a1b1c
A  file:encrypt-ex4a.bin
PT 202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f
CT 69915dad1e84c6376a68c2967e4dab615ae0fd1faec44cc484828529463ccf72b4ac6bec93e8598e7f0dadbcea5b
M  D
K  404142434445464748494a4b4c4d4e4f 
TL 112
N  101112131415161718191a1b1c
A  file:encrypt-ex4a.bin
PT 202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f
CT 69915dad1e84c6376a68c2967e4dab615ae0fd1faec44cc484828529463ccf72b4ac6bec93e8598e7f0dadbcea5b
