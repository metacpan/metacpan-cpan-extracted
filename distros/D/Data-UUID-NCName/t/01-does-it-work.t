#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;

our @UUIDS;

BEGIN {
    my $obj;
    my $gen = sub {};
    eval { require OSSP::uuid };
    if ($@) {
        local $@;
        eval { require Data::UUID };
        if ($@) {
            my $x = `uuidgen`;
            if ($? == 0) {
                $gen = sub { chomp(my $x = `uuidgen`) };
            }
            else {
                plan skip_all => 'Require something that generates UUIDs';
                exit;
            }
        }
        else {
            $obj = Data::UUID->new;
            $gen = sub { lc $obj->create_str };
        }
    }
    else {
        $obj = OSSP::uuid->new;
        $gen = sub { $obj->make('v4'); $obj->export('str') };
    }

    for my $i (1..100) {
        push @UUIDS, $gen->();
    }
}

plan tests => 4 * @UUIDS + 6;

use_ok('Data::UUID::NCName', ':all');

# EXPECTED OUTPUTS

my $z64 = to_ncname_64('00000000-0000-0000-0000-000000000000');
my $z32 = to_ncname_32('00000000-0000-0000-0000-000000000000');

is($z64, 'AAAAAAAAAAAAAAAAAAAAAA',     'Null64 UUID OK');
is($z32, 'Aaaaaaaaaaaaaaaaaaaaaaaaaa', 'Null32 UUID OK');

my $f64 = to_ncname_64('ffffffff-ffff-ffff-ffff-ffffffffffff');
my $f32 = to_ncname_32('ffffffff-ffff-ffff-ffff-ffffffffffff');

#diag('E' . MIME::Base64::encode_base64url(pack 'C*', (255) x 15, 15 << 2));

is($f64, 'P____________________P',     'FF64 UUID OK');
is($f32, 'P777777777777777777777777p', 'FF32 UUID OK');

my $f064 = to_ncname_64('ffffffff-ffff-4fff-ffff-fffffffffff0');
my $z064 = to_ncname_64('00000000-0000-4000-0000-00000000000f');

#my $lint = substr
#    MIME::Base64::encode_base64url(pack 'C*', (0) x 15, 0xf << 2), 0, 21;

#diag(MIME::Base64::encode_base64url(pack 'C*', 0b00001111));
#diag(MIME::Base64::encode_base64url(pack 'C*', 0b00111100));
#diag(MIME::Base64::encode_base64url(pack 'C*', 0b11110000));

#diag(unpack 'H*', MIME::Base64::decode_base64url('8PA'));

# D    w
# 0x03 0x30

#diag("E$lint");

is($f064, 'E____________________A', 'F064 ends with A');

#diag($f064);
#diag($z064);

# FUZZ TESTING

for my $uu (@UUIDS) {
    #diag($uu);
    mooltipass($uu);
}

sub mooltipass {
    my $uuid = shift;

    my $ncn64 = Data::UUID::NCName::to_ncname($uuid);
    my $ncn32 = Data::UUID::NCName::to_ncname($uuid, 32);

    #diag($ncn64);
    is(length $ncn64, 22, "Base64 NCName is 22 characters long");

    my $uu64 = Data::UUID::NCName::from_ncname_64($ncn64);
    is($uu64, $uuid, 'Base64 content matches original UUID');

    #diag($ncn32);
    is(length $ncn32, 26, "Base32 NCName is 26 characters long");

    my $uu32 = Data::UUID::NCName::from_ncname_32($ncn32);
    is($uu32, $uuid, 'Base32 content matches original UUID');

}

#diag(to_ncname('00000000-0000-4000-0000-00000000000f'));
#diag(from_ncname('EAAAAAAAAAAAAAAAAAAAAP'));
