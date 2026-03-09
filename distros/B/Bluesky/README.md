# NAME

Bluesky - Bluesky Client Library in Perl

# SYNOPSIS

```perl
use Bluesky;
my $bsky = Bluesky->new();

# Interactive OAuth Authentication (Recommended)
$bsky->oauth_helper(
    handle => 'user.bsky.social',
    listen => 1, # Automatically catch the redirect
    on_success => sub { say 'Logged in!' }
);

# Posting
$bsky->createPost( text => 'Hello from Perl!' );

# Streaming
my $fh = $bsky->firehose(sub ( $header, $body, $err ) {
    return warn $err if $err;
    say 'New event: ' . $header->{t};
});
$fh->start();
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

## `oauth_start( $handle, $client_id, $redirect_uri, [ $scope ] )`

Initiates the OAuth 2.0 Authorization Code flow. Returns the authorization URL.

```perl
my $url = $bsky->oauth_start(
    'user.bsky.social',
    'http://localhost',
    'http://127.0.0.1:8888/callback'
);
```

## `oauth_callback( $code, $state )`

Exchanges the authorization code for tokens and completes the OAuth flow.

```
$bsky->oauth_callback( $code, $state );
```

## `oauth_helper( %args )`

A high-level helper to manage the entire OAuth flow. This is the recommended way to authenticate for interactive
applications.

```perl
$bsky->oauth_helper(
    handle     => 'user.bsky.social',
    listen     => 1,
    on_success => sub ($self) {
        say 'Authenticated as ' . $self->did;
    }
);
```

Expected parameters include:

- `handle` - required

    The user's handle or DID.

- `listen`

    Boolean. If true, attempts to start a local HTTP server (using [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious%3A%3ALite)) to automatically capture the
    `code` and `state` from the redirect.

- `redirect`

    The redirect URI. Defaults to `http://127.0.0.1:8888/callback`.

- `scope`

    The requested OAuth scopes. Defaults to `atproto chat.bsky.convo`.

- `on_success`

    A callback subroutine invoked after a successful login. Receives the `$bsky` object as an argument.

## `firehose( $callback, [ $url ] )`

