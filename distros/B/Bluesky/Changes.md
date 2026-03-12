# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.01] - 2026-03-12

### Added
- Adding support for `app.bsky.feed.postgate`.

### Changed
- Minor doc fixes.

## [1.00] - 2026-03-09
### Added
- Added `oauth_helper` method to provide a streamlined, interactive OAuth flow with an optional built-in redirect listener.
- Implemented functional Chat (Direct Messages) support via PDS proxying (`atproto-proxy`).
- Added `threadgate` support to `createPost` via the `reply_gate` parameter, allowing users to control who can reply to their posts.
- Added `getKnownFollowers` method for advanced social discovery (mutual followers).
- Added `report` method for official content reporting via Ozone (`com.atproto.moderation.createReport`).
- Added robust service-aware routing in `_at_for` to handle repo, feed, and chat lexicons transparently.
- Updated examples: `eg/bsky_auth.pl` and `eg/bsky_chat.pl` are now fully operational.
- Implemented missing methods: `repost`, `deleteRepost`, `uploadBlob`, `deleteBlock`, `follow`, `deleteFollow`, `getFollows`, `getFollowers`, `getRepostedBy`.

### Changed
- Refactored all repository-related sugary methods (`repost`, `like`, `block`, `follow`, `createPost`, `upsertProfile`, etc.) to use new high-level `At.pm` helpers, resulting in a cleaner and more maintainable codebase.
- Standardized internal implementation to use accessor methods (e.g., `$self->at`) instead of direct field access, improving testability and robustness.

### Fixed
- Fixed `oauth_helper` to use standard `Mojolicious` objects instead of `Mojolicious::Lite`, resolving "Modification of a read-only value" errors.
- Corrected OAuth scopes to use `transition:generic` and `transition:chat.bsky` for reliable chat authorization.
- Fixed sender handle display in `bsky_chat.pl` by mapping member DIDs to handles.
- Support for Bookmarks: `getBookmarks`, `createBookmark`, `deleteBookmark`.
- Feed Generator methods: `getFeed`, `getFeedSkeleton`, `getFeedGenerator`, `getFeedGenerators`, `getActorFeeds`, `getSuggestedFeeds`, `getPopularFeedGenerators`, `getTrends`, `describeFeedGenerator`.
- Social Graph features: `getRelationships`, `getMutes`, `muteThread`, `unmuteThread`, `getLists`, `getList`, `getKnownFollowers`, `getSuggestedFollowsByActor`.
- Actor features: `upsertProfile`, `getProfiles`, `getSuggestions`, `getSuggestionsSkeleton`, `searchActors`, `searchActorsTypeahead`, `mute`, `unmute`, `muteModList`, `unmuteModList`, `blockModList`, `unblockModList`, `getPreferences`, `putPreferences`.
- Notification features: `listNotifications`, `countUnreadNotifications`, `updateSeenNotifications`, `putNotificationPreferences`.
- Identity features: `resolveHandle`, `updateHandle`.
- Starter Pack support: `getStarterPack`, `getStarterPacks`, `getActorStarterPacks`.
- Drafts support: `getDrafts`, `createDraft`, `updateDraft`, `deleteDraft`.
- Chat (Direct Messages) support: `listConvos`, `getConvo`, `getConvoForMembers`, `getMessages`, `sendMessage`, `sendMessageToHandle`, `updateRead`, `muteConvo`, `unmuteConvo`.
- Video features: `getVideoUploadLimits`, `getVideoJobStatus`.
- Contact features: `importContacts`, `getContactMatches`.
- Miscellaneous methods: `describeServer`, `listRecords`, `getLabelerServices`.
- OAuth and Firehose wrapper methods.
- New examples (Bluesky auth, chat, firehose, etc.)
- Refactored `uploadFile` to use `HTTP::Tiny` directly, bypassing bugs in the underlying `At` module's UserAgent.

## [0.20] - 2024-12-31

### Added
- List, create, and delete records to block actors/accounts by name.
- Allow posts to be liked by their AT-URI.
- Allow likes to be deleted.
- Wrapping Bluesky's new `*.getTrendingTopics` lexicon.

## [0.19] - 2024-12-03

### Changed
- Split from At.pm.

[Unreleased]: https://github.com/sanko/Bluesky.pm/compare/1.01...HEAD
[1.01]: https://github.com/sanko/Bluesky.pm/compare/1.00...1.01
[1.00]: https://github.com/sanko/Bluesky.pm/compare/0.20...1.00
[0.20]: https://github.com/sanko/Bluesky.pm/compare/0.19...0.20
[0.19]: https://github.com/sanko/Bluesky.pm/releases/tag/0.19
