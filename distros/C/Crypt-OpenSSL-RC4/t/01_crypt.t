use strict;
use warnings;
use Test::More tests => 10;
use Crypt::OpenSSL::RC4;

#
# test vectors are from:
#
#        Legion of The Bouncy Castle Java Crypto Libraries http://www.bouncycastle.org
# and    Crypto++ 3.2 http://www.eskimo.com/~weidai/cryptlib.html
#

{
    my $passphrase = pack('C*', (0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef));
    my $plaintext = pack('C*', (0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef));
    my $encrypted = RC4( $passphrase, $plaintext );
    my $decrypt = RC4( $passphrase, $encrypted );

    is $encrypted, pack( 'C*', ( 0x75, 0xb7, 0x87, 0x80, 0x99, 0xe0, 0xc5, 0x96 ) );
    is $decrypt, $plaintext;
}

{
    my $passphrase = pack('C*', (0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef));
    my $plaintext = pack('C*', (0x68,0x65,0x20,0x74,0x69,0x6d,0x65,0x20));
    my $encrypted = RC4( $passphrase, $plaintext );
    my $decrypt = RC4( $passphrase, $encrypted );

    is $encrypted, pack('C*', (0x1c,0xf1,0xe2,0x93,0x79,0x26,0x6d,0x59));
    is $decrypt, $plaintext;
}

{
    my $passphrase = pack('C*', (0xef,0x01,0x23,0x45));
    my $plaintext = pack('C*', (0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00));
    my $encrypted = RC4( $passphrase, $plaintext );
    my $decrypt = RC4( $passphrase, $encrypted );

    is $encrypted, pack('C*', (0xd6,0xa1,0x41,0xa7,0xec,0x3c,0x38,0xdf,0xbd,0x61));
    is $decrypt, $plaintext;
}

{
    # Checking that the OO interface maintains separate states
    my $message = RC4( "This is my passphrase", "looks good" );
    my $one     = Crypt::OpenSSL::RC4->new("This is my passphrase");
    my $two     = Crypt::OpenSSL::RC4->new("This is not my passphrase");
    is $one->RC4("looks good"), $message;
}

{
    # Checking that state is properly maintained
    my $one = Crypt::OpenSSL::RC4->new("This is my passphrase");

    # These two must be the same number of bytes
    my $message_one = $one->RC4("This is a message of precise length");
    my $message_two = $one->RC4("This is also a known-length message");
    my $two         = Crypt::OpenSSL::RC4->new("This is my passphrase");
    isnt $message_two, $two->RC4("This is also a known-length message");
    is $message_two, $two->RC4("This is also a known-length message");
}

{
    # Ensure that RC4 is not sensitive to chunking.
    my $message = "This is a message which may be encrypted in
                chunks, but which should give the same result nonetheless.";
    my $key       = "It's just a passphrase";
    my $encrypted = do {
        my $k = Crypt::OpenSSL::RC4->new($key);
        my @pieces = split /(?=\s+|(?!\n)\Z)/, $message;
        join "", map $k->RC4($_), @pieces;
    };
    my $failed;

    # Merely some various chunking sizes.
    for my $split_size ( 1, 4, 5, 10, 30, 9999 ) {
        my $k      = Crypt::OpenSSL::RC4->new($key);
        my @pieces = $message =~ /(.{1,$split_size})/sg;    # no /o!
        my $trial  = join "", map $k->RC4($_), @pieces;
        if ( $trial ne $encrypted ) {
            $failed = $split_size;
            last;
        }
    }
    print "# Failed at split=$failed\nnot " if $failed;
    ok(1);
}