Returns a new [At::Protocol::Firehose](https://metacpan.org/pod/At%3A%3AProtocol%3A%3AFirehose) client for real-time streaming.

```perl
my $fh = $bsky->firehose(sub ($header, $body, $err) { ... });
$fh->start();
```

See [At::Protocol::Firehose](https://metacpan.org/pod/At%3A%3AProtocol%3A%3AFirehose) for more details.

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

Get a view of the requesting account's home timeline. This is expected to some form of reverse-chronological feed.

Expected parameters include:

- `algorithm`

    Variant 'algorithm' for timeline. Implementation-specific.

    NOTE: most feed flexibility has been moved to feed generator mechanism.

- `limit`

    Integer.

    Default: `50`, Minimum: `1`, Maximum: `100`.

- `cursor`

## `getFeed( ... )`

```
$bsky->getFeed( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );
```

Get a hydrated feed from a feed generator.

## `getFeedSkeleton( ... )`

```
$bsky->getFeedSkeleton( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );
```

Get a feed skeleton (list of URIs) from a feed generator.

## `getAuthorFeed( ... )`

```perl
$bsky->getAuthorFeed( actor => 'sankorobinson.com' );
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

## `getFeed( ... )`

```
$bsky->getFeed( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );
```

Get a hydrated feed from a feed generator.

## `getFeedSkeleton( ... )`

```
$bsky->getFeedSkeleton( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );
```

Get a feed skeleton (list of URIs) from a feed generator.

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

## `getBookmarks( ... )`

```
$bsky->getBookmarks();
```

Get private bookmarks for the authorized account.

## `createBookmark( ... )`

```
$bsky->createBookmark( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Create a private bookmark for a post.

## `deleteBookmark( ... )`

```
$bsky->deleteBookmark( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Delete a private bookmark.

## `getQuotes( ... )`

```perl
$bsky->getQuotes( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Get quotes of a post.

## `getActorLikes( ... )`

```perl
$bsky->getActorLikes( actor => 'sankorobinson.com' );
```

Get a list of posts liked by an actor.

## `searchPosts( ... )`

```perl
$bsky->searchPosts( q => 'perl' );
```

Find posts matching search criteria.

## `getSuggestedFeeds( ... )`

```
$bsky->getSuggestedFeeds();
```

Get suggested feed generators.

## `describeFeedGenerator( )`

```
$bsky->describeFeedGenerator();
```

Get information about a feed generator.

## `getFeedGenerator( ... )`

```
$bsky->getFeedGenerator( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/3l6oveex3ii2l' );
```

Get information about a feed generator.

## `getFeedGenerators( ... )`

```perl
$bsky->getFeedGenerators( feeds => [ ... ] );
```

Get information about multiple feed generators.

## `getActorFeeds( ... )`

```perl
$bsky->getActorFeeds( actor => 'sankorobinson.com' );
```

Get a list of feed generators created by an actor.

## `getRepostedBy( ... )`

```perl
$bsky->getRepostedBy( uri => 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Get repost records which reference a subject (by AT-URI and CID).

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

- `reply_gate`

    Arrayref of rules to restrict who can reply to this post.

    Supported rules:

    - `mention` - Only users mentioned in the post can reply.
    - `following` - Only users the author follows can reply.
    - `list` - Only users in a specific moderation list can reply (requires `reply_gate_list`).

    Example:

    ```perl
    $bsky->createPost( text => 'Private post', reply_gate => ['following'] );
    ```

- `reply_gate_list`

    The AT-URI of a moderation list to use with the `list` rule in `reply_gate`.

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

## `repost( ... )`

```
$bsky->repost( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post/3lcdwvquo7y25' );
```

Repost a post.

Expected parameters include:

- `uri` - required

    The AT-URI of the post.

- `cid`

    If undefined, the post is fetched to gather this for you.

## `deleteRepost( ... )`

```
$bsky->deleteRepost( 'at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.repost/3lcdwvquo7y25' );
```

Remove a repost record.

## `uploadBlob( ... )`

```perl
$bsky->uploadBlob( $data, mime_type => 'image/png' );
```

Upload a blob (file/data) to the PDS. This is a wrapper around `uploadFile`.

# Social Graph

Methods documented in this section deal with relationships between the authorized user and other members of the social
network.

## `block( ... )`

```
$bsky->block( 'sankorobinson.com' );
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

## `deleteBlock( ... )`

```
$bsky->deleteBlock( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.block/3l6oveex3ii2l' );
```

Unblocks a user by removing the block record.

## `follow( ... )`

```
$bsky->follow( 'sankorobinson.com' );
```

Follows a user.

## `deleteFollow( ... )`

```
$bsky->deleteFollow( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.follow/3l6oveex3ii2l' );
```

Unfollows a user by removing the follow record.

## `getFollows( ... )`

```
$bsky->getFollows( 'sankorobinson.com' );
```

Enumerates who an account is following.

## `getFollowers( ... )`

```
$bsky->getFollowers( 'sankorobinson.com' );
```

Enumerates who is following an account.

## `getKnownFollowers( ... )`

```
$bsky->getKnownFollowers( 'sankorobinson.com' );
```

Enumerates followers of an account that the authorized user also follows (mutuals).

## `getRelationships( ... )`

```perl
$bsky->getRelationships( actors => ['sankorobinson.com', 'bsky.app'] );
```

Enumerates relationships between the authorized user and other actors.

## `getMutes( ... )`

```
$bsky->getMutes();
```

Enumerate actors that the authorized user has muted.

## `muteThread( ... )`

```
$bsky->muteThread( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Mute a thread.

## `unmuteThread( ... )`

```
$bsky->unmuteThread( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l' );
```

Unmute a thread.

## `getLists( ... )`

```
$bsky->getLists( 'sankorobinson.com' );
```

Enumerate moderation lists created by an actor.

## `getList( ... )`

```
$bsky->getList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );
```

Get detailed view of a moderation list.

## `getStarterPack( ... )`

```
$bsky->getStarterPack( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.starterpack/3l6oveex3ii2l' );
```

Get a detailed view of a starter pack.

## `getStarterPacks( ... )`

```
$bsky->getStarterPacks( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.starterpack/3l6oveex3ii2l' );
```

Get views for a list of starter packs.

## `getActorStarterPacks( ... )`

```
$bsky->getActorStarterPacks( 'sankorobinson.com' );
```

Get starter packs created by an actor.

# Actors

Methods in this section deal with profile information and actor discovery.

## `getProfile( ... )`

```
$bsky->getProfile( 'sankorobinson.com' );
```

Get detailed profile view of an actor.

## `getPreferences( )`

```
$bsky->getPreferences();
```

Get private preferences for the authorized account.

## `putPreferences( ... )`

```
$bsky->putPreferences( [ ... ] );
```

Update private preferences for the authorized account.

## `upsertProfile( &callback )`

```perl
$bsky->upsertProfile( sub (%existing) {
    return { %existing, displayName => 'New Name' };
});
```

Retrieve the current profile, allow a callback to modify it, and then update it.

## `getProfiles( ... )`

```perl
$bsky->getProfiles( actors => ['sankorobinson.com', 'bsky.app'] );
```

Get detailed profile views of multiple actors.

## `getSuggestions( )`

```
$bsky->getSuggestions();
```

Get a list of suggested actors.

## `searchActors( ... )`

```perl
$bsky->searchActors( q => 'perl' );
```

Search for actors.

## `searchActorsTypeahead( ... )`

```perl
$bsky->searchActorsTypeahead( q => 'san' );
```

Find actor suggestions for a partial search term.

## `mute( ... )`

```
$bsky->mute( 'sankorobinson.com' );
```

Mutes an actor.

## `unmute( ... )`

```
$bsky->unmute( 'sankorobinson.com' );
```

Unmutes an actor.

## `muteModList( ... )`

```
$bsky->muteModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );
```

Mutes all actors in a moderation list.

## `unmuteModList( ... )`

```
$bsky->unmuteModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );
```

Unmutes all actors in a moderation list.

## `blockModList( ... )`

```
$bsky->blockModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.list/3l6oveex3ii2l' );
```

Blocks all actors in a moderation list.

## `unblockModList( ... )`

```
$bsky->unblockModList( 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.graph.listblock/3l6oveex3ii2l' );
```

Unblocks a moderation list.

# Moderation

## `mute( ... )`

```
$bsky->mute( 'sankorobinson.com' );
```

Mutes an actor.

## `unmute( ... )`

```
$bsky->unmute( 'sankorobinson.com' );
```

Unmutes an actor.

## `report( $subject, $reason_type, [ $reason ] )`

Submits a moderation report.

Expected parameters:

- `$subject` - The AT-URI or DID being reported.
- `$reason_type` - Lexicon-defined reason (e.g., `com.atproto.moderation.defs#reasonSpam`).
- `$reason` - Optional free-text description.

# Notifications

Methods in this section deal with notifications.

## `listNotifications( ... )`

```
$bsky->listNotifications();
```

Enumerate notifications for the authorized user.

## `countUnreadNotifications( )`

```
$bsky->countUnreadNotifications();
```

Count unread notifications.

## `updateSeenNotifications( [ $seenAt ] )`

```
$bsky->updateSeenNotifications();
```

Update when notifications were last seen.

# Identity

Methods in this section deal with handle and DID resolution.

## `resolveHandle( ... )`

```
$bsky->resolveHandle( 'sankorobinson.com' );
```

Resolves a handle to a DID.

## `updateHandle( ... )`

```
$bsky->updateHandle( 'new-handle.bsky.social' );
```

Updates the handle for the authorized user.

## `describeServer( )`

```
$bsky->describeServer();
```

Describes the server's account creation requirements and capabilities.

## `listRecords( ... )`

```perl
$bsky->listRecords( repo => 'sankorobinson.com', collection => 'app.bsky.feed.post' );
```

List records in a repository collection.

## `getLabelerServices( ... )`

```perl
$bsky->getLabelerServices( dids => [ ... ] );
```

Get views of labeler services.

# Chat

Methods in this section deal with direct messaging and conversations.

## `listConvos( [...] )`

```
$bsky->listConvos();
```

Enumerates conversations for the authorized user.

## `getConvo( $convoId )`

```
$bsky->getConvo( $convoId );
```

Get a detailed view of a conversation.

## `getConvoForMembers( actors => [ ... ] )`

```perl
$bsky->getConvoForMembers( actors => [ 'did:plc:...' ] );
```

Get or create a conversation for a list of members.

## `getMessages( convoId => ..., [...] )`

```perl
$bsky->getMessages( convoId => $convoId );
```

Get messages in a conversation.

## `sendMessage( $convoId, { text => ... } )`

```perl
$bsky->sendMessage( $convoId, { text => 'Hello!' } );
```

Send a message to a conversation.

## `acceptConvo( $convoId )`

```
$bsky->acceptConvo( $convoId );
```

Accept a conversation request.

## `leaveConvo( $convoId )`

```
$bsky->leaveConvo( $convoId );
```

Leave a conversation.

## `updateRead( $convoId, [ $messageId ] )`

```
$bsky->updateRead( $convoId );
```

Update the read status of a conversation.

## `muteConvo( $convoId )`

```
$bsky->muteConvo( $convoId );
```

Mute a conversation.

## `unmuteConvo( $convoId )`

```
$bsky->unmuteConvo( $convoId );
```

Unmute a conversation.

## `addReaction( $convoId, $messageId, $reaction )`

```
$bsky->addReaction( $convoId, $messageId, '👍' );
```

Add a reaction to a message.

## `removeReaction( $convoId, $messageId, $reaction )`

```
$bsky->removeReaction( $convoId, $messageId, '👍' );
```

Remove a reaction from a message.

## `deleteMessageForSelf( $convoId, $messageId )`

```
$bsky->deleteMessageForSelf( $convoId, $messageId );
```

Delete a message for the local user.

## `getConvoAvailability( [...] )`

```
$bsky->getConvoAvailability();
```

Check if the authorized user can join conversations.

## `getLog( [...] )`

```
$bsky->getLog();
```

Get a log of chat events.

# See Also

[At](https://metacpan.org/pod/At) - AT Protocol library

[App::bsky](https://metacpan.org/pod/App%3A%3Absky) - Bluesky client on the command line

[https://docs.bsky.app/docs/api/](https://docs.bsky.app/docs/api/)

# Perl Starter Pack

I've created a starter pack of Perl folks on Bluesky.

Follow it at [https://bsky.app/starter-pack/sankorobinson.com/3lk3xd5utq52s](https://bsky.app/starter-pack/sankorobinson.com/3lk3xd5utq52s) and get in touch to have yourself added.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
