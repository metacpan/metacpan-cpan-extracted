package Amazon::S3::SignedURLGenerator;

use strict;
use warnings;
our $VERSION = '0.02';

use Carp;
use URI::Escape;
use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args = scalar(@_) % 2 ? %{$_[0]} : @_;
    $args{aws_access_key_id} or croak 'aws_access_key_id is required';
    $args{aws_secret_access_key} or croak 'aws_secret_access_key is required';

    $args{prefix}  ||= 'https://s3.amazonaws.com';
    $args{expires} ||= 3600;

    $args{prefix} =~ s/\/$//; # remove last /

    return bless \%args, $class;
}

sub generate_url {
    my ($self, $method, $path, $headers) = @_;

    $path =~ s/^\///;
    $headers ||= {};
    my $expires = $headers->{expires} || (time() + $self->{expires});

    my $x_path = $path;
    if ($self->{prefix} =~ '//(.*)\.s3') {
        $x_path = $1 . '/' . $path;
    }

    my $canonical_string = __canonical_string($method, $x_path, $headers, $expires);
    my $encoded_canonical = __encode($self->{aws_secret_access_key}, $canonical_string, 1);
    if (index($path, '?') == -1) {
        return "$self->{prefix}/$path?Signature=$encoded_canonical&Expires=$expires&AWSAccessKeyId=$self->{aws_access_key_id}";
    } else {
        return "$self->{prefix}/$path&Signature=$encoded_canonical&Expires=$expires&AWSAccessKeyId=$self->{aws_access_key_id}";
    }
}

our $AMAZON_HEADER_PREFIX = 'x-amz-';
our $METADATA_PREFIX = 'x-amz-meta-';

sub __trim {
    my ($value) = @_;

    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

# generate a canonical string for the given parameters.  expires is optional and is
# only used by query string authentication.
sub __canonical_string {
    my ($method, $path, $headers, $expires) = @_;
    my %interesting_headers = ();
    while (my ($key, $value) = each %$headers) {
        my $lk = lc $key;
        if (
            $lk eq 'content-md5' or
            $lk eq 'content-type' or
            $lk eq 'date' or
            $lk =~ /^$AMAZON_HEADER_PREFIX/
        ) {
            $interesting_headers{$lk} = __trim($value);
        }
    }

    # these keys get empty strings if they don't exist
    $interesting_headers{'content-type'} ||= '';
    $interesting_headers{'content-md5'} ||= '';

    # just in case someone used this.  it's not necessary in this lib.
    $interesting_headers{'date'} = '' if $interesting_headers{'x-amz-date'};

    # if you're using expires for query string auth, then it trumps date
    # (and x-amz-date)
    $interesting_headers{'date'} = $expires if $expires;

    my $buf = "$method\n";
    foreach my $key (sort keys %interesting_headers) {
        if ($key =~ /^$AMAZON_HEADER_PREFIX/) {
            $buf .= "$key:$interesting_headers{$key}\n";
        } else {
            $buf .= "$interesting_headers{$key}\n";
        }
    }

    # don't include anything after the first ? in the resource...
    $path =~ /^([^?]*)/;
    $buf .= "/$1";

    # ...unless there is an acl or torrent parameter
    if ($path =~ /[&?]acl($|=|&)/) {
        $buf .= '?acl';
    } elsif ($path =~ /[&?]torrent($|=|&)/) {
        $buf .= '?torrent';
    } elsif ($path =~ /[&?]logging($|=|&)/) {
        $buf .= '?logging';
    }

    return $buf;
}

# finds the hmac-sha1 hash of the canonical string and the aws secret access key and then
# base64 encodes the result (optionally urlencoding after that).
sub __encode {
    my ($aws_secret_access_key, $str, $urlencode) = @_;
    my $hmac = Digest::HMAC_SHA1->new($aws_secret_access_key);
    $hmac->add($str);
    my $b64 = encode_base64($hmac->digest, '');
    if ($urlencode) {
        return __urlencode($b64);
    } else {
        return $b64;
    }
}

sub __urlencode {
    my ($unencoded) = @_;
    return uri_escape($unencoded, '^A-Za-z0-9_-');
}

1;
__END__

=encoding utf-8

=head1 NAME

Amazon::S3::SignedURLGenerator - Amazon S3 Signed URL Generator

=head1 SYNOPSIS

    use Amazon::S3::SignedURLGenerator;

    my $generator = Amazon::S3::SignedURLGenerator->new(
        aws_access_key_id     => $aws_access_key_id,
        aws_secret_access_key => $aws_secret_access_key,
        prefix => 'https://mybucket.s3.amazonaws.com',
        expires => 600, # 10 minutes
    );

    my $url = $generator->generate_url('GET', 'path/file.txt', {});

=head1 DESCRIPTION

Amazon::S3::SignedURLGenerator is just a copy of L<Muck::FS::S3::QueryStringAuthGenerator> without unnecessary dependencies.

=head1 SEE ALSO

L<https://github.com/rbrigham/s3-signed-url>

L<Muck>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
