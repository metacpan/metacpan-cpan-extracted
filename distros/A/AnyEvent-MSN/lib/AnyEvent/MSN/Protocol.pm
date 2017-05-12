package AnyEvent::MSN::Protocol;
{ $AnyEvent::MSN::Protocol::VERSION = 0.002 }
use 5.012;
use AnyEvent;
use MIME::Base64 qw[];
use Digest::HMAC qw[hmac];
use Digest::SHA qw[];
use Digest::MD5 qw[];
use Crypt::CBC qw[];

sub anyevent_read_type {
    my ($handle, $s) = @_;
    sub {
        return if !length $handle->{rbuf};
        $handle->{rbuf} =~ s[^([^\015\012]*)\015?\012][] or return;
        my $line = $1;
        AnyEvent::MSN::DEBUG() && warn 'I: ' . $line;
        $s->(split qr[\s+], $line);    # my ($cmd, $tid, @data)
        $handle->push_read(__PACKAGE__, $s);    # Re-queue
        return 1                                # But remove this one
        }
}

sub anyevent_write_type {    # XXX - Currently... not... right.
    my ($handle, @args) = @_;
    my $out = sprintf shift(@args), grep {defined} @args;
    AnyEvent::MSN::DEBUG() && warn 'O: ' . $out;
    return $out . ($out =~ m[^(QRY|UUX|ADL|PUT|SDG)] ? '' : "\015\012");
}

sub __parse_msn_headers {
    state $hp //= sub {
        map { split qr[\s*:\s*], $_, 2 }
            split qr[\015?\012],
            shift;
    };
    my ($h1, $h2, $h3, $body) = split qr[\015?\012\015?\012], shift, 4;
    ({map { $hp->($_) }
      grep { defined && length } $h1, $h2, $h3
     },
     $body
    );
}

# Auth stuff
sub derive_key {
    my ($key, $magic) = @_;
    $magic = 'WS-SecureConversationSESSION KEY ' . $magic;
    my $hash1 = hmac($magic,          $key, \&Digest::SHA::sha1);
    my $hash2 = hmac($hash1 . $magic, $key, \&Digest::SHA::sha1);
    my $hash3 = hmac($hash1,          $key, \&Digest::SHA::sha1);
    my $hash4 = hmac($hash3 . $magic, $key, \&Digest::SHA::sha1);
    my $derived_key = $hash2;
    $derived_key .= substr($hash4, 0, 4);
    return $derived_key;
}

sub SSO {
    my ($nonce, $secret, $iv) = @_;

    # 1. Base64 decode binary secret
    my $key1 = MIME::Base64::decode_base64($secret);

    # 2a. key2 and key3
    my $key2 = derive_key($key1, 'HASH');
    my $key3 = derive_key($key1, 'ENCRYPTION');

    # 3. hash
    my $hash = Digest::HMAC::hmac($nonce, $key2, \&Digest::SHA::sha1);

    # 4. Pad nonce with 8 bytes of \08
    my $p_nonce = $nonce . (chr(8) x 8);

    # 5. Create 8 bytes of random data as iv
    $iv //= Crypt::CBC->random_bytes(8);

    # 6. TripleDES CBC encryption
    my $encrypted_data =
        Crypt::CBC->new(-literal_key => 1,
                        -key         => $key3,
                        -iv          => $iv,
                        -header      => 'none',
                        -cipher      => 'Crypt::DES_EDE3'
        )->encrypt($p_nonce);

    # 7. Fill in the struct
    my $struct = pack 'I7 A8 A20 A72', 28, 1, 0x6603, 0x8004, 8, 20, 72,
        $iv,
        $hash, $encrypted_data;

    # 8 Base64 encode struct
    MIME::Base64::encode_base64($struct, '');
}

# This piece of code was written by Siebe Tolsma (Copyright 2004, 2005).
sub CreateQRYHash {
    use Math::BigInt;    # Only locally
    my ($chldata, $prodid, $prodkey) = @_;

 # Create an MD5 hash out of the given data, then form 32 bit integers from it
    my @md5hash = unpack("a16a16", Digest::MD5::md5_hex("$chldata$prodkey"));
    my @md5parts = MD5HashToInt("$md5hash[0]$md5hash[1]");

# Then create a valid productid string, divisable by 8, then form 32 bit integers from it
    my @chlprodid = CHLProdToInt(
             "$chldata$prodid" . ("0" x (8 - length("$chldata$prodid") % 8)));

    # Create the key we need to XOR
    my $key = KeyFromInt(@md5parts, @chlprodid);

    # Take the MD5 hash and split it in two parts and XOR them
    my $low
        = substr(Math::BigInt->new("0x$md5hash[0]")->bxor($key)->as_hex(), 2);
    my $high
        = substr(Math::BigInt->new("0x$md5hash[1]")->bxor($key)->as_hex(), 2);

    # Return the string, make sure both parts are padded though if needed
    return
          ('0' x (16 - length($low)))
        . $low
        . ('0' x (16 - length($high)))
        . $high;
}

