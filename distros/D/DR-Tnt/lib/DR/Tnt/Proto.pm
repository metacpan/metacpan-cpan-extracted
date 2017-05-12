use utf8;
use strict;
use warnings;

package DR::Tnt::Proto;
use base qw(Exporter);
our @EXPORT_OK = qw(
    call_lua
    response
    insert
    replace
    del
    update
    select
    auth
    handshake
    ping
);
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use DR::Tnt::Msgpack;
use Digest::SHA;
use Scalar::Util 'looks_like_number';
use Digest::SHA 'sha1';
use MIME::Base64;
use Data::Dumper;

sub parse_greeting {
    my ($str) = @_;
    croak "strlen is not 128 bytes" unless $str and 128 == length $str;

    my $salt = eval { substr decode_base64(substr $str, 64, 44), 0, 20; } || undef;
    my $grstr = substr $str, 0, 64;

    my ($title, $v, $pt, $uid) = split /\s+/, $grstr, 5;

    return {
        salt    => $salt,
        gr      => $grstr,
        title   => $title,
        version => $v,
        uuid    => $uid,
        proto   => $pt,
    }
}

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
        IPROTO_SELECT           => 1,
        IPROTO_INSERT           => 2,
        IPROTO_REPLACE          => 3,
        IPROTO_UPDATE           => 4,
        IPROTO_DELETE           => 5,
        IPROTO_CALL             => 6,
        IPROTO_AUTH             => 7,
        IPROTO_EVAL             => 8,
        IPROTO_PING             => 64,
    );
    my %attrs = (
        IPROTO_CODE             => 0x00,
        IPROTO_SYNC             => 0x01,
        IPROTO_SERVER_ID        => 0x02,
        IPROTO_LSN              => 0x03,
        IPROTO_TIMESTAMP        => 0x04,
        IPROTO_SCHEMA_ID        => 0x05,
        IPROTO_SPACE_ID         => 0x10,
        IPROTO_INDEX_ID         => 0x11,
        IPROTO_LIMIT            => 0x12,
        IPROTO_OFFSET           => 0x13,
        IPROTO_ITERATOR         => 0x14,
        IPROTO_KEY              => 0x20,
        IPROTO_TUPLE            => 0x21,
        IPROTO_FUNCTION_NAME    => 0x22,
        IPROTO_USER_NAME        => 0x23,
        IPROTO_EXPRESSION       => 0x27,
        IPROTO_DATA             => 0x30,
        IPROTO_ERROR            => 0x31,
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


sub raw_response($$) {
    my ($response, $utf8) = @_;

    my $len;
    {
        return unless defined $response;
        my $lenheader = length $response > 10 ?
            substr $response, 0, 10 : $response;
        return unless my $lenlen = DR::Tnt::Msgpack::msgunpack_check $lenheader;

        $len = DR::Tnt::Msgpack::msgunpack $lenheader;
        croak 'Unexpected msgpack object ' . ref($len) if ref $len;
        $len += $lenlen;
    }
    
    return if length $response < $len;

    my @r;
    my $off = 0;

    for (1 .. 3) {
        my $sp = $off ? substr $response, $off : $response;
        my $len_item = DR::Tnt::Msgpack::msgunpack_check $sp;
        croak sprintf('Broken %s section of response', $_)
            unless $len_item and $len_item + $off <= length $response;
        if ($utf8) {
            push @r => DR::Tnt::Msgpack::msgunpack_utf8 $sp;
        } else {
            push @r => DR::Tnt::Msgpack::msgunpack $sp;
        }
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

sub response($;$) {

    my ($buffer, $utf8) = @_;
    my ($resp, $tail) = raw_response($buffer => $utf8);
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

    return join '',
        msgpack(length $pkt),
        $pkt;
}

sub _mk_header($$$) {
    my ($code, $sync, $schema_id) = @_;
   

    return {
        IPROTO_SYNC, $sync,
        IPROTO_CODE, $code,
    } unless defined $schema_id;

    return {
        IPROTO_SYNC,        $sync,
        IPROTO_CODE,        $code,
        IPROTO_SCHEMA_ID,   $schema_id
    }
}

sub _call_lua($$$$) {
    my ($sync, $schema_id, $proc, $tuple) = @_;
    request
        _mk_header(IPROTO_CALL, $sync, $schema_id),
        {
            IPROTO_FUNCTION_NAME,   $proc,
            IPROTO_TUPLE,           $tuple,
        }
    ;
}

sub call_lua($$$@) {
    my ($sync, $schema_id, $proc, @args) = @_;
    return _call_lua($sync, $schema_id, $proc, \@args);
}


sub eval_lua($$$@) {
    my ($sync, $schema_id, $lua, @args) = @_;
    request
        _mk_header(IPROTO_EVAL, $sync, $schema_id),
        {
            IPROTO_EXPRESSION,  $lua,
            IPROTO_TUPLE,       \@args,
        }
    ;
}

sub insert($$$$) {
    my ($sync, $schema_id, $space, $tuple) = @_;

    $tuple = [ $tuple ] unless ref $tuple;
    croak "Cant convert HashRef to tuple" if 'HASH' eq ref $tuple;

    if (looks_like_number $space) {
        return request
            _mk_header(IPROTO_INSERT, $sync, $schema_id),
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_TUPLE,       $tuple,
            }
        ;
    }

    # HACK
    _call_lua($sync, $schema_id, "box.space.$space:insert", $tuple);
}

sub replace($$$$) {
    my ($sync, $schema_id, $space, $tuple) = @_;

    $tuple = [ $tuple ] unless ref $tuple;
    croak "Cant convert HashRef to tuple" if 'HASH' eq ref $tuple;

    if (looks_like_number $space) {
        return request
            _mk_header(IPROTO_REPLACE, $sync, $schema_id),
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_TUPLE,       $tuple,
            }
        ;
    }
    # HACK
    _call_lua($sync, $schema_id, "box.space.$space:replace", $tuple);
}
sub del($$$$) {
    my ($sync, $schema_id, $space, $key) = @_;

    $key = [ $key ] unless ref $key;
    croak "Cant convert HashRef to key" if 'HASH' eq ref $key;

    if (looks_like_number $space) {
        return request
            _mk_header(IPROTO_DELETE, $sync, $schema_id),
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_KEY,         $key,
            }
        ;
    }
    # HACK
    _call_lua($sync, $schema_id, "box.space.$space:delete", $key);
}


