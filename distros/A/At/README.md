[![Actions Status](https://github.com/sanko/At.pm/actions/workflows/linux.yaml/badge.svg)](https://github.com/sanko/At.pm/actions) [![Actions Status](https://github.com/sanko/At.pm/actions/workflows/windows.yaml/badge.svg)](https://github.com/sanko/At.pm/actions) [![Actions Status](https://github.com/sanko/At.pm/actions/workflows/osx.yaml/badge.svg)](https://github.com/sanko/At.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/At.svg)](https://metacpan.org/release/At)
# NAME

At - The AT Protocol for Social Networking

# SYNOPSIS

```perl
use At;
my $at = At->new( host => 'https://fun.example' );
$at->server_createSession( 'sanko', '1111-aaaa-zzzz-0000' );
$at->repo_createRecord(
    $at->did,
    'app.bsky.feed.post',
    { '$type' => 'app.bsky.feed.post', text => 'Hello world! I posted this via the API.', createdAt => time }
);
```

# DESCRIPTION

Bluesky is backed by the AT Protocol, a "social networking technology created to power the next generation of social
applications."

At.pm uses perl's new class system which requires perl 5.38.x or better and, like the protocol itself, is still under
development.

## At::Bluesky

At::Bluesky is a subclass with the host set to `https://bluesky.social` and all the lexicon related to the social
networking site included.

## App Passwords

Taken from the AT Protocol's official documentation:

<div>
    <blockquote>
</div>

For the security of your account, when using any third-party clients, please generate an [app
password](https://atproto.com/specs/xrpc#app-passwords) at Settings > Advanced > App passwords.

App passwords have most of the same abilities as the user's account password, but they're restricted from destructive
actions such as account deletion or account migration. They are also restricted from creating additional app passwords.

<div>
    </blockquote>
</div>

Read their disclaimer here: [https://atproto.com/community/projects#disclaimer](https://atproto.com/community/projects#disclaimer).

# Methods

The API attempts to follow the layout of the underlying protocol so changes to this module might be beyond my control.

## `new( ... )`

Creates an AT client and initiates an authentication session.

```perl
my $at = At->new( host => 'https://bsky.social' );
```

Expected parameters include:

- `host` - required

    Host for the account. If you're using the 'official' Bluesky, this would be 'https://bsky.social' but you'll probably
    want `At::Bluesky->new(...)` because that client comes with all the bits that aren't part of the core protocol.

## `resume( ... )`

Resumes an authenticated session.

```perl
my $at = At->resume( $session );
```

Expected parameters include:

- `session` - required

## `session( )`

Returns data which may be used to resume an authenticated session.

```perl
my $restore = $at->session;
```

Note that this data is subject to change in line with the AT protocol.

## `admin_deleteCommunicationTemplate( ... )`

```
$at->admin_deleteCommunicationTemplate( 99999 );
```

Delete a communication template.

Expected parameters include:

- `id` - required

    ID of the template.

Returns a true value on success.

## `admin_disableAccountInvites( ... )`

Disable an account from receiving new invite codes, but does not invalidate existing codes.

Expected parameters include:

- `account` - required

    DID of account to modify.

- `note`

    Optional reason for disabled invites.

## `admin_disableInviteCodes( )`

Disable some set of codes and/or all codes associated with a set of users.

Expected parameters include:

- `codes`

    List of codes.

- `accounts`

    List of account DIDs.

## `admin_createCommunicationTemplate( ... )`

```
$at->admin_createCommunicationTemplate( 'warning_1', 'Initial Warning for [...]', 'You are being alerted [...]' );
```

Administrative action to create a new, re-usable communication (email for now) template.

Expected parameters include:

- `name` - required

    Name of the template.

- `subject` - required

    Subject of the message, used in emails.

- `contentMarkdown` - required

    Content of the template, markdown supported, can contain variable placeholders.

- `createdBy`

    DID of the user who is creating the template.

Returns a true value on success.

## `admin_deleteAccount( ... )`

```
$at->admin_deleteAccount( 'did://...' );
```

Delete a user account as an administrator.

Expected parameters include:

- `did` - required

Returns a true value on success.

## `admin_emitModerationEvent( ..., [...] )`

```
$at->admin_emitModerationEvent( ... );
```

Take a moderation action on an actor.

Expected parameters include:

- `event` - required
- `subject` - required
- `createdBy` - required
- `subjectBlobCids`

Returns a new `At::Lexicon::com::atproto::admin::modEventView` object on success.

## `admin_enableAccountInvites( ..., [...] )`

```
$at->admin_enableAccountInvites( 'did://...' );
```

Re-enable an account's ability to receive invite codes.

Expected parameters include:

- `account` - required
- `note`

    Optional reason for enabled invites.

Returns a true value on success.

## `admin_getAccountInfo( ..., [...] )`

```
$at->admin_getAccountInfo( 'did://...' );
```

Get details about an account.

Expected parameters include:

- `did` - required

Returns a new `At::Lexicon::com::atproto::admin::accountView` object on success.

## `admin_getAccountsInfo( ... )`

```
$at->admin_getAccountsInfo( 'did://...', 'did://...' );
```

Get details about some accounts.

Expected parameters include:

- `dids` - required

Returns an info list of new `At::Lexicon::com::atproto::admin::accountView` objects on success.

## `admin_getInviteCodes( [...] )`

```
$at->admin_getInviteCodes( );
```

Get an admin view of invite codes.

Expected parameters include:

- `sort`

    Order to sort the codes: 'recent' or 'usage' with 'recent' being the default.

- `limit`

    How many codes to return. Minimum of 1, maximum of 500, default of 100.

- `cursor`

Returns a new `At::Lexicon::com::atproto::server::inviteCode` object on success.

## `admin_getModerationEvent( ... )`

```
$at->admin_getModerationEvent( 77736393829 );
```

Get details about a moderation event.

Expected parameters include:

- `id` - required

Returns a new `At::Lexicon::com::atproto::admin::modEventViewDetail` object on success.

## `admin_getRecord( ..., [...] )`

```
$at->admin_getRecord( 'at://...' );
```

Get details about a record.

Expected parameters include:

- `uri` - required
- `cid`

Returns a new `At::Lexicon::com::atproto::admin::recordViewDetail` object on success.

## `admin_getRepo( ... )`

```
$at->admin_getRepo( 'did:...' );
```

Get details about a repository.

Expected parameters include:

- `did` - required

Returns a new `At::Lexicon::com::atproto::admin::repoViewDetail` object on success.

## `admin_getSubjectStatus( [...] )`

```
$at->admin_getSubjectStatus( 'did:...' );
```

Get details about a repository.

Expected parameters include:

- `did`
- `uri`
- `blob`

Returns a subject and, optionally, the takedown reason as a new `At::Lexicon::com::atproto::admin::statusAttr` object
on success.

## `admin_listCommunicationTemplates( )`

```
$at->admin_listCommunicationTemplates( );
```

Get list of all communication templates.

Returns a list of communicationTemplates as new `At::Lexicon::com::atproto::admin::communicationTemplateView` objects
on success.

## `admin_queryModerationEvents( [...] )`

```
$at->admin_queryModerationEvents( 'did:...' );
```

List moderation events related to a subject.

Expected parameters include:

- `types`

    The types of events (fully qualified string in the format of `com.atproto.admin#modEvent...`) to filter by. If not
    specified, all events are returned.

- `createdBy`
- `sortDirection`

    Sort direction for the events. `asc` or `desc`. Defaults to descending order of created at timestamp.

- `subject`
- `includeAllUserRecords`

    If true, events on all record types (posts, lists, profile etc.) owned by the did are returned.

- `limit`

    Minimum is 1, maximum is 100, 50 is the default.

- `cursor`

Returns a list of events as new `At::Lexicon::com::atproto::admin::modEventView` objects on success.

## `admin_queryModerationStatuses( [...] )`

```perl
$at->admin_queryModerationStatuses( 'did:...' );
```

List moderation events related to a subject.

Expected parameters include:

- `subject`
- `comment`

    Search subjects by keyword from comments.

- `reportedAfter`

    Search subjects reported after a given timestamp.

- `reportedBefore`

    Search subjects reported before a given timestamp.

- `reviewedAfter`

    Search subjects reviewed after a given timestamp.

- `reviewedBefore`

    Search subjects reviewed before a given timestamp.

- `includeMuted`

    By default, we don't include muted subjects in the results. Set this to true to include them.

- `reviewState`

    Specify when fetching subjects in a certain state.

- `ignoreSubjects`
- `lastReviewedBy`

    Get all subject statuses that were reviewed by a specific moderator.

- `sortField`

    `lastReviewedAt` or `lastReportedAt`, which is the default.

- `sortDirection`

    `asc` or `desc`, which is the default.

- `takendown`

    Get subjects that were taken down.

- `limit`

    Minimum of 1, maximum is 100, the default is 50.

- `cursor`

Returns a list of subject statuses as new `At::Lexicon::com::atproto::admin::subjectStatusView` objects on success.

## `admin_searchRepos( [...] )`

```
$at->admin_searchRepos( 'hydra' );
```

Find repositories based on a search term.

Expected parameters include:

- `query`
- `limit`

    Minimum of 1, maximum is 100, the default is 50.

- `cursor`

Returns a list of repos as new `At::Lexicon::com::atproto::admin::repoView` objects on success.

## `admin_sendEmail( ..., [...] )`

```
$at->admin_sendEmail( 'did:...', 'Hi!', 'did:...' );
```

Send email to a user's account email address.

Expected parameters include:

- `recipientDid` - required
- `senderDid` - required
- `content` - required
- `subject`
- `comment`

    Additional comment by the sender that won't be used in the email itself but helpful to provide more context for
    moderators/reviewers.

Returns a sent status boolean.

## `admin_updateAccountEmail( ... )`

```
$at->admin_updateAccountEmail( 'atproto2.bsky.social', 'contact@example.com' );
```

Administrative action to update an account's email.

Expected parameters include:

- `account` - required

    The handle or DID of the repo.

- `email` - required

Returns a true value on success.

## `admin_updateAccountHandle( ... )`

```
$at->admin_updateAccountHandle( 'did:...', 'atproto2.bsky.social' );
```

Administrative action to update an account's handle.

Expected parameters include:

- `did` - required
- `handle` - required

Returns a true value on success.

## `admin_updateCommunicationTemplate( ... )`

```
$at->admin_updateCommunicationTemplate( 999999, 'warning_1', 'First Warning for [...]' );
```

Administrative action to update an existing communication template. Allows passing partial fields to patch specific
fields only.

Expected parameters include:

- `id` - required

    ID of the template to be updated.

- `name`

    Name of the template.

- `contentMarkdown`

    Content of the template, markdown supported, can contain variable placeholders.

- `subject`

    Subject of the message, used in emails.

- `updatedBy`

    DID of the user who is updating the template.

- `disabled`

    Boolean.

Returns a true value on success.

## `admin_updateSubjectStatus( ..., [...] )`

```
$at->admin_updateSubjectStatus( ... );
```

Update the service-specific admin status of a subject (account, record, or blob).

Expected parameters include:

- `subject` - required
- `takedown`

Returns the subject and takedown objects on success.

## `identity_resolveHandle( ... )`

```
$at->identity_resolveHandle( 'atproto.bsky.social' );
```

Provides the DID of a repo.

Expected parameters include:

- `handle` - required

    The handle to resolve.

Returns the DID on success.

## `identity_updateHandle( ... )`

```
$at->identity_updateHandle( 'atproto.bsky.social' );
```

Updates the handle of the account.

Expected parameters include:

- `handle` - required

Returns a true value on success.

## `label_queryLabels( ... )`

```
$at->label_queryLabels( '' );
```

Find labels relevant to the provided URI patterns.

Expected parameters include:

- `uriPatterns` - required

    List of AT URI patterns to match (boolean 'OR'). Each may be a prefix (ending with '\*'; will match inclusive of the
    string leading to '\*'), or a full URI.

- `sources`

    Optional list of label sources (DIDs) to filter on.

- `limit`

    Number of results to return. 250 max. Default is 50.

- `cursor`

On success, labels are returned as a list of new `At::Lexicon::com::atproto::label` objects.

## `label_subscribeLabels( ..., [...] )`

```perl
$at->label_subscribeLabels( sub { ... } );
```

Subscribe to label updates.

Expected parameters include:

- `callback` - required

    Code reference triggered with every event.

- `cursor`

    The last known event to backfill from.

On success, a websocket is initiated. Events we receive include
`At::Lexicon::com::atproto::label::subscribeLables::labels` and
`At::Lexicon::com::atproto::label::subscribeLables::info` objects.

## `label_subscribeLabels_p( ..., [...] )`

```perl
$at->label_subscribeLabels_p( sub { ... } );
```

Subscribe to label updates.

Expected parameters include:

- `callback` - required

    Code reference triggered with every event.

- `cursor`

    The last known event to backfill from.

On success, a websocket is initiated and a promise is returned. Events we receive include
`At::Lexicon::com::atproto::label::subscribeLables::labels` and
`At::Lexicon::com::atproto::label::subscribeLables::info` objects.

## `moderation_createReport( ..., [...] )`

```perl
$at->moderation_createReport( { '$type' => 'com.atproto.moderation.defs#reasonSpam' }, { '$type' => 'com.atproto.repo.strongRef', uri => ..., cid => ... } );
```

Report a repo or a record.

Expected parameters include:

- `reasonType` - required

    An `At::Lexicon::com::atproto::moderation::reasonType` object.

- `subject` - required

    An `At::Lexicon::com::atproto::admin::repoRef` or `At::Lexicon::com::atproto::repo::strongRef` object.

- `reason`

On success, an id, the original reason type, subject, and reason, are returned as well as the DID of the user making
the report and a timestamp.

## `repo_applyWrites( ..., [...] )`

```
$at->repo_applyWrites( $at->did, [ ... ] );
```

Apply a batch transaction of creates, updates, and deletes.

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

- `writes`

    Array of [At::Lexicon::com::atproto::repo::applyWrites::create](https://metacpan.org/pod/At%3A%3ALexicon%3A%3Acom%3A%3Aatproto%3A%3Arepo%3A%3AapplyWrites%3A%3Acreate),
    [At::Lexicon::com::atproto::repo::applyWrites::update](https://metacpan.org/pod/At%3A%3ALexicon%3A%3Acom%3A%3Aatproto%3A%3Arepo%3A%3AapplyWrites%3A%3Aupdate), or [At::Lexicon::com::atproto::repo::applyWrites::delete](https://metacpan.org/pod/At%3A%3ALexicon%3A%3Acom%3A%3Aatproto%3A%3Arepo%3A%3AapplyWrites%3A%3Adelete)
    objects.

- `validate` - required

    Flag for validating the records.

- `swapCommit`

Returns a true value on success.

## `repo_createRecord( ... )`

Create a new record.

```perl
$at->repo_createRecord(
    repo       => $at->did,
    collection => 'app.bsky.feed.post',
    record     => { '$type' => 'app.bsky.feed.post', text => "Hello world! I posted this via the API.", createdAt => gmtime->datetime . 'Z' }
);
```

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

- `collection` - required

    The NSID of the record collection.

- `record` - required

    The record to create.

- `validate`

    Flag for validating the record.

- `swapCommit`

    Compare and swap with the previous commit by CID.

- `rkey`

    The key of the record.

Returns the uri and cid of the newly created record on success.

## `repo_deleteRecord( ... )`

Create a new record.

```perl
$at->repo_deleteRecord( repo => $at->did, collection => 'app.bsky.feed.post', rkey => '3kiburrigys27' );
```

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

- `collection` - required

    The NSID of the record collection.

- `rkey`

    The key of the record.

- `swapRecord`

    Compare and swap with the previous record by CID.

- `swapCommit`

    Compare and swap with the previous commit by CID.

Returns a true value on success.

## `repo_describeRepo( ... )`

```
$at->repo_describeRepo( $at->did );
```

Get information about the repo, including the list of collections.

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

On success, returns the repo's handle, did, a didDoc, a list of supported collections, a flag indicating whether or not
the handle is correct.

## `repo_getRecord( ... )`

```perl
$at->repo_getRecord( repo => $at->did, collection => 'app.bsky.feed.post', rkey => '3kiburrigys27' );
```

Get a record.

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

- `collection` - required

    The NSID of the record collection.

- `rkey` - required

    The key of the record.

- `cid`

    The CID of the version of the record. If not specified, then return the most recent version.

Returns the uri, value, and, optionally, cid of the requested record on success.

## `repo_listRecords( ..., [...] )`

```
$at->repo_listRecords( $at->did, 'app.bsky.feed.post' );
```

List a range of records in a collection.

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

- `collection` - required

    The NSID of the record type.

- `limit`

    The number of records to return.

    Maximum is 100, minimum is 1, default is 50.

- `reverse`

    Flag to reverse the order of the returned records.

- `cursor`

## `repo_putRecord( ... )`

```perl
$at->repo_putRecord( repo => $at->did, collection => 'app.bsky.feed.post', rkey => 'aaaaaaaaaaaaaaa', ... );
```

Write a record, creating or updating it as needed.

Expected parameters include:

- `repo` - required

    The handle or DID of the repo.

- `collection` - required

    The NSID of the record collection.

- `rkey` - required

    The key of the record.

- `record` - required

    The record to write.

- `validate`

    Flag for validating the record.

- `swapRecord`

    Compare and swap with the previous record by CID.

- `swapCommit`

    Compare and swap with the previous commit by CID.

Returns the record's uri and cid on success.

## `repo_uploadBlob( ..., [...] )`

Upload a new blob to be added to repo in a later request.

Expected parameters include:

- `blob` - required
- `type` - optional `Content-type` header value

On success, the mime type, size, and a link reference are returned.

## `server_createSession( ... )`

```
$at->server_createSession( 'sanko', '1111-2222-3333-4444' );
```

Create an authentication session.

Expected parameters include:

- `identifier` - required

    Handle or other identifier supported by the server for the authenticating user.

- `password` - required

On success, the access and refresh JSON web tokens, the account's handle, DID and (optionally) other data is returned.

## `server_describeServer( )`

Get a document describing the service's accounts configuration.

```
$at->server_describeServer( );
```

This method does not require an authenticated session.

Returns a list of available user domains and, optionally, boolean values indicating whether an invite code and/or phone
verification are required, and links to the TOS and privacy policy.

## `server_listAppPasswords( )`

```
$at->server_listAppPasswords( );
```

List all App Passwords.

Returns a list of passwords as new `At::Lexicon::com::atproto::server::listAppPasswords::appPassword` objects.

## `server_getSession( )`

```
$at->server_getSession( );
```

Get information about the current session.

Returns the handle, DID, and (optionally) other data.

## `server_getAccountInviteCodes( )`

```
$at->server_getAccountInviteCodes( );
```

Get all invite codes for a given account.

Returns codes as a list of new `At::Lexicon::com::atproto::server::inviteCode` objects.

## `server_getAccountInviteCodes( [...] )`

```
$at->server_getAccountInviteCodes( );
```

Get all invite codes for a given account.

Expected parameters include:

- `includeUsed`

    Optional boolean flag.

- `createAvailable`

    Optional boolean flag.

Returns a list of `At::Lexicon::com::atproto::server::inviteCode` objects on success. Note that this method returns an
error if the session was authorized with an app password.

## `server_updateEmail( ..., [...] )`

```
$at->server_updateEmail( 'smith...@gmail.com' );
```

Update an account's email.

Expected parameters include:

- `email` - required
- `token`

    This method requires a token from `requestEmailUpdate( ... )` if the account's email has been confirmed.

## `server_requestEmailUpdate( ... )`

```
$at->server_requestEmailUpdate( 1 );
```

Request a token in order to update email.

Expected parameters include:

- `tokenRequired` - required

    Boolean value.

## `server_revokeAppPassword( ... )`

```
$at->server_revokeAppPassword( 'Demo App [beta]' );
```

Revoke an App Password by name.

Expected parameters include:

- `name` - required

## `server_resetPassword( ... )`

```
$at->server_resetPassword( 'fdsjlkJIofdsaf89w3jqirfu2q8docwe', '****************' );
```

Reset a user account password using a token.

Expected parameters include:

- `token` - required
- `password` - required

## `server_resetPassword( ... )`

```
$at->server_resetPassword( 'fdsjlkJIofdsaf89w3jqirfu2q8docwe', '****************' );
```

Reset a user account password using a token.

Expected parameters include:

- `token` - required
- `password` - required

## `server_reserveSigningKey( [...] )`

```
$at->server_reserveSigningKey( 'did:...' );
```

Reserve a repo signing key for account creation.

Expected parameters include:

- `did`

    The did to reserve a new did:key for.

On success, a public signing key in the form of a did:key is returned.

## `server_requestPasswordReset( [...] )`

```
$at->server_requestPasswordReset( 'smith...@gmail.com' );
```

Initiate a user account password reset via email.

Expected parameters include:

- `email` - required

## `server_requestEmailConfirmation( )`

```
$at->server_requestEmailConfirmation( );
```

Request an email with a code to confirm ownership of email.

## `server_refreshSession( ... )`

```
$at->server_refreshSession( 'eyJhbGc...' );
```

Refresh an authentication session.

Expected parameters include:

- `refreshJwt` - required

    Refresh token returned as part of the response from `server_createSession( ... )`.

On success, new access and refresh JSON web tokens are returned along with the account's handle, DID and (optionally)
other data.

## `server_requestAccountDelete( )`

```
$at->server_requestAccountDelete( );
```

Initiate a user account deletion via email.

## `server_deleteSession( )`

```
$at->server_deleteSession( );
```

Initiate a user account deletion via email.

## `server_deleteAccount( )`

```
$at->server_deleteAccount( );
```

Delete an actor's account with a token and password.

Expected parameters include:

- `did` - required
- `password` - required
- `token` - required

## `server_createInviteCodes( ..., [...] )`

```
$at->server_createInviteCodes( 1, 1 );
```

Create invite codes.

Expected parameters include:

- `codeCount` - required

    The number of codes to create. Default value is 1.

- `useCount` - required

    Int.

- `forAccounts`

    List of DIDs.

On success, returns a list of new `At::Lexicon::com::atproto::server::createInviteCodes::accountCodes` objects.

## `server_createInviteCode( ..., [...] )`

```
$at->server_createInviteCode( 1 );
```

Create an invite code.

Expected parameters include:

- `useCount` - required

    Int.

- `forAccounts`

    List of DIDs.

On success, a new invite code is returned.

## `server_createAppPassword( ..., [...] )`

```
$at->server_createAppPassword( 'AT Client [release]' );
```

Create an App Password.

Expected parameters include:

- `name` - required

On success, a new `At::Lexicon::com::atproto::server::createAppPassword::appPassword` object.

## `server_createAccount( ..., [...] )`

```
$at->server_createAccount( 'jsmith....', '*********' );
```

Create an account.

Expected parameters include:

- `handle` - required
- `email`
- `password`
- `inviteCode`
- `did`
- `recoveryKey`
- `plcOP`

On success, JSON web access and refresh tokens, the handle, did, and (optionally) a server defined didDoc are returned.

## `server_confirmEmail( ... )`

```
$at->server_confirmEmail( 'jsmith...@gmail.com', 'idkidkidkidkdifkasjkdfsaojfd' );
```

Confirm an email using a token from `requestEmailConfirmation( )`,

Expected parameters include:

- `email` - required
- `token` - required

## `sync_getBlocks( ... )`

```
$at->sync_getBlocks( 'did...' );
```

Get blocks from a given repo.

Expected parameters include

- `did` - required

    The DID of the repo.

- `cids` - required

## `sync_getLatestCommit( ... )`

```
$at->sync_getLatestCommit( 'did...' );
```

Get the current commit CID & revision of the repo.

Expected parameters include:

- `did` - required

    The DID of the repo.

Returns the revision and cid on success.

## `sync_getRecord( ..., [...] )`

```
$at->sync_getRecord( 'did...', ... );
```

Get blocks needed for existence or non-existence of record.

Expected parameters include:

- `did` - required

    The DID of the repo.

- `collection` - required

    NSID.

- `rkey` - required
- `commit`

    An optional past commit CID.

## `sync_getRepo( ... )`

```
$at->sync_getRepo( 'did...', ... );
```

Gets the DID's repo, optionally catching up from a specific revision.

Expected parameters include:

- `did` - required

    The DID of the repo.

- `since`

    The revision of the repo to catch up from.

## `sync_listBlobs( ..., [...] )`

```
$at->sync_listBlobs( 'did...' );
```

List blob CIDs since some revision.

Expected parameters include:

- `did` - required

    The DID of the repo.

- `since`

    on of the repo to list blobs since.

- `limit`

    Minimum is 1, maximum is 1000, default is 500.

- `cursor`

On success, a list of cids is returned and, optionally, a cursor.

## `sync_listRepos( [...] )`

```
$at->sync_listRepos( );
```

List DIDs and root CIDs of hosted repos.

Expected parameters include:

- `limit`

    Maximum is 1000, minimum is 1, default is 500.

- `cursor`

On success, a list of `At::Lexicon::com::atproto::sync::repo` objects is returned and, optionally, a cursor.

## `sync_notifyOfUpdate( ... )`

```
$at->sync_notifyOfUpdate( 'example.com' );
```

Notify a crawling service of a recent update; often when a long break between updates causes the connection with the
crawling service to break.

Expected parameters include:

- `hostname` - required

    Hostname of the service that is notifying of update.

Returns a true value on success.

## `sync_requestCrawl( ... )`

```
$at->sync_requestCrawl( 'example.com' );
```

Request a service to persistently crawl hosted repos.

Expected parameters include:

- `hostname` - required

    Hostname of the service that is requesting to be crawled.

Returns a true value on success.

## `sync_getBlob( ... )`

```
$at->sync_getBlob( 'did...', ... );
```

Get a blob associated with a given repo.

Expected parameters include:

- `did` - required

    The DID of the repo.

- `cid` - required

    The CID of the blob to fetch.

## `sync_subscribeRepos( ... )`

```perl
$at->sync_subscribeRepos( sub {...} );
```

Subscribe to repo updates.

Expected parameters include:

- `cb` - required
- `cursor`

    The last known event to backfill from.

## `sync_subscribeRepos_p( ... )`

TODO

## `temp_checkSignupQueue( [...] )`

```
$at->temp_checkSignupQueue;
```

Check accounts location in signup queue.

Returns a boolean indicating whether signups are activated and, optionally, the estimated time and place in the queue
the account is on success.

## `temp_fetchLabels( [...] )`

```
$at->temp_fetchLabels;
```

Fetch all labels from a labeler created after a certain date.

Expected parameters include:

- `since`
- `limit`

    Default is 50, minimum is 1, maximum is 250.

Returns a list of labels as new `At::Lexicon::com::atproto::label` objects on success.

## `temp_pushBlob( ... )`

```
$at->temp_pushBlob( 'did:...' );
```

Gets the did's repo, optionally catching up from a specific revision.

Expected parameters include:

- `did` - required

    The DID of the repo.

## `temp_transferAccount( ... )`

```
$at->temp_transferAccount( ... );
```

Transfer an account.

Expected parameters include:

- `handle` - required
- `did` - required
- `plcOp` - required

## `temp_importRepo( ... )`

```
$at->temp_importRepo( 'did...' );
```

Gets the did's repo, optionally catching up from a specific revision.

Expected parameters include:

- `did` - required

    The DID of the repo.

## `temp_requestPhoneVerification( ... )`

```
$at->temp_requestPhoneVerification( '2125551000' );
```

Request a verification code to be sent to the supplied phone number.

Expected parameters include:

- `phoneNumber` - required

    Phone number

Returns a true value on success.

# See Also

[App::bsky](https://metacpan.org/pod/App%3A%3Absky) - Bluesky client on the command line

[https://atproto.com/](https://atproto.com/)

[https://bsky.app/profile/atperl.bsky.social](https://bsky.app/profile/atperl.bsky.social)

[Bluesky on Wikipedia.org](https://en.wikipedia.org/wiki/Bluesky_\(social_network\))

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
