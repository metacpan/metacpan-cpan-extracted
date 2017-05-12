use utf8;
use strict;
use warnings;

package DR::Tarantool::MsgPack::Proto;
use DR::Tarantool::MsgPack qw(msgpack msgunpack msgcheck);
use base qw(Exporter);
our @EXPORT_OK = qw(call_lua response insert replace del update select auth handshake ping);
use Carp;
use Scalar::Util 'looks_like_number';
use Digest::SHA 'sha1';
use MIME::Base64;

our $DECODE_UTF8    = 1;

my (%resolve, %tresolve);

my %iter = (
    EQ                  => 0,
    REQ                 => 1,
    ALL                 => 2,
    LT                  => 3,
    LE                  => 4,
    GE                  => 5,
    GT                  => 6,
    BITS_ALL_SET        => 7,
    BITS_ANY_SET        => 8,
    BITS_ALL_NOT_SET    => 9
);

my %riter = reverse %iter;

BEGIN {
    my %types = (
        IPROTO_SELECT              => 1,
        IPROTO_INSERT              => 2,
        IPROTO_REPLACE             => 3,
        IPROTO_UPDATE              => 4,
        IPROTO_DELETE              => 5,
        IPROTO_CALL                => 6,
        IPROTO_AUTH                => 7,
        IPROTO_DML_REQUEST_MAX     => 8,
        IPROTO_PING                => 64,
        IPROTO_SUBSCRIBE           => 66,
    );
    my %attrs = (
        IPROTO_CODE                => 0x00,
        IPROTO_SYNC                => 0x01,
        IPROTO_SERVER_ID           => 0x02,
        IPROTO_LSN                 => 0x03,
        IPROTO_TIMESTAMP           => 0x04,
        IPROTO_SPACE_ID            => 0x10,
        IPROTO_INDEX_ID            => 0x11,
        IPROTO_LIMIT               => 0x12,
        IPROTO_OFFSET              => 0x13,
        IPROTO_ITERATOR            => 0x14,
        IPROTO_KEY                 => 0x20,
        IPROTO_TUPLE               => 0x21,
        IPROTO_FUNCTION_NAME       => 0x22,
        IPROTO_USER_NAME           => 0x23,
        IPROTO_DATA                => 0x30,
        IPROTO_ERROR               => 0x31,
    );

    use constant;
    while (my ($n, $v) = each %types) {
        constant->import($n => $v);
        $n =~ s/^IPROTO_//;
        $tresolve{$v} = $n;
    }
    while (my ($n, $v) = each %attrs) {
        constant->import($n => $v);
        $n =~ s/^IPROTO_//;
        $resolve{$v} = $n;
    }
}



sub raw_response($) {
    my ($response) = @_;

    my $len;
    {
        return unless defined $response;
        my $lenheader = length $response > 10 ?
            substr $response, 0, 10 : $response;
        return unless my $lenlen = msgcheck($lenheader);

        $len = msgunpack $lenheader, $DECODE_UTF8;
        croak 'Unexpected msgpack object ' . ref($len) if ref $len;
        $len += $lenlen;
    }


    return if length $response < $len;

    my @r;
    my $off = 0;

    for (1 .. 3) {
        my $sp = $off ? substr $response, $off : $response;
        my $len_item = msgcheck $sp;
        croak 'Broken response'
            unless $len_item and $len_item + $off <= length $response;
        push @r => msgunpack $sp, $DECODE_UTF8;
        $off += $len_item;

        if ($_ eq 2 and $off == length $response) {
            push @r => {};
            last;
        }
    }

    croak 'Broken response header' unless 'HASH' eq ref $r[1];
    croak 'Broken response body' unless 'HASH' eq ref $r[2];

    return [ $r[1], $r[2] ], substr $response, $off;
}

sub response($) {

    my ($resp, $tail) = raw_response($_[0]);
    return unless $resp;
    my ($h, $b) = @$resp;

    my $res = {};

    while(my ($k, $v) = each %$h) {
        my $name = $resolve{$k};
        $name = $k unless defined $name;
        $res->{$name} = $v;
    }
    while(my ($k, $v) = each %$b) {
        my $name = $resolve{$k};
        $name = $k unless defined $name;
        $res->{$name} = $v;
    }

    if (defined $res->{CODE}) {
        my $n = $tresolve{ $res->{CODE} };
        $res->{CODE} = $n if defined $n;
    }

    if (defined $res->{ITERATOR}) {
        my $n = $riter{ $res->{ITERATOR} };
        $res->{ITERATOR} = $n if defined $n;
    }

    return $res, $tail;
    
}

sub request($$) {
    my ($header, $body) = @_;
    my $pkt = msgpack($header) . msgpack($body);
    return msgpack(length $pkt) . $pkt;
}

sub _call_lua($$$) {
    my ($sync, $proc, $tuple) = @_;
    request
        {
            IPROTO_SYNC,            $sync,
            IPROTO_CODE,            IPROTO_CALL,
        },
        {
            IPROTO_FUNCTION_NAME,   $proc,
            IPROTO_TUPLE,           $tuple,
        }
    ;
}

