# $Id: SSH2.pm,v 1.2 2001/07/11 03:34:02 btrott Exp $

package Crypt::Keys::Private::DSA::SSH2;
use strict;

use MIME::Base64 qw( decode_base64 encode_base64 );

use constant PRIVKEY_MAGIC => 0x3f6ff9eb;
use constant PRIVKEY_TYPE => 'dl-modp{sign{dsa-nist-sha1},dh{plain}}';

use Crypt::Keys::Buffer;

sub deserialize {
    my $class = shift;
    my %param = @_;

    chomp($param{Content});
    my($head, $object, $content, $tail) = $param{Content} =~
        m:(---- BEGIN ([^\n\-]+) ----)\n(.+)(---- END .*? ----)$:s;
    my @lines = split /\n/, $content;
    my $escaped = 0;
    my @real;
    for my $l (@lines) {
        if (substr($l, -1) eq '\\') {
            $escaped++;
            next;
        }
        next if index($l, ':') != -1;
        if ($escaped) {
            $escaped--;
            next;
        }
        push @real, $l;
    }
    $content = join "\n", @real;
    $content = decode_base64($content);

    my $b = Crypt::Keys::Buffer->new(MP => 'SSH2');
    $b->append($content);
    my $magic = $b->get_int32;
    return unless $magic == PRIVKEY_MAGIC;

    my($ignore);
    $ignore = $b->get_int32;
    my $type = $b->get_str;
    my $cipher = $b->get_str;
    $ignore = $b->get_int32 for 1..3;

    return unless $cipher eq 'none';

    {
        p => $b->get_mp_int,
        g => $b->get_mp_int,
        q => $b->get_mp_int,
        pub_key => $b->get_mp_int,
        priv_key => $b->get_mp_int,
    };
}

sub serialize {
    my $class = shift;
    my %param = @_;

    my $b = Crypt::Keys::Buffer->new(MP => 'SSH2');
    $b->put_int32(PRIVKEY_MAGIC);
    $b->put_int32(0);
    $b->put_str(PRIVKEY_TYPE);
    $b->put_str('none');

    $b->put_int32(0) for 1..3;

    my $data = $param{Data};
    $b->put_mp_int( $data->{p} );
    $b->put_mp_int( $data->{g} );
    $b->put_mp_int( $data->{q} );
    $b->put_mp_int( $data->{pub_key} );
    $b->put_mp_int( $data->{priv_key} );

    $b->bytes(4, 4, pack "N", $b->length);

    (my $blob = encode_base64($b->bytes, '')) =~ s!(.{1,70})!$1\n!g;
    qq(---- BEGIN SSH2 ENCRYPTED PRIVATE KEY ----\n) .
    ($param{Comment} ? qq(Comment: $param{Comment}\n) : '') .
    $blob .
    qq(---- END SSH2 ENCRYPTED PRIVATE KEY ----\n);
}

1;
