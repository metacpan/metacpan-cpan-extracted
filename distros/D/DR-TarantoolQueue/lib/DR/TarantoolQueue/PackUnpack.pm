use utf8;
use strict;
use warnings;

package DR::TarantoolQueue::PackUnpack;
use Mouse;
use Compress::Zlib;
use MIME::Base64;

use JSON::XS;
        
has jsp =>
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => sub {
        return JSON::XS
                -> new
                -> allow_nonref
                -> allow_blessed
                -> convert_blessed
                -> utf8;
    }
;

has gzip_size_limit => is => 'ro', isa => 'Int', default => 1024 * 1024;

sub encode {
    my ($self, $data) = @_;
    my $pkt = $self->jsp->encode($data);

    return $pkt unless length $pkt >= $self->gzip_size_limit;

    $pkt = Compress::Zlib::memGzip($pkt);
    die "Can't compress data: " . $gzerrno unless defined $pkt;
    return join ':', 'base64', encode_base64 $pkt, '';
}

sub decode {
    my ($self, $data) = @_;

    return undef unless defined $data;

    return $self->jsp->decode($data) unless $data =~ /^base64:/;
    my $raw = decode_base64 substr $data, 7;

    $raw = Compress::Zlib::memGunzip($raw);
    return $self->jsp->decode($raw);
}

__PACKAGE__->meta->make_immutable;