sub call_lua($$@) {
    my ($sync, $proc, @args) = @_;
    return _call_lua($sync, $proc, \@args);
}

sub insert($$$) {
    my ($sync, $space, $tuple) = @_;

    $tuple = [ $tuple ] unless ref $tuple;
    croak "Cant convert HashRef to tuple" if 'HASH' eq ref $tuple;

    if (looks_like_number $space) {
        return request
            {
                IPROTO_SYNC,        $sync,
                IPROTO_CODE,        IPROTO_INSERT,
            },
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_TUPLE,       $tuple,
            }
        ;
    }

    # HACK
    _call_lua($sync, "box.space.$space:insert", $tuple);
}

sub replace($$$) {
    my ($sync, $space, $tuple) = @_;

    $tuple = [ $tuple ] unless ref $tuple;
    croak "Cant convert HashRef to tuple" if 'HASH' eq ref $tuple;

    if (looks_like_number $space) {
        return request
            {
                IPROTO_SYNC,        $sync,
                IPROTO_CODE,        IPROTO_REPLACE,
            },
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_TUPLE,       $tuple,
            }
        ;
    }
    # HACK
    _call_lua($sync, "box.space.$space:replace", $tuple);
}
sub del($$$) {
    my ($sync, $space, $key) = @_;

    $key = [ $key ] unless ref $key;
    croak "Cant convert HashRef to key" if 'HASH' eq ref $key;

    if (looks_like_number $space) {
        return request
            {
                IPROTO_SYNC,        $sync,
                IPROTO_CODE,        IPROTO_DELETE,
            },
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_KEY,         $key,
            }
        ;
    }
    # HACK
    _call_lua($sync, "box.space.$space:delete", $key);
}


sub update($$$$) {
    my ($sync, $space, $key, $ops) = @_;
    croak 'Oplist must be Arrayref' unless 'ARRAY' eq ref $ops;
    $key = [ $key ] unless ref $key;
    croak "Cant convert HashRef to key" if 'HASH' eq ref $key;

    if (looks_like_number $space) {
        return request
            {
                IPROTO_SYNC,        $sync,
                IPROTO_CODE,        IPROTO_UPDATE,
            },
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_KEY,         $key,
                IPROTO_TUPLE,       $ops,
            }
        ;
    }
    # HACK
    _call_lua($sync, "box.space.$space:update", [ $key, $ops ]);
}

sub select($$$$;$$$) {
    my ($sync, $space, $index, $key, $limit, $offset, $iterator) = @_;
    $iterator = 'EQ' unless defined $iterator;
    $offset ||= 0;
    $limit  = 0xFFFF_FFFF unless defined $limit;
    $key = [ $key ] unless ref $key;
    croak "Cant convert HashRef to key" if 'HASH' eq ref $key;

    unless(looks_like_number $iterator) {
        my $i = $iter{$iterator};
        croak "Wrong iterator type: $iterator" unless defined $i;
        $iterator = $i;
    }

    if (looks_like_number $space and looks_like_number $index) {
        return request
            {
                IPROTO_SYNC,        $sync,
                IPROTO_CODE,        IPROTO_SELECT,
            },
            {
                IPROTO_KEY,         $key,
                IPROTO_SPACE_ID,    $space,
                IPROTO_OFFSET,      $offset,
                IPROTO_INDEX_ID,    $index,
                IPROTO_LIMIT,       $limit,
                IPROTO_ITERATOR,    $iterator,
            }
        ;
    }

    # HACK
    _call_lua($sync, "box.space.$space.index.$index:select", [
                $key,
                {
                    offset => $offset,
                    limit => $limit,
                    iterator => $iterator
                } 
            ]
    );
}

sub ping($) {
    my ($sync) = @_;
    request
        {
            IPROTO_SYNC,    $sync,
            IPROTO_CODE,    IPROTO_PING,
        },
        {
        }
    ;
}


sub strxor($$) {
    my ($x, $y) = @_;

    my @x = unpack 'C*', $x;
    my @y = unpack 'C*', $y;
    $x[$_] ^= $y[$_] for 0 .. $#x;
    return pack 'C*', @x;
}

sub auth($$$$) {
    my ($sync, $user, $password, $salt) = @_;

    my $hpasswd = sha1 $password;
    my $hhpasswd = sha1 $hpasswd;
    my $scramble = sha1 $salt . $hhpasswd;


    my $hash = strxor $hpasswd, $scramble;
    request
        {
            IPROTO_SYNC, $sync,
            IPROTO_CODE, IPROTO_AUTH,
        },
        {
            IPROTO_USER_NAME,   $user,
            IPROTO_TUPLE,       [ 'chap-sha1', $hash ],
        }
    ;
}

sub handshake($) {
    my ($h) = @_;
    croak 'Wrong handshake length' unless length $h == 128;
    my $version = substr $h, 0, 64;
    my $salt =    substr MIME::Base64::decode_base64(substr $h, 64), 0, 20;

    for ($version) {
        s/\0.*//;
        s/^tarantool:?\s*//i;
    }
    return $version, $salt;
}

1;
