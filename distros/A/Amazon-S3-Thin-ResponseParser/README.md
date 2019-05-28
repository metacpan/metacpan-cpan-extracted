# NAME

Amazon::S3::Thin::ResponseParser - A parser for S3 XML responses

# SYNOPSIS

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

# DESCRIPTION

Amazon::S3::Thin::ResponseParser parses an XML response from S3 API.

This module provides a helper for the `list_objects` API which provide by [Amazon::S3::Thin](https://metacpan.org/pod/Amazon::S3::Thin).

# METHODS

- $response\_parser = Amazon::S3::Thin::ResponseParser->new();
- $response\_parser = Amazon::S3::Thin::ResponseParser->new(xml => $xml);

    This will create a new instance of [Amazon::S3::Thin::ResponseParser](https://metacpan.org/pod/Amazon::S3::Thin::ResponseParser).

    If you specify the `xml => $xml` argument, you can replace the XML parser.
    The `$xml` should be an instance of [XML::LibXML](https://metacpan.org/pod/XML::LibXML).

- ($list\_objects, $error) = $response\_parser->list\_objects($content);

    This takes an XML response as `$content` and it will return a list of objects and an error if the `$content` has
    [Error Responses](https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html).
    The `$content` should be valid XML formed
    [GET Bucket (List Objects) Version 2](https://docs.aws.amazon.com/AmazonS3/latest/API/v2-RESTBucketGET.html) or
    [GET Bucket (List Objects) Version 1](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGET.html).

    `$list_objects` is a hashref that looks like following form. undef is returned if there is the `$error`.

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

    `$error` is a hashref that looks like following form. undef is returned if there is the `$list_objects`.

        {
            code       => 'NoSuchKey',
            message    => 'The resource you requested does not exist',
            resource   => '/mybucket/myfoto.jpg',
            request_id => '4442587FB7D0A2F9',
        };

# SEE ALSO

[Amazon::S3::Thin](https://metacpan.org/pod/Amazon::S3::Thin)

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
