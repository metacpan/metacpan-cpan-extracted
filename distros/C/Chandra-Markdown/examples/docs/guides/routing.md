# Routing with Markdown

Chandra::Markdown integrates with the Chandra SPA router via `render_dir`.
Each `.md` file becomes a route; clicking any nav link navigates to it without
a full page reload.

## How it works

```perl
my $nav = $md->render_dir('docs',
    base_route => '/docs',
    recursive  => 1,
);
```

1. Every `.md` file found is indexed and registered as a route.
2. The returned `<nav>` HTML contains one `<a>` per file.
3. Chandra's `_router_js` intercepts clicks and calls `navigate()` in Perl.
4. `navigate()` renders the route body and swaps `#chandra-content`.

## Subdirectories

Pass `recursive => 1` to include nested folders.
A file at `docs/guides/routing.md` becomes the route `/docs/guides/routing`.

## index.md

A file named `index.md` is treated as the section root.
`docs/index.md` → `/docs` instead of `/docs/index`.