sub KeyFromInt {

    # We take it the first 4 integers are from the MD5 Hash
    my @md5 = splice(@_, 0, 4);
    my @chlprod = @_;

    # Create a new series of numbers
    my $key_temp = Math::BigInt->new(0);
    my $key_high = Math::BigInt->new(0);
    my $key_low  = Math::BigInt->new(0);

    # Then loop on the entries in the second array we got in the parameters
    for (my $i = 0; $i < scalar(@chlprod); $i += 2) {

# Make $key_temp zero again and perform calculation as described in the documents
        $key_temp->bzero()->badd($chlprod[$i])->bmul(0x0E79A9C1)
            ->bmod(0x7FFFFFFF)->badd($key_high);
        $key_temp->bmul($md5[0])->badd($md5[1])->bmod(0x7FFFFFFF);

        # So, when that is done, work on the $key_high value :)
        $key_high->bzero()->badd($chlprod[$i + 1])->badd($key_temp)
            ->bmod(0x7FFFFFFF);
        $key_high->bmul($md5[2])->badd($md5[3])->bmod(0x7FFFFFFF);

        # And add the two parts to the low value of the key
        $key_low->badd($key_temp)->badd($key_high);
    }

    # At the end of the loop we should add the dwords and modulo again
    $key_high->badd($md5[1])->bmod(0x7FFFFFFF);
    $key_low->badd($md5[3])->bmod(0x7FFFFFFF);

# Byteswap the keys, left shift (32) the high value and then add the low value
    $key_low  = unpack("I*", reverse(pack("I*", $key_low)));
    $key_high = unpack("I*", reverse(pack("I*", $key_high)));
    return $key_temp->bzero()->badd($key_high)->blsft(32)->badd($key_low);
}

# Takes an CHLData + ProdID + Padded string and chops it in 4 bytes. Then converts to 32 bit integers
sub CHLProdToInt {
    return
        map { unpack("I*", $_) } unpack(("a4" x (length($_[0]) / 4)), $_[0]);
}

# Takes an MD5 string and chops it in 4. Then "decodes" the HEX and converts to 32 bit integers. After that it ANDs
sub MD5HashToInt {
    return
        map { unpack("I*", pack("H*", $_)) & 0x7FFFFFFF }
        unpack(("a8" x 4), $_[0]);
}

sub capabilities {

    # http://msnpiki.msnfanatic.com/index.php/MSNC:Client_Capabilities
    my $s = shift;

# 0x01(CapabilityMobileOnline): This means you are running a Windows Mobile device. The official client changes the little icon to a little man with a phone, and puts the status 'Phone' next to your name.
# 0x02(CapabilityMSN8User): This value is set if you are a MSN Explorer 8 user, but it is sometimes used when the client resets its capabilities
# 0x04(CapabilityRendersGif): Your client can send/receive Ink (GIF format)
# 0x08(CapabilityRendersIsf): Your client can send/recieve Ink (ISF format)
# 0x10(CapabilityWebCamDetected): This option is set when you are able to participate in video conversations. In reality, it is only set when you have a webcam connected and have it set to 'shared'.
# 0x20(CapabilitySupportsChunking): This value is being used with Multi-Packet Messaging.
# 0x40(CapabilityMobileEnabled): This is used when the client is running on a MSN Mobile device. This is equivalent to the MOB setting in the BPR list.
# 0x80(CapabilityDirectDevice): This is used when the client is running on a MSN Direct device. This is equivalent to the WWE setting in the BPR list.
# 0x200(CapabilityWebIMClient): This is used when someone signs in on the official Web-based MSN Messenger. It will show a new icon in other people's contact list.
# 0x800(CapabilityConnectedViaTGW): Internal Microsoft client and/or Microsoft Office Live client (TGWClient).
# 0x1000(CapabilityHasSpace): This means you have a MSN Space.
# 0x2000(CapabilityMCEUser): This means you are using Windows XP Media Center Edition.
# 0x4000(CapabilitySupportsDirectIM): This means you support 'DirectIM' (creating direct connections for conversations rather than using the traditional switchboard)
# 0x8000(CapabilitySupportsWinks): This means you support Winks receiving (If not set the official Client will warn with 'contact has an older client and is not capable of receiving Winks')
# 0x10000: Your client supports the MSN Search feature
# 0x20000(CapabilityIsBot): The client is bot (provisioned account)
# 0x40000(CapabilitySupportsVoiceIM): This means you support Voice Clips receiving
# 0x80000(CapabilitySupportsSChannel): This means you support Secure Channel Communications
# 0x100000(CapabilitySupportsSipInvite): Supports SIP Invitations
# 0x200000(CapabilitySupportsTunneledSip): Supports Tunneled SIP
# 0x400000(CapabilitySupportsSDrive): Sharing Folders
# 0x1000000(CapabilityHasOnecare): The client has OneCare
# 0x2000000(CapabilityP2PSupportsTurn): Supports P2P TURN
# 0x4000000(CapabilityP2PBootstrapViaUUN): Supports P2P Bootstrap via UUN
# 0x10000000(CapabilityMsgrVersion1): Supports MSNC1 (MSN Msgr 6.0)
# 0x20000000(CapabilityMsgrVersion2): Supports MSNC2 (MSN Msgr 6.1)
# 0x30000000(CapabilityMsgrVersion3): Supports MSNC3 (MSN Msgr 6.2)
# 0x40000000(CapabilityMsgrVersion4): Supports MSNC4 (MSN Msgr 7.0)
# 0x50000000(CapabilityMsgrVersion5): Supports MSNC5 (MSN Msgr 7.5)
# 0x60000000(CapabilityMsgrVersion6): Supports MSNC6 (WL Msgr 8.0)
# 0x70000000(CapabilityMsgrVersion7): Supports MSNC7 (WL Msgr 8.1)
# 0x80000000(CapabilityMsgrVersion8): Supports MSNC8 (WL Msgr 8.5)
# 0x90000000(CapabilityMsgrVersion9): Supports MSNC9 (WL Msgr 9.0)
# 0xA0000000(CapabilityMsgrVersion10): Supports MSNC10 (WL Msgr 14.0)
# Note: If you support an MSNC protocol, the official client assumes that you also support all previous MSNC protocols.
# Extended Client Capabilities (from MSNP16)
# 0x10(CapabilityRTCVideoEnabled): RTC Video enabled
# 0x20(CapabilityP2PV2): Supports P2PV2
# Extended capabilities are written after the 'basic' capabilities, seperated by a colon. (capab:excapab) For example 4:48 means that the client can send/receive Ink (GIF format) + RTC Video enabled + Supports P2PV2
    return;
}

