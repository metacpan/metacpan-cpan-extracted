# render

```perl
my $html = $md->render($markdown);
```

Converts a Markdown string to HTML using the configured `Markdown::Simple`
renderer. Does **not** update the webview — use `set()` or `append()` for that.

Returns an empty string if `$markdown` is `undef` or `''`.

## Options (set at construction)

| Attribute     | Effect                                      |
|---------------|---------------------------------------------|
| `gfm => 1`    | GitHub Flavored Markdown (default)          |
| `gfm => 0`    | Strict CommonMark                           |
| `hard_breaks` | Treat bare newlines as `<br>` (default off) |

## GFM extensions enabled by default

- Tables
- Strikethrough (`~~text~~`)
- Task lists (`- [x] done`)
- Autolinks (bare URLs become `<a>`)
- Fenced code blocks with language hints
