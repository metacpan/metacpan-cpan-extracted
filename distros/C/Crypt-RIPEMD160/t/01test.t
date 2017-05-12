#!perl

use strict;
use warnings;

use Test::More tests => 26;

use Crypt::RIPEMD160;
use Crypt::RIPEMD160::MAC;

my $ripemd160 = new Crypt::RIPEMD160;
isa_ok($ripemd160, 'Crypt::RIPEMD160');

my %data = (''  => '9c1185a5c5e9fc54612808977ee8f548b2258d31',
            'a' => '0bdc9d2d256b3ee9daae347be6f4dc835a467ffe',
          'abc' => '8eb208f7e05d987a9b044a8e98c6b087f15a0bfc',
          'message digest' => '5d0689ef49d2fae572b881b123a85ffa21595f36',
          'abcdefghijklmnopqrstuvwxyz' => 'f71c27109c692c1b56bbdceb5b9d2865b3708dbc',
          'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq' => '12a053384a9c0c88e405a06c27dcf49ada62eb2b'
          );

foreach my $key (sort(keys(%data)))
{
    $ripemd160->reset;
    $ripemd160->add($key);
    my $digest = $ripemd160->digest;
    my $hex = unpack("H*", $digest);
    is($hex, $data{$key}, "std-test-vectors");
}

# 4: "A...Za...z0...9"
{
    $ripemd160->reset;
    $ripemd160->add("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    $ripemd160->add("abcdefghijklmnopqrstuvwxyz");
    $ripemd160->add("01234");
    $ripemd160->add("56789");
    my $digest = $ripemd160->digest;
    my $hex = unpack("H*", $digest);
    is($hex, "b0e20b6e3116640286ed3a87a5713079b21f5189", '(A...Za...z0...9)');
}


# 5: adding 8 times "1234567890"
{
    $ripemd160->reset;
    for (1..8) {
	   $ripemd160->add("12345");
	   $ripemd160->add("67890");
    }
    my $digest = $ripemd160->digest;
    my $hex = unpack("H*", $digest);
    is($hex, "9b752e45573d4b39f4dbd3323cab82bf63326bfb", '8 x "1234567890"');
}



# 6: adding 1 million times a single "a"
{
    my ($million_a) = "a" x 1000000;
    $ripemd160->reset;
# Extreme slow version: 
    for (1..1000000) {
	   $ripemd160->add("a");
    }

    # Faster way...
#    $ripemd160->add($million_a);
    my $digest = $ripemd160->digest;
    my $hex = unpack("H*", $digest);
    is($hex, "52783243c1697bdbe16d37f97f68f08325dc1528", '1e6 x "a"');
}

# 7: Various flavours of file-handle to addfile
{
    open(F, "<$0");

    $ripemd160->reset;
    $ripemd160->addfile(*F);
    my $hex = $ripemd160->hexdigest;
    isnt($hex, '', 'Various flavours of file-handle to addfile - *F');
}

# 9: Fully qualified with :: operator
{
    seek(F, 0, 0);
    $ripemd160->reset;
    $ripemd160->addfile(*main::F);
    my $hex = $ripemd160->hexdigest;
    isnt($hex, '', 'Various flavours of file-handle to addfile - *main::F');
}

# 11: Type glob reference (the prefered mechanism)

{
    seek(F, 0, 0);
    $ripemd160->reset;
    $ripemd160->addfile(\*F);
    my $hex = $ripemd160->hexdigest;
    isnt($hex, '', 'Various flavours of file-handle to addfile - \\*F');
}

# 13: Other ways of reading the data -- line at a time

{
    seek(F, 0, 0);
    $ripemd160->reset;
    while (<F>) {
        $ripemd160->add($_);
    }
    my $hex = $ripemd160->hexdigest;
    isnt($hex, '', 'Other ways of reading the data -- line at a time');
}

# 14: Input lines as a list to add()
{
    seek(F, 0, 0);
    $ripemd160->reset;
    $ripemd160->add(<F>);
    my $hex = $ripemd160->hexdigest;
    isnt($hex, '', 'Input lines as a list to add()');
}

# 15: Random chunks up to 128 bytes

{
    seek(F, 0, 0);
    $ripemd160->reset;
    my $hexata;
    while (read(*F, $hexata, (rand % 128) + 1)) {
        $ripemd160->add($hexata);
    }
    my $hex = $ripemd160->hexdigest;
    isnt($hex, '', 'Random chunks up to 128 bytes');
}

# 16: All the data at once
{
    seek(F, 0, 0);
    $ripemd160->reset;
    undef $/;
    my $data = <F>;
    my $hex = $ripemd160->hexhash($data);
    print ($hex ne '' ? "" : "not ");
    isnt($hex, '', 'All the data at once');

    close(F);

# 17: Using static member function

    my $hex2 = Crypt::RIPEMD160->hexhash($data);
    isnt($hex2, '', 'Using static member function');
}

# Tests on raw data

test("24cb4bd6 7d20fc1a 5d2ed773 2dcc3937 7f0a5668", 
     chr(0x0b) x 20, 
     "Hi There");
    
test("dda6c021 3a485a9e 24f47420 64a7f033 b43c4069", 
     "Jefe",
     "what do ya want for nothing?");

test("b0b10536 0de75996 0ab4f352 98e116e2 95d8e7c1", 
     chr(0xaa) x 20,
     chr(0xdd) x 50);

test("d5ca862f 4d21d5e6 10e18b4c f1beb97a 4365ecf4", 
     chr(0x01).chr(0x02).chr(0x03).chr(0x04).chr(0x05).
     chr(0x06).chr(0x07).chr(0x08).chr(0x09).chr(0x0a).
     chr(0x0b).chr(0x0c).chr(0x0d).chr(0x0e).chr(0x0f).
     chr(0x10).chr(0x11).chr(0x12).chr(0x13).chr(0x14).
     chr(0x15).chr(0x16).chr(0x17).chr(0x18).chr(0x19),
     chr(0xcd) x 50);

test("76196939 78f91d90 539ae786 500ff3d8 e0518e39", 
     chr(0x0c) x 20,
     "Test With Truncation");

test("6466ca07 ac5eac29 e1bd523e 5ada7605 b791fd8b", 
     chr(0xaa) x 80,
     "Test Using Larger Than Block-Size Key - Hash Key First");

test("69ea6079 8d71616c ce5fd087 1e23754c d75d5a0a", 
     chr(0xaa) x 80,
     "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data");

test("69ea6079 8d71616c ce5fd087 1e23754c d75d5a0a", 
     chr(0xaa) x 80,
     "Test Using Lar", 
     "ger Than Block-Size K",
     "ey and Larger Than One Block-Size Dat",
     "a");

exit;

sub test {
    my($digest, $key, @data) = @_;

    my($mac) = new Crypt::RIPEMD160::MAC($key);
    $mac->add(@data);
    is($mac->hexmac(), $digest, 'Crypt::RIPEMD160::MAC std-test-vector from RFC2286');
}
