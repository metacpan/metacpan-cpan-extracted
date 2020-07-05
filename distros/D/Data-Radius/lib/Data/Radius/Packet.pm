package Data::Radius::Packet;
# encode/decode RADIUS protocol messages

use v5.10;
use strict;
use warnings;
use Digest::MD5 ();
use Digest::HMAC_MD5 ();
use bytes;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(secret dict));

use Data::Radius::Constants qw(:all);
use Data::Radius::Encode qw(encode);
use Data::Radius::Decode qw(decode);
use Data::Radius::Util qw(encrypt_pwd decrypt_pwd is_enum_type);

use constant {
    # common attributes
    ATTR_PASSWORD       => 2,
    ATTR_VENDOR         => 26,
    # Message-Authenticator
    ATTR_MSG_AUTH_NAME  => 'Message-Authenticator',
    ATTR_MSG_AUTH       => 80,
    ATTR_MSG_AUTH_LEN   => 18,

    # has extra byte in VSA header
    WIMAX_VENDOR        => 24757,
};

my %IS_REPLY   = map { $_ => 1 } (ACCESS_ACCEPT, ACCESS_REJECT, DISCONNECT_ACCEPT, DISCONNECT_REJECT, COA_ACCEPT, COA_REJECT);
my %IS_REQUEST = map { $_ => 1 } (ACCESS_REQUEST, ACCOUNTING_REQUEST, DISCONNECT_REQUEST, COA_REQUEST);

my $request_id = int( rand(255) );

# Digest::MD5 object
my $md5;

sub new {
    my ($class, %h) = @_;
    my $obj = {
        secret => $h{secret},
        dict => $h{dict},
    };

    bless $obj, $class;
}

# build new request
# input:
#  type - radius code
#  authenticator - for access request allow to override random one,
#                  for replies - value from request must be used
#  av_list - array-ref of AV in {Name, Value} or {Id,Type,VendorId,Value} form
#  dict - allow to override default dictionary object from constructor
#  secret - allow to override default secret from constructor
#  with_msg_auth - boolean, to add Message-Authenticator.
#                  This can be archieved by adding Message-Authenticator to av_list with undefined value
#  request_id - allow to specify custom value (0..255), otherwise internal counter is used
sub build {
    my ($self, %h) = @_;

    # RADIUS code
    my $type = $h{type};
    # list in form of { Name => ... Value => ... [Vendor => ...]}
    my $av_list = $h{av_list};
    # object of Data::Radius::Dictionary or compatible
    my $dict = $h{dict} // $self->dict();
    # RADIUS secret
    if($h{secret}) {
        $self->secret($h{secret});
    }
    die 'No secret value' if(! defined $self->secret);
    # enable adding Message-Authenticator attribute (RFC3579)
    # enable it by defaulf if Message-Authenticator is present in av_list with empty value
    my $with_msg_auth = $h{with_msg_auth};

    if ($self->is_reply($type) && ! $h{authenticator}) {
        die "No authenticator value from request";
    }

    # Authenticator required now to encode password field (if present)
    my $authenticator;
    if ($type == ACCESS_REQUEST) {
        # random, but allow to override for testing
        $authenticator = $h{authenticator} // pack 'L4', map { int(rand(2 ** 32 - 1)) } (0..3);
    }

    # pack attributes
    my @bin_av = ();
    foreach my $av (@{$av_list}) {
        # Message-Authenticator
        if (($av->{Name} eq ATTR_MSG_AUTH_NAME) && !$av->{Value}) {
            $with_msg_auth = 1;
            # this AV will be calculated and added to the end of list
            next;
        }

        my $bin = $self->pack_attribute($av, $authenticator);
        next if(! $bin);
        push @bin_av, $bin;
    }

    my $attributes = join('', @bin_av);

    # build packet header

    my $length = 20 + length($attributes);

    # generate new sequential id if not given (one byte size)
    my $req_id = $h{request_id} // ($request_id++) & 0xff;

    # RFC3579 Message-Authenticator (EAP)
    if($with_msg_auth) {
        # calculate and append Message-Authenticator attribute
        $length += ATTR_MSG_AUTH_LEN;
        my $msg_auth = "\x0" x (ATTR_MSG_AUTH_LEN - 2);

        my $used_auth;
        if ($type == ACCESS_REQUEST) {
            # random-generated
            $used_auth = $authenticator;
        }
        elsif ($self->is_request($type)) {
            # Message-Authenticator should not be present in ACCOUNTING_REQUEST
            $used_auth = "\x00" x 16;
        }
        else {
            # must be passed when composing replies
            $used_auth = $h{authenticator};
        }

        my $data = join('',
                        pack('C C n', $type, $req_id, $length),
                        $used_auth,
                        $attributes,
                        pack('C C', ATTR_MSG_AUTH, ATTR_MSG_AUTH_LEN),
                        $msg_auth,
                    );

        my $hmac = Digest::HMAC_MD5->new($self->secret);
        $hmac->add( $data );
        $msg_auth = $hmac->digest;

        $attributes .= pack('C C', ATTR_MSG_AUTH, ATTR_MSG_AUTH_LEN) . $msg_auth;
    }

    # calculate authentificator value for non-authentication request
    if (! $authenticator) {
        # calculated from content
        my $used_auth = $self->is_request($type) ? "\x0" x 16 : $h{authenticator};

        my $hdr = pack('C C n', $type, $req_id, $length);
        $md5 //= Digest::MD5->new;
        $md5->add($hdr, $used_auth, $attributes, $self->secret);
        $authenticator = $md5->digest();
    }

    # wtf?
    die "No authenticator" if(! $authenticator);

    my $packet = join('',
                        pack('C C n', $type, $req_id, $length),
                        $authenticator,
                        $attributes,
                    );

    return ($packet, $req_id, $authenticator);
}

