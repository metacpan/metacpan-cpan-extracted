package Crypt::Keyczar::Util;
use base 'Exporter';
use strict;
use warnings;

use Carp;
use MIME::Base64;
use Crypt::Keyczar::Engine;

our @EXPORT_OK = qw(
    encode_json decode_json
    json_true json_false
    json_null
);



sub create_from_json {
    my $json = shift;
    my $class = shift;

    my $opts = decode_json($json);
    return undef if !defined $opts;
    return $class->new(%{$opts});
}


sub encode_json { return Crypt::Keyczar::Util::JSON::encode(@_); }
sub decode_json { return Crypt::Keyczar::Util::JSON::decode(@_); }
sub json_true   { return Crypt::Keyczar::Util::JSON::true(); }
sub json_false  { return Crypt::Keyczar::Util::JSON::false(); }
sub json_null   { return Crypt::Keyczar::Util::JSON::null(); }


sub encode {
    my $src = shift;
    return undef if !defined $src;

    my $result = encode_base64($src, '');
    $result =~ tr{+/}{-_};
    $result =~ s/=*\r?\n?$//;
    return $result;
}


sub decode {
    my $src = shift;
    return undef if !defined $src;

    $src =~ tr{-_}{+/};
    if (length($src) % 4 != 0) {
        $src .= '=' x (4 - length($src) % 4);
    }
    return decode_base64($src);
}


1;


package Crypt::Keyczar::Util::JSON;
use strict;
use warnings;
use JSON;


sub is_v1 { return $JSON::VERSION < 2.0; }


sub encode {
    my $data = shift;
    my $enc = JSON->new;
    return $enc->objToJson($data) if is_v1();
    $enc->utf8(1);
    return $enc->encode($data); 
}


sub decode {
    my $data = shift;
    my $dec = JSON->new;
    return $dec->jsonToObj($data) if is_v1();
    $dec->utf8(1);
    return $dec->decode($data);
}


sub true { return is_v1() ? JSON::True() : JSON::true(); }
sub false { return is_v1() ? JSON::False() : JSON::false(); }
sub null { return is_v1() ? JSON::Null() : JSON::null(); }

1;
__END__
