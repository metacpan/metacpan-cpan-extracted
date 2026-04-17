package Apertur::SDK::Resource::Upload;

use strict;
use warnings;

use JSON qw(encode_json);
use File::Basename qw(basename);
use Apertur::SDK::Crypto qw(encrypt_image);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub image {
    my ($self, $uuid, $file, %options) = @_;

    my ($data, $filename);
    if (ref $file eq 'SCALAR') {
        # Raw bytes passed as scalar ref
        $data     = $$file;
        $filename = $options{filename} || 'image.jpg';
    }
    else {
        # File path string
        $filename = $options{filename} || basename($file);
        open my $fh, '<:raw', $file
            or die "Cannot open file '$file': $!\n";
        local $/;
        $data = <$fh>;
        close $fh;
    }

    my $mime_type = $options{mimeType} || $options{mime_type} || 'image/jpeg';

    my @multipart = (
        file => [
            undef,
            $filename,
            'Content-Type' => $mime_type,
            Content        => $data,
        ],
    );

    if ($options{source}) {
        push @multipart, source => $options{source};
    }

    my %headers;
    if ($options{password}) {
        $headers{'x-session-password'} = $options{password};
    }

    return $self->{http}->request(
        'POST', "/api/v1/upload/$uuid/images",
        multipart => \@multipart,
        headers   => \%headers,
    );
}

sub image_encrypted {
    my ($self, $uuid, $file, $public_key, %options) = @_;

    my ($data, $filename);
    if (ref $file eq 'SCALAR') {
        $data     = $$file;
        $filename = $options{filename} || 'image.jpg';
    }
    else {
        $filename = $options{filename} || basename($file);
        open my $fh, '<:raw', $file
            or die "Cannot open file '$file': $!\n";
        local $/;
        $data = <$fh>;
        close $fh;
    }

    my $mime_type = $options{mimeType} || $options{mime_type} || 'image/jpeg';
    my $encrypted = encrypt_image($data, $public_key);

    my $payload = encode_json({
        encryptedKey  => $encrypted->{encrypted_key},
        iv            => $encrypted->{iv},
        encryptedData => $encrypted->{encrypted_data},
        algorithm     => $encrypted->{algorithm},
        filename      => $filename,
        mimeType      => $mime_type,
        source        => $options{source} || 'sdk',
    });

    my %headers = (
        'Content-Type'     => 'application/json',
        'X-Aptr-Encrypted' => 'default',
    );
    if ($options{password}) {
        $headers{'x-session-password'} = $options{password};
    }

    return $self->{http}->request(
        'POST', "/api/v1/upload/$uuid/images",
        body    => $payload,
        headers => \%headers,
    );
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Upload - Image upload operations

=head1 DESCRIPTION

Handles uploading images to an upload session, both plain multipart
and end-to-end encrypted.

=head1 METHODS

=over 4

=item B<image($uuid, $file, %options)>

Uploads an image via multipart POST. C<$file> can be a file path string
or a scalar reference containing raw bytes. Options: C<filename>,
C<mimeType> (or C<mime_type>), C<source>, C<password>.

=item B<image_encrypted($uuid, $file, $public_key, %options)>

Encrypts an image with AES-256-GCM (key wrapped with RSA-OAEP) and
uploads it as a JSON payload. Requires C<Crypt::OpenSSL::RSA> and
C<CryptX>. Options: same as C<image>.

=back

=cut
