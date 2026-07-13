# API Reference

## Chandra::Markdown->new(%opts)

Constructs a new Markdown widget. `app` is required. Injects the default
stylesheet unless `css => 0` is passed.

## render($markdown)

Converts `$markdown` to an HTML string. Does not update the webview.
Returns an empty string if `$markdown` is `undef` or `''`.

```perl
my $html = $md->render("**bold**");  # => "<p><strong>bold</strong></p>\n"
```

## set($markdown)

Renders `$markdown` and replaces the innerHTML of the target element.
Returns `$self` for chaining.

```perl
$md->set("# New content");
```

## append($markdown)

Renders `$markdown` and appends it to the target element's innerHTML.
Returns `$self` for chaining.

```perl
$md->append("## Extra section\nMore text.");
```

## render_dir($dir, %opts)

Scans `$dir` for `.md` files, registers a route on the app for each,
and returns a `<nav>` HTML string of links.

```perl
my $nav = $md->render_dir('docs',
    recursive  => 1,
    base_route => '/docs',
    nav_id     => 'sidebar-nav',
    sort       => 'alpha',
    index      => 'index.md',
);
```

`index.md` is treated as the section root: its route is `$base_route`
rather than `$base_route/index`.

## _css()

Returns the embedded stylesheet string. Call `$app->inject_css(Chandra::Markdown::_css())`
if you want the styles without constructing a widget.
