[![Build Status](https://travis-ci.org/zoncoen/Amazon-CloudFront-SignedURL.png?branch=master)](https://travis-ci.org/zoncoen/Amazon-CloudFront-SignedURL)
# NAME

Amazon::CloudFront::SignedURL - A module to generate AWS CloudFront signed URLs.

# SYNOPSIS

    use Amazon::CloudFront::SignedURL;

    my $signed_url = Amazon::CloudFront::SignedURL->new(
        private_key_string => {PRIVATE_KEY},
        key_pair_id        => {KEY_PAIR_ID}
    );

    # create signed url with canned policy
    $signed_url->generate( resource => {RESOURCE_PATH}, expires => {EXPIRES} );

    # create signed url with custom policy
    $signed_url->generate( resource => {RESOURCE_PATH}, policy => {CUSTOM_POLICY} );

# DESCRIPTION

Amazon::CloudFront::SignedURL generates AWS CloudFront signed URLs.

# METHODS

- `Amazon::CloudFront::SignedURL->new(\%args: HashRef)`

    Creates a new instance.

    Arguments can be:

    - private\_key\_string

        The private key strings.

    - key\_pair\_id

        The AWS Portal assigned key pair identifier.

- `$signed_url->generate(\%args: HashRef)`

    Generate a signed URL.

    Arguments can be:

    - resource

        The URL or stream. (required)

    - expires

        The Unix epoch time when the URL is to expire. (xor policy)

    - policy

        The CloudFront policy document. (xor expires)

# LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

zoncoen <zoncoen@gmail.com>
