# Styling

Chandra::Markdown ships a default stylesheet scoped to `.chandra-markdown`.
It is injected via `$app->css()` during construction (unless `css => 0`).

## CSS custom properties

All colours use `--chandra-*` custom properties so they automatically
inherit from `Chandra::Theme` without any extra wiring.

| Property              | Default   | Used for                  |
|-----------------------|-----------|---------------------------|
| `--chandra-text`      | `#24292f` | Body text                 |
| `--chandra-border`    | `#d0d7de` | Lines, table borders      |
| `--chandra-link`      | `#0969da` | Links, active nav item    |
| `--chandra-code-bg`   | `#f6f8fa` | Inline code, code blocks  |
| `--chandra-muted`     | `#57606a` | Secondary text, scores    |
| `--chandra-sidebar-bg`| `#f6f8fa` | Sidebar background        |

## Overriding styles

Add your own rules after construction:

```perl
$app->css(q{
    .chandra-markdown { max-width: 720px; }
    .chandra-markdown code { font-size: .9em; }
});
```

## Disabling the default stylesheet

```perl
my $md = Chandra::Markdown->new(app => $app, css => 0);
```
