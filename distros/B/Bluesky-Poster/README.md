# NAME

Bluesky::Poster - Simple interface for posting to Bluesky (AT Protocol)

# SYNOPSIS

    use Bluesky::Poster;

    my $poster = Bluesky::Poster->new(
        handle       => 'your-handle.bsky.social',
        app_password => 'abcd-efgh-ijkl-mnop',
    );

    my $result = $poster->post("Hello from Perl!");
    print "Post URI: $result->{uri}\n";

# DESCRIPTION

I've all but given up with X/Twitter.
It's API is overly complex and no longer freely available,
so I'm trying Bluesky.

This module authenticates with Bluesky using app passwords and posts text
messages using the AT Protocol API.

# METHODS

## new(handle => ..., app\_password => ...)

Constructs a new poster object and logs in.

## post($text)

Posts the given text to your Bluesky feed.

# AUTHOR

Nigel Horne, with help from ChatGPT

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