sub update($$$$$) {
    my ($sync, $schema_id, $space, $key, $ops) = @_;
    croak 'Oplist must be Arrayref' unless 'ARRAY' eq ref $ops;
    $key = [ $key ] unless ref $key;
    croak "Cant convert HashRef to key" if 'HASH' eq ref $key;

    if (looks_like_number $space) {
        return request
            _mk_header(IPROTO_UPDATE, $sync, $schema_id),
            {
                IPROTO_SPACE_ID,    $space,
                IPROTO_KEY,         $key,
                IPROTO_TUPLE,       $ops,
            }
        ;
    }
    # HACK
    _call_lua($sync, $schema_id, "box.space.$space:update", [ $key, $ops ]);
}

sub select($$$$$;$$$) {
    my ($sync, $schema_id, $space, $index, $key, $limit, $offset, $iterator) = @_;
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
            _mk_header(IPROTO_SELECT, $sync, $schema_id),
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
    _call_lua($sync, $schema_id, "box.space.$space.index.$index:select", [
                $key,
                {
                    offset => $offset,
                    limit => $limit,
                    iterator => $iterator
                } 
            ]
    );
}

sub ping($$) {
    my ($sync, $schema_id) = @_;
    request
        _mk_header(IPROTO_PING, $sync, $schema_id),
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

sub auth($$$$$) {
    my ($sync, $schema_id, $user, $password, $salt) = @_;

    my $hpasswd = sha1 $password;
    my $hhpasswd = sha1 $hpasswd;
    my $scramble = sha1 $salt . $hhpasswd;

    my $hash = strxor $hpasswd, $scramble;
    request
        _mk_header(IPROTO_AUTH, $sync, $schema_id),
        {
            IPROTO_USER_NAME,   $user,
            IPROTO_TUPLE,       [ 'chap-sha1', $hash ],
        }
    ;
}

1;