# authenticator required only for password attribute
# av:  {Name,Value,[Tag]} or {Id,Type,Value,[VendorId],[Tag]}
sub pack_attribute {
    my ($self, $av, $authenticator) = @_;

    # optional
    my $dict = $self->dict;

    my $attr;
    my $vendor_id;

    # attribute not present in dictionary must be passed as {Id, Type, Value, VendorId, Tag },
    # where VendorId and Tag are optional
    if ($av->{Id}) {
        if (! $av->{Type}) {
            warn "No attribute type for " . $av->{Id};
            return undef;
        }
        $attr = {
            id => $av->{Id},
            name => $av->{Id},
            type => $av->{Type},
            vendor => $av->{VendorId},
            has_tag => defined $av->{Tag},
        };
        $vendor_id = $av->{VendorId};
    }
    else {
        # av: {Name, Value}

        if (! $dict) {
            warn 'No dictionary provided';
            return undef;
        }

        # tagged attribute
        if ($av->{Name} =~ /^([\w-]+):(\d+)$/) {
            ($av->{Name}, $av->{Tag}) = ($1, $2);
        }

        $attr = $dict->attribute($av->{Name});
        if (! $attr) {
            warn "Unknown attribute ".$av->{Name};
            return undef;
        }

        if (defined $av->{Tag} && !$attr->{has_tag}) {
            warn "Tag not required for attribute ".$av->{Name};
            return undef;
        }

        if ($attr->{has_tag} && ! defined $av->{Tag}) {
            warn "No Tag provided for attribute ".$av->{Name};
            return undef;
        }

        # TODO store vendor_id in dictionary parser
        $vendor_id = $dict->vendor_id($attr->{vendor});
    }

    if (defined $av->{Tag}) {
        my $tag = $av->{Tag} // 0;
        if ($tag < 1 || $tag > 31) {
            warn "Tag value is out of range [1..31] for ".($av->{Name} // $av->{Id});
            return undef;
        }
    }

    my $value = $av->{Value};
    if (! defined $value) {
        warn "Undefined value for " . $attr->{name};
        return undef;
    }

    if ($attr->{id} == ATTR_PASSWORD && ! $vendor_id) {
        # need an authenticator - this attribute must be present only in ACCESS REQUEST
        $value = encrypt_pwd($value, $self->secret, $authenticator);
    }

    if ($attr->{type} ne 'tlv' && is_enum_type($attr->{type}) && $dict) {
        # convert constant-like values to real value
        $value = $dict->value($attr->{name}, $value) // $value;
    }
    # else - for TVL type value is ARRAY-ref

    my $encoded = encode($attr, $value, $self->dict, ($attr->{has_tag} ? $av->{Tag} : undef) );

    if (! defined $encoded) {
        warn "Unable to encode value for ".$av->{Name};
        return undef;
    }

    my $len_encoded = length($encoded);

    if (! $vendor_id) {
        # tag already included into value, if any
        return pack('C C', $attr->{id}, $len_encoded + 2) . $encoded;
    }

    # VSA

    my $vsa_header;
    if ($vendor_id == WIMAX_VENDOR) {
        $vsa_header = pack('N C C C', $vendor_id, $attr->{id}, $len_encoded + 3, 0);
    }
    else {
        # tag already included into value, if any
        $vsa_header = pack('N C C', $vendor_id, $attr->{id}, $len_encoded + 2);
    }

    return pack('C C', ATTR_VENDOR, length($vsa_header) + $len_encoded + 2) . $vsa_header . $encoded;
}

# parse binary-encoded radius packet
# returns list: type, request-id, authenticator, \@AV_list
sub parse {
    my ($self, $packet, $orig_auth) = @_;

    my $dict = $self->dict;

    my($type, $req_id, $length, $auth, $attributes) = unpack('C C n a16 a*', $packet);

    # Validate authenticator field
    my $expected_auth;
    if ($type == ACCESS_REQUEST) {
        # authenticator is random value - no validation
    }
    else {
        my $used_auth;
        if ($self->is_request($type)) {
            $used_auth = "\x00" x 16;
        }
        else {
            # fo replied we have to use authenticator from request:
            if (! $orig_auth) {
                warn "No original authenticator - unable to verify reply";
                return undef;
            }
            $used_auth = $orig_auth;
        }

        $md5 //= Digest::MD5->new;

        my $hdr = pack('C C n', $type, $req_id, $length);
        $md5->add($hdr, $used_auth, $attributes, $self->secret);
        $expected_auth = $md5->digest();

        if($auth ne $expected_auth) {
            warn "Bad authenticator value";
            return undef;
        }
    }

    # decode attributes
    my @attr;
    my $msg_auth;
    my $pos = 0;
    my $len = length($attributes);

    while ($pos < $len) {
        my ($attr_val, $vendor_id, $vendor, $vsa_len, $attr, $tag) = ();
        # FIXME not supported
        my $wimax_cont;

        my ($attr_id, $attr_len) = unpack('C C', substr($attributes, $pos, 2));

        if ($attr_id == ATTR_VENDOR) {
            my $vsa_header_len = 6;

            ($vendor_id, $attr_id, $vsa_len) = unpack('N C C', substr($attributes, $pos + 2, $vsa_header_len) );
            if ($vendor_id == WIMAX_VENDOR) {
                # +1 continuation byte
                $vsa_header_len = 7;
                $wimax_cont = unpack('C', substr($attributes, $pos + 8, 1));
                warn 'continuation field is not supported' if ($wimax_cont);
                printf "WIMAX cont: %d\n", $wimax_cont;
            }

            if ($dict) {
                $vendor = $dict->vendor_name($vendor_id) // $vendor_id;
                $attr = $dict->attribute_name($vendor, $attr_id);
            }

            $attr_val = substr($attributes, $pos + 2 + $vsa_header_len, $attr_len - 2 - $vsa_header_len);
        }
        else {
            if ($dict) {
                $attr = $dict->attribute_name(undef, $attr_id);
            }

            $attr_val = substr($attributes, $pos + 2, $attr_len - 2);
        }

        if ($attr_id == ATTR_MSG_AUTH && ! $vendor) {
            die "Invalid Message-Authenticator len" if ($attr_len != 18);
            $msg_auth = $attr_val;
            # zero it to verify later
            $attr_val = "\x0" x (ATTR_MSG_AUTH_LEN - 2);
            substr($attributes, $pos + 2, $attr_len - 2, $attr_val);
        }

        $pos += $attr_len;

        if (! $attr) {
            # raw data for unknown attribute
            push @attr, {
                Name => $attr_id,
                Value => $attr_val,
                Type => undef,
                Vendor => $vendor,
                Tag => undef,
            };
            next;
        }

        (my $decoded, $tag) = decode($attr, $attr_val, $self->dict);
        if (is_enum_type($attr->{type})) {
            # try to convert value to constants
            $decoded = $dict->constant($attr->{name}, $decoded) // $decoded;
        }

        # password is expected only in auth request
        if ($type == ACCESS_REQUEST && $attr->{id} == ATTR_PASSWORD && ! $attr->{vendor}) {
            $decoded = decrypt_pwd($decoded, $self->secret, $auth);
        }

        push @attr, {
            Name => $attr->{name},
            Value => $decoded,
            Type => $attr->{type},
            Vendor => $vendor,
            Tag => $tag,
        };
    }

    if($msg_auth) {
        # we already replaced msg auth value to \x0...
        my $auth_used;
        if ($self->is_reply($type)) {
            $auth_used = $orig_auth;
        }
        elsif ($type == ACCESS_REQUEST) {
            $auth_used = $auth;
        }
        else {
            # other type of request should use 00x16
            # Message-Authenticator should not be present in ACCOUNTING_REQUEST
            $auth_used = "\x00" x 16;
        }

        my $data = join('',
                        pack('C C n', $type, $req_id, $length),
                        $auth_used,
                        $attributes,
                    );
        my $hmac = Digest::HMAC_MD5->new($self->secret);
        $hmac->add( $data );
        my $exp_msg_auth = $hmac->digest;

        if ($msg_auth ne $exp_msg_auth) {
            warn "Message-Authenticator not verified";
            return undef;
        }
    }

    return ($type, $req_id, $auth, \@attr);
}

# extract request id from packet header without parsing attributes
# should be used to find original authenticator value for received reply packet to pass it to decode_request()
sub request_id {
    my ($self, $packet) = @_;
    my $req_id = unpack('C', substr($packet, 1, 1));
    return $req_id;
}

sub is_reply {
    my ($class, $type) = @_;
    return $IS_REPLY{ $type } // 0;
}

sub is_request {
    my ($class, $type) = @_;
    return $IS_REQUEST{ $type } // 0;
}

1;

__END__

=head1 NAME

Data::Radius::Packet - module to encode/decode RADIUS messages

=head1 SYNOPSYS

    use Data::Radius::Constants qw(:all);
    use Data::Radius::Packet;

    my $dictionary = Data::Radius::Dictionary->load_file('./radius/dictionary');
    my $packet = Data::Radius::Packet->new(secret => 'top-secret', dict => $dictionary);

    # build request packet:
    my ($request, $req_id, $authenticator) = $packet->build(
        type => ACCESS_REQUEST,
        av_list => [
            { Name => 'User-Name', Value => 'JonSnow'},
            { Name => 'User-Password', Value => 'Castle Black' },
            { Name => 'Message-Authenticator', Value => '' },
        ],
    );

    # ... send $request and read $reply binary packets from RADIUS server

    # parse reply packet:
    my ($reply_type, $reply_id, $reply_authenticator, $av_list) = $packet->parse($reply, $authenticator);

=head1 DESCRIPTION

The C<Data::Radius::Packet> module provides a methods to encode/decode RADIUS messages.
It can be used to implement both Radius client or Radius server.

=head1 CONSTRUCTOR

=over

=item new ( secret => SECRET, dict => DICTIONARY )

Create a new object.
All arguments are optional. Dictionary is object of C<Data::Radius::Dictionary> which allow to use attribute names instead of codes.
Secret is global secret string, can be overrided when building a new packet.

=back

=head1 METHODS

=over

=item build ( type => CODE, av_list => AVLIST, [ authenticator => AUTH ],
            [ dict => DICTIONARY ], [ secret => SECRET ],
            [ with_msg_auth => BOOL ], [ request_id => BYTE ])

Build a binary-encoded RADIUS packet.

C<type> identify type of RADIUS request. They are defined in Data::Radius::Constants.

C<av_list> is ARRAY-REF of attributes, each defined as HASH-REF with keys {Name, Value, [Tag]} or {Id, [VendorId], Value}
Tagged attributes can be also specified using 'Name:Tag' format.

C<authenticator> is optional for request (by default the random value will be used), but required for replies.

C<secret> and C<dict> can be used to override values from constructor (for example to use individual secrets for different Radius servers).

C<with_msg_auth> can be passed to append Message-Authenticator attribute.
It also can be archived by adding this attribyte to AV list with empty value
Note that this attribute usually must not be used for ACCOUNTING requests.

C<request_id> - allow to define own it. By default internal sequence is used. Value must be in range 0-255 (1byte)


=item parse ($radius_packet, [$request_authenticator])

Parse binary-encoded RADIUS packet to list of attributes

Returns multiple values: RADIUS code, request id, authenticator, ARRAY-REF of attributes


=item request_id ($radius_packet)

Returns request id from packet without parsing it's attribues.
Can be used to choose request authenticator before parsing the response packet in full.

=back

=head1 SEE ALSO

L<Data::Radius::Constants>, L<Data::Radius::Dictionary>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut
