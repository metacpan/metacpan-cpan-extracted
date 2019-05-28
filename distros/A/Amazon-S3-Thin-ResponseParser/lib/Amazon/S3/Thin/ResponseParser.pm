package Amazon::S3::Thin::ResponseParser;
use strict;
use warnings;
use XML::LibXML;
use XML::LibXML::XPathContext;

our $VERSION = "0.02";

sub new {
    my ($class, %args) = @_;

    my $xml = exists $args{xml} ? $args{xml} : XML::LibXML->new();

    return bless {
        xml => $xml,
    }, $class;
}

sub _xpc {
    my ($self, $content) = @_;
    my $doc = $self->{xml}->parse_string($content);
    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs('s3' => 'http://s3.amazonaws.com/doc/2006-03-01/');
    return $xpc;
}

sub list_objects {
    my ($self, $content) = @_;

    my $xpc = $self->_xpc($content);

    if ($xpc->findnodes('/Error')) {
        # https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html
        my $error = {
            code       => $xpc->findvalue('/Error/Code'),
            message    => $xpc->findvalue('/Error/Message'),
            request_id => $xpc->findvalue('/Error/RequestId'),
            resource   => $xpc->findvalue('/Error/Resource'),
        };
        return (undef, $error);
    }

    # https://docs.aws.amazon.com/AmazonS3/latest/API/v2-RESTBucketGET.html
    my $result = {
        contents                => [ map {
            +{
                etag          => _remove_quote($xpc->findvalue('./s3:ETag', $_)),
                key           => $xpc->findvalue('./s3:Key', $_),
                last_modified => $xpc->findvalue('./s3:LastModified', $_),
                owner         => {
                    display_name => $xpc->findvalue('./s3:Owner/s3:DisplayName', $_),
                    id           => $xpc->findvalue('./s3:Owner/s3:ID', $_),
                },
                size          => $xpc->findvalue('./s3:Size', $_),
                storage_class => $xpc->findvalue('./s3:StorageClass', $_),
            }
        } $xpc->findnodes('/s3:ListBucketResult/s3:Contents') ],
        common_prefixes         => [ map {
            +{
                owner  => {
                    display_name => $xpc->findvalue('./s3:Owner/s3:DisplayName', $_),
                    id           => $xpc->findvalue('./s3:Owner/s3:ID', $_),
                },
                prefix => $xpc->findvalue('./s3:Prefix', $_),
            }
        } $xpc->findnodes('/s3:ListBucketResult/s3:CommonPrefixes') ],
        delimiter               => $xpc->findvalue('/s3:ListBucketResult/s3:Delimiter'),
        encoding_type           => $xpc->findvalue('/s3:ListBucketResult/s3:EncodingType'),
        is_truncated            => _boolean($xpc->findvalue('/s3:ListBucketResult/s3:IsTruncated')),
        max_keys                => $xpc->findvalue('/s3:ListBucketResult/s3:MaxKeys'),
        name                    => $xpc->findvalue('/s3:ListBucketResult/s3:Name'),
        prefix                  => $xpc->findvalue('/s3:ListBucketResult/s3:Prefix'),
        # v1
        # https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGET.html
        marker                  => $xpc->findvalue('/s3:ListBucketResult/s3:Marker'),
        next_marker             => $xpc->findvalue('/s3:ListBucketResult/s3:NextMarker'),
        # v2
        continuation_token      => $xpc->findvalue('/s3:ListBucketResult/s3:ContinuationToken'),
        next_continuation_token => $xpc->findvalue('/s3:ListBucketResult/s3:NextContinuationToken'),
        key_count               => $xpc->findvalue('/s3:ListBucketResult/s3:KeyCount'),
        start_after             => $xpc->findvalue('/s3:ListBucketResult/s3:StartAfter'),
    };
    return ($result, undef);
}

sub _boolean {
    my $s = shift;
    return $s eq 'true' ? 1 : 0;
}

sub _remove_quote {
    my $s = shift;
    $s =~ s/^"|"$//g;
    return $s;
}

1;
__END__

=encoding utf-8

=head1 NAME

Amazon::S3::Thin::ResponseParser - A parser for S3 XML responses

=head1 SYNOPSIS

    use Amazon::S3::Thin;
    use Amazon::S3::Thin::ResponseParser;

    my $s3client = Amazon::S3::Thin->new({
        aws_access_key_id     => $aws_access_key_id,
        aws_secret_access_key => $aws_secret_access_key,
        region                => $region, # e.g. 'ap-northeast-1'
    });

    my $response_parser = Amazon::S3::Thin::ResponseParser->new();

    my $res = $s3_client->list_objects($bucket);
    die $res->status_line if $res->is_error;
    my ($list_objects, $error) = $response_parser->list_objects($res->content);
    die $error->{message} if $error;
    # Print a list of the object keys in the bucket:
    print join "\n", map { $_->{key} } @{$list_objects->{contents}};


=head1 DESCRIPTION

Amazon::S3::Thin::ResponseParser parses an XML response from S3 API.

This module provides a helper for the C<list_objects> API which provide by L<Amazon::S3::Thin>.

=head1 METHODS

=over 4

=item $response_parser = Amazon::S3::Thin::ResponseParser->new();

=item $response_parser = Amazon::S3::Thin::ResponseParser->new(xml => $xml);

This will create a new instance of L<Amazon::S3::Thin::ResponseParser>.

If you specify the C<< xml => $xml >> argument, you can replace the XML parser.
The C<$xml> should be an instance of L<XML::LibXML>.

=item ($list_objects, $error) = $response_parser->list_objects($content);

This takes an XML response as C<$content> and it will return a list of objects and an error if the C<$content> has
L<< Error Responses|https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html >>.
The C<$content> should be valid XML formed
L<< GET Bucket (List Objects) Version 2|https://docs.aws.amazon.com/AmazonS3/latest/API/v2-RESTBucketGET.html >> or
L<< GET Bucket (List Objects) Version 1|https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGET.html >>.

C<$list_objects> is a hashref that looks like following form. undef is returned if there is the C<$error>.

    {
        common_prefixes         => [],
        contents                => [
            {
                etag          => 'fba9dede5f27731c9771645a39863328',
                key           => 'my-image.jpg',
                last_modified => '2009-10-12T17:50:30.000Z',
                owner         => {
                    display_name => '',
                    id           => ''
                },
                size          => 434234,
                storage_class => 'STANDARD'
            },
        ],
        delimiter               => '',
        encoding_type           => '',
        is_truncated            => 0,
        max_keys                => 1000,
        name                    => 'bucket',
        prefix                  => '',
        # v1
        marker                  => '',
        next_marker             => '',
        # v2
        continuation_token      => '',
        next_continuation_token => '',
        key_count               => 205,
        start_after             => '',
    };

C<$error> is a hashref that looks like following form. undef is returned if there is the C<$list_objects>.

    {
        code       => 'NoSuchKey',
        message    => 'The resource you requested does not exist',
        resource   => '/mybucket/myfoto.jpg',
        request_id => '4442587FB7D0A2F9',
    };

=back

=head1 SEE ALSO

L<Amazon::S3::Thin>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

