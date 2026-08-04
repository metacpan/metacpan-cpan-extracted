# Audio::Scrobbler2

[![Tests](https://github.com/Perdolique/Audio-Scrobbler2/actions/workflows/test.yml/badge.svg)](https://github.com/Perdolique/Audio-Scrobbler2/actions/workflows/test.yml)

`Audio::Scrobbler2` is a small synchronous client for the Last.fm desktop
authentication flow and track scrobbling API.

## Requirements

- Perl 5.26 or newer
- A Last.fm API key and shared secret

## Installation

```console
cpanm Audio::Scrobbler2
```

## Usage

```perl
use Audio::Scrobbler2;

my $scrobbler = Audio::Scrobbler2->new($api_key, $api_secret);
my $token = $scrobbler->auth_getToken;

# Ask the user to authorize the token:
# https://www.last.fm/api/auth/?api_key=$api_key&token=$token

my $session_key = $scrobbler->auth_getSession;

$scrobbler->track_updateNowPlaying('Artist Name', 'Track Name');
$scrobbler->track_scrobble(
    'Artist Name',
    'Track Name',
    $playback_started_at,
);
```

An existing session key can be restored without repeating authentication:

```perl
$scrobbler->set_session_key($session_key);
```

All validation, transport, HTTP, JSON, and Last.fm API failures throw
exceptions. Submission requests are never retried automatically because a
retry could create a duplicate scrobble.

## Migrating from 0.05

Version 1.00 contains two breaking changes:

- `track_scrobble` requires a positive integer Unix timestamp for when
  playback started.
- All failures throw exceptions instead of returning `0` or inconsistent
  error structures.

The constructor and existing method names are unchanged.

## Development

The test suite uses an in-process fake HTTP client and never calls Last.fm:

```console
perl Makefile.PL
make test
make disttest
```

## Author

Pier Dolique ([Perdolique](https://github.com/Perdolique)),
`baget@cpan.org`

CPAN ID: `BAGET`

## License

Copyright 2012-2026 Pier Dolique.

This software is available under the same terms as Perl itself.