sub err2str {    # Converts \d+ to \s+
    my ($i, @data) = @_;
    state $errors //= {200 => 'Invalid Syntax',
                        201 => 'Invalid parameter',
                        205 => 'Invalid user',
                        206 => 'Domain name missing',
                        207 => 'Already logged in',
                        208 => 'Invalid User Name',
                        209 => 'Invlaid Friendly Name',
                        210 => 'List Full',
                        213 => 'Invalid Rename Request?',
                        215 => 'User already on list',
                        216 => 'User not on list',
                        217 => 'User not online',
                        218 => 'Already in that mode',
                        219 => 'User is in the opposite list',
                        223 => 'Too Many Groups',
                        224 => 'Invalid Groups ',
                        225 => 'User Not In Group',
                        227 => 'Group Is Not Empty',
                        228 => 'Group With Same Name Exists',
                        229 => 'Group Name too long',
                        230 => 'Cannont Remove Group Zero',
                        231 => 'Invalid Group',
                        240 => 'Empty Domain',
                        280 => 'Switchboard Failed',
                        281 => 'Transfer to Switchboard failed',
                        282 => 'P2P Error?',
                        300 => 'Required Field Missing',
                        301 => 'Too Many Hits to FND',
                        302 => 'Not Logged In',
                        402 => 'Error Accessing Contact List',
                        403 => 'Error Accessing Contact List',
                        420 => 'Invalid Account Permissions',
                        500 => 'Internal Server Error',
                        501 => 'Database Server Error',
                        502 => 'Command Disabled',
                        510 => 'File Operation Failed',
                        511 => 'User is Banned',
                        520 => 'Memory Allocation Failed',
                        540 => 'Challenge Response Failed',
                        600 => 'Server Is Busy',
                        601 => 'Server Is Unavailable',
                        602 => 'Peer Name Server is Down',
                        603 => 'Database Connection Failed',
                        604 => 'Server Going Down',
                        605 => 'Server Unavailable',
                        707 => 'Could Not Create Connection',
                        710 => 'Bad CVR Parameter Sent',
                        711 => 'Write is Blocking',
                        712 => 'Session is Overloaded',
                        713 => 'Too Many Active Users',
                        714 => 'Too Many Sessions',
                        715 => 'Command Not Expected',
                        717 => 'Bad Friend File',
                        731 => 'Badly Formated CVR',
                        800 => 'Changing Display Name Too Rapidly',
                        910 => 'Server Too Busy',
                        911 => 'Authentication Failed',
                        912 => 'Server Too Busy',
                        913 => 'Not allowed While Offline',
                        914 => 'Server Not Available',
                        915 => 'Server Not Available',
                        916 => 'Server Not Available',
                        917 => 'Authentication Failed',
                        918 => 'Server Too Busy',
                        919 => 'Server Too Busy',
                        920 => 'Not Accepting New Users',
                        921 => 'Server Too Busy: User Digest',
                        922 => 'Server Too Busy',
                        923 => 'Kids Passport Without Parental Consent',
                        924 => 'Passport Account Not Verified',
                        928 => 'Bad ticket',
                        931 => 'Account Not On This Server'
    };
    $errors->{$i} // 'Unknown error #' . $i;
}
1;

=pod

=head1 NAME

AnyEvent::MSN::Protocol - Meh. No peeking!

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2011-2012 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with Microsoft.

=cut
