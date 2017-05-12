# NAME

AWS::Signature::V2 - Create a version 2 signature for AWS services

# SYNOPSIS

    use AWS::Signature::V2;
    use LWP::UserAgent->new;

    my $signer = AWS::Signature::V2->new(
        aws_access_key => ..., # defaults to $AWS_ACCESS_KEY
        aws_secret_key => ..., # defaults to $AWS_SECRET_KEY
    );

    my $ua  = LWP::UserAgent->new;
    my $uri = URI->new('https://');
    $uri->query_form(...);
    my $signed_uri = $signer->sign($uri);
    my $response = $ua->get($signed_uri);

# DESCRIPTION

Pretty much the only service that needs this anymore is the Amazon Product
Advertising API.  99% of this code was copied from URI::Amazon::APA.  But
URI::Amazon::APA doesn't support https and I wanted that.

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
