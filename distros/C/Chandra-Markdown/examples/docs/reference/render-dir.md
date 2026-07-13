# render_dir

```perl
my $nav = $md->render_dir($dir, %opts);
```

Scans `$dir` for `.md` files, registers a Chandra route for each,
indexes the content for search, and returns a `<nav>` HTML string.

## Options

| Option        | Default      | Description                                        |
|---------------|--------------|----------------------------------------------------|
| `base_route`  | `/docs`      | URL prefix for all generated routes                |
| `recursive`   | `0`          | Descend into subdirectories                        |
| `nav_id`      | `chandra-markdown-nav` | `id` on the returned `<nav>` element  |
| `sort`        | `alpha`      | `alpha` or `mtime`                                 |
| `index`       | `index.md`   | Filename treated as section root                   |

## Title extraction

The title for each file is the text of the first `# Heading` line.
If no heading is found, the filename is used with hyphens/underscores
replaced by spaces and the first letter uppercased.

## index.md

A file matching the `index` option becomes the section root:
`docs/index.md` → `/docs` (not `/docs/index`).
Subdirectory index files follow the same rule:
`docs/guides/index.md` → `/docs/guides`.

## Route callbacks

Each registered route opens the file, renders its Markdown, and returns
the HTML string to the Chandra router. The file is read fresh on every
navigation — no caching.

## Side effects

- Registers routes on `$app` via `$app->route`.
- Indexes document content into the trigram index for `search()`.
- Appends each route to `$md->_dir_routes`.
