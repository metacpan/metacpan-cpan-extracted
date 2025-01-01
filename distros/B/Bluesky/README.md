# NAME

Bluesky - Bluesky Client Library in Perl

# SYNOPSIS

```perl
use Bluesky;
my $bsky = Bluesky->new();
$bsky->login( 'sanko', '1111-2222-3333-4444' );
$bsky->createPost( ... );
# To be continued...
```

# DESCRIPTION

You shouldn't need to know the AT protocol in order to get things done so I'm including this sugary wrapper so that
[At](https://metacpan.org/pod/At) can remain mostly technical.

# Constructor and Session Management

Bluesky.pm is my attempt to make use of Perl's class syntax so this is obviously OO.

## `new( ... )`

```perl
my $bsky = Bluesky->new( 'sanko', '1111-2222-3333-4444' );
```

Expected parameters include:

- `identifier` - required

    Handle or other identifier supported by the server for the authenticating user.

- `password` - required

    This is the app password not the account's password. App passwords are generated at
    [https://bsky.app/settings/app-passwords](https://bsky.app/settings/app-passwords).

# Feed and Content

Methods in this category create, modify, access, and delete content.

## `getTrendingTopics( [...] )`

```
$bsky->getTrendingTopics( );
```

Get a list of trending topics.

Expected parameters include:

- `viewer`

    DID of the account making the request (not included for public/unauthenticated queries). Used to boost followed
    accounts in ranking.

- `limit`

    Integer.

    Default: `10`, Minimum: `1`, Maximum: `25`.

## `getTimeline( [...] )`

```
$bsky->getTimeline();
```

Get a view of the requesting account's home timeline. This is expected to be some form of reverse-chronological feed.

Expected parameters include:

- `algorithm`

    Variant 'algorithm' for timeline. Implementation-specific.

    NOTE: most feed flexibility has been moved to feed generator mechanism.

- `limit`

    Integer.

    Default: `50`, Minimum: `1`, Maximum: `100`.

- `cursor`

## `getAuthorFeed( ... )`

```perl
$bsky->getAuthorFeed( actor => 'sankor.bsky.social' );
```

Get a view of an actor's 'author feed' (post and reposts by the author).

Expected parameters include:

- `actor` - required

    AT-identifier for the author.

- `limit`

    Integer.

    Default: `50`, Minimum: `1`, Maximum: `100`.

- `cursor`
- `filter`

    Combinations of post/repost types to include in response.

    Known values:

    - `posts_with_replies` - default
    - `posts_no_replies`
    - `posts_with_media`
    - `posts_and_author_threads`

- `includePins`

    Boolean value (false is default).

An error is returned if the client is blocked by the actor.

## `getPostThread( ... )`

```perl
$bsky->getPostThread( uri => 'at://bsky.app/app.bsky.feed.post/3l6oveex3ii2l' );
```

Get posts in a thread. Does not require auth, but additional metadata and filtering will be applied for authed
requests.

Expected parameters include:

- `uri` - required

    Reference (AT-URI) to post record.

- `depth`

    How many levels of reply depth should be included in response.

    Default: `6`, Minimum: `0`, Maximum: `1000`.

- `parentHeight`

    How many levels of parent (and grandparent, etc) post to include.

    Default: `80`, Minimum: `0`, Maximum: `1000`.

Returns an error if the thread cannot be found.

## `getPost( ... )`

```
$bsky->getPost('at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2');
```

Gets a single post view for a specified post (by AT-URI).

Expected parameters include:

- `uri` - required

    AT-URI.

## `getPosts( ... )`

```
$bsky->getPosts(
    'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l',
    'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3lbvgvbvcf22c'
);
```

Gets post views for a specified list of posts (by AT-URI). This is sometimes referred to as 'hydrating' a 'feed
skeleton'.

Expected parameters include:

- `uris` - required

    List of (up to 25) post AT-URIs to return hydrated views for.

## `getLikes( ... )`

```perl
$bsky->getLikes( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Get like records which reference a subject (by AT-URI and CID).

Expected parameters include:

- `uri` - required

    AT-URI of the subject (eg, a post record).

- `cid`

    CID of the subject record (aka, specific version of record), to filter likes.

- `limit`

    Integer.

    Default: 50, Minimum: 1, Maximum: 100.

- `cursor`

## `createPost( ... )`

```perl
$bsky->createPost( text => 'Test. Test. Test.' );
```

Create a new post.

Expected parameters include:

- `text` - required

    The primary post content. May be an empty string, if there are embeds.

    Annotations of text (mentions, URLs, hashtags, etc) are automatically parsed. These include:

    - mentions

        Facet feature for mention of another account. The text is usually a handle, including a '@' prefix, but the facet
        reference is a DID.

        ```
        This is an example. Here, I am mentioning @atproto.bsky.social and it links to their profile.
        ```

    - links

        Facet feature for a URL. The text URL may have been simplified or truncated, but the facet reference should be a
        complete URL.

        ```
        This is an example that would link to Google here: https://google.com/.
        ```

    - tags

        Facet feature for a hashtag. The text usually includes a '#' prefix, but the facet reference should not (except in the
        case of 'double hash tags').

        ```
        This is an example that would link to a few hashtags. #perl #atproto
        ```

- `timestamp`

    Client-declared timestamp (ISO 8601 in UTC) when this post was originally created.

    Defaults to the current time.

- `lang`

    Indicates human language of post primary text content.

    ```perl
    $bsky->createPost(
        lang     => [ 'en', 'ja' ],
        reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27',
        text     => 'こんにちは, World!'
    );
    ```

    This is expected to be a comma separated string of language codes (e.g. `en-US,en;q=0.9,fr`).

    Bluesky recommends sending the `Accept-Language` header to get posts in the user's preferred language. See
    [https://www.w3.org/International/questions/qa-lang-priorities.en](https://www.w3.org/International/questions/qa-lang-priorities.en) and
    [https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).

- `reply_to`

    AT-URL of a post to reply to.

    ```perl
    $bsky->createPost( reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27', text => 'Exactly!' );
    ```

- `embed`

    Bluesky allows for posts to contain embedded data.

    Known embed types:

    - `images`

        Up to 4 images (path name or raw data).

        Set alt text by passing a hash.

        ```perl
        $bsky->createPost(
            embed    => { images => ['path/to/my.jpg'] },
            lang     => 'en',
            reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27',
            text     => 'I found this image on https://google.com/'
        );

        $bsky->createPost(
            embed    => { images => [{ alt => 'Might be a picture of a frog.', image => 'path/to/my.jpg' }] },
            lang     => 'en',
            reply_to => 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lbvllq2kul27',
            text     => 'I found this image on https://google.com/'
        );
        ```

    - `url`

        A card (including the URL, the page title, and a description) will be presented in a GUI.

        ```perl
        $bsky->createPost( embed => { url => 'https://en.wikipedia.org/wiki/Main_Page' }, text => <<'END');
        This is the link to wikipedia, @atproto.bsky.social. You should check it out.
        END
        ```

    - `ref`

        An AT-URL to link from this post.

    - `video`

        A video to be embedded in a Bluesky record (eg, a post).

        ```perl
        $bsky->createPost( embed => { video => 'path/to/cat.mpeg' }, text => 'Loot at this little guy!' );
        ```

        This might be a single path, raw data, or a hash reference (if you're really into what and how the video is presented).

        If passed a hash, the following are expected:

        - `video` - required

            The path name.

        - `alt`

            Alt text description of the video, for accessibility.

        - `mime`

            Mime type.

            We try to figure this out internally if undefined.

        - `aspectRatio`

            Represents an aspect ratio.

            It may be approximate, and may not correspond to absolute dimensions in any given unit.

            ```perl
            ...
            aspectRatio =>{ width => 100, height => 120 },
            ...
            ```

        - `captions`

            This is a hash reference of up to 20 [WebVTT](https://en.wikipedia.org/wiki/WebVTT) files organized by language.

            ```perl
            ...
            captions => {
                en => 'english.vtt',
                ja => 'japanese.vtt'
            },
            ...
            ```

    You may also pass your own valid embed.

- `labels`

    Self-label values for this post. Effectively content warnings.

- `tags`

    Additional hashtags, in addition to any included in post text and facets.

    These are not visible in the current Bluesky interface but do cause posts to return as results to to search (such as
    [https://bsky.app/hashtag/perl](https://bsky.app/hashtag/perl).

Note that a post may only contain one of the following embeds: `image`, `video`, `embed_url`, or `embed_ref`.

## `deletePost( ... )`

```perl
$bsky->deletePost( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

my $post = $bsky->createPost( ... );
...
$bsky->deletePost( $post->{uri} );
```

Delete a post or ensures it doesn't exist.

Expected parameters include:

- `uri` - required

## `like( ... )`

```
$bsky->like( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

$bsky->like( 'at://did:plc:totallymadeupgarbagehere/app.bsky.feed.post/randomexample', 'fu82qrfrf829crw89rfpuwcfiosdfcu8239wcrusiofcv2epcuy8r9jkfsl' );
```

Like a post publically.

Expected parameters include:

- `uri` - required

    The AT-URI of the post.

- `cid`

    If undefined, the post is fetched to gather this for you.

On success, a record is returned.

## `deleteLike( ... )`

```
$bsky->deleteLike( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );

$bsky->deleteLike( 'at://did:plc:totallymadeupgarbagehere/app.bsky.feed.like/randomexample' );
```

Remove a like record.

Expected parameters include:

- `uri` - required

    The AT-URI of the post or the like record itself.

On success, commit info is returned.

# Social Graph

Methods documented in this section deal with relationships between the authorized user and other members of the social
network.

## `block( ... )`

```
$bsky->block( 'sankor.bsky.social' );
```

Blocks a user.

Expected parameters include:

- `identifier` - required

    Handle or DID of the person you'd like to block.

## `getBlocks( ... )`

```
$bsky->getBlocks( );
```

Enumerates which accounts the requesting account is currently blocking.

Requires auth.

Expected parameters include:

- `uri`

    AT-URI of the subject (eg, a post record).

- `limit`

    Integer.

    Default: 50, Minimum: 1, Maximum: 100.

- `cursor`

Returns a list of actor profile views on success.

# See Also

[At](https://metacpan.org/pod/At) - AT Protocol library

[App::bsky](https://metacpan.org/pod/App%3A%3Absky) - Bluesky client on the command line

[https://docs.bsky.app/docs/api/](https://docs.bsky.app/docs/api/)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
