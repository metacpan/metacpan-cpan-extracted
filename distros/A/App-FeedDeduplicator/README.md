# App::FeedDeduplicator

A Perl application to aggregate, deduplicate, and republish web feeds. 

## Features

- Parses multiple feed URLs from a config file
- Detects duplicates (via canonical links or titles)
- Outputs a clean Atom, RSS, or JSON feed

## Usage

```sh
feed-deduplicator [config.json]
```

Will also look in the `FEED_DEDUP_CONFIG` env variable or `~/.feed-deduplicator/config.json` by default.
