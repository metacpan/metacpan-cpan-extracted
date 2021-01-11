# NAME

API::Medium - Talk with medium.com using their REST API

# VERSION

version 0.902

# SYNOPSIS

    use API::Medium;
    my $m = new({
        access_token=>'your_token',
    });
    my $hash = $m->get_current_user;
    say $hash->{id};

    my $url       = $m->create_post( $user_id, $post );

    my $other_url = $m->create_publication_post( $publication_id, $post );

# DESCRIPTION

It's probably a good idea to read [the Medium API
docs](https://github.com/Medium/medium-api-docs) first, especially as
the various data structures you have to send (or might get back) are
**not** documented here.

See `example/hello_medium.pl` for a complete script.

## Authentication

### OAuth2 Login

Not implemented yet, mostly because medium only support the "web
server" flow and I'm using `API::Medium` for an installed
application.

### Self-issued access token / Integration token

Go to your [settings](https://medium.com/me/settings), scroll down to
"Integration tokens", and either create a new one, or pick the one you
want to use.

# Methods

## new

    my $m = API::Medium->new({
         access_token => $token,
    });

Create a new API client. You will need to pass in your `$token`, see
above on how to get it. Please make sure no not leak your Integration
Token. If you do, anybody who has it can take over your Medium page!

## get\_current\_user

    my $data = $m->get_current_user;

Fetch the User "object".

You will need this to get the user `id` for posting. Depending on
your app you might want to store your `id` in some config file to
save one API call.

## publications

Not implemented yet. Listing the user's publications

    /users/{{userId}}/publications

## contributors

Not implemented yet. Fetching contributors for a publication.

    /publications/{{publicationId}}/contributors

## create\_post

    my $url = $m->create_post( $user_id, $post_data );

Create a new post. If you pass in bad data, Medium will probably
report an error.

`publishStatus` is set to 'draft' unless you pass in another value.

## create\_publication\_post

    my $url = $m->create_publication_post( $publication_id, $post_data );

Create a new post under a publication. You will need to figure out the
publication\_id by calling the API from the commandline (until
`publications` is implemented.)

If you pass in bad data, Medium will probably report an error.

`publishStatus` is set to 'draft' unless you pass in another value.

## TODO

- OAuth2 Login
- Get a new access\_token from refresh\_token
- `publications`
- `contributors`

## Thanks

Thanks to Dave Cross for starting [Cultured
Perl](https://medium.com/cultured-perl), which prompted me to write
this module so I can auto-post blogposts from [my private
blog](http://domm.plix.at) to medium.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
