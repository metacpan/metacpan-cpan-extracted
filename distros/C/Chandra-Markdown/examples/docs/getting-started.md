# Getting Started

## Installation

```
cpanm Chandra::Markdown
```

## Basic usage

```perl
use Chandra::App;
use Chandra::Markdown;

my $app = Chandra::App->new(title => 'My App', width => 900, height => 700);

$app->set_content('<div id="chandra-markdown" class="chandra-markdown"></div>');

my $md = Chandra::Markdown->new(app => $app);
$md->set("# Hello\nThis is **Markdown** rendered in a Chandra app.");

$app->run;
```

## Constructor options

| Option        | Default              | Description                        |
|---------------|----------------------|------------------------------------|
| `app`         | *(required)*         | Chandra app object                 |
| `gfm`         | `1`                  | Enable GitHub Flavored Markdown    |
| `hard_breaks` | `0`                  | Treat newlines as `<br>`           |
| `id`          | `chandra-markdown`   | Target element id                  |
| `css`         | `1`                  | Inject default stylesheet          |

## Rendering to a string

Use `render()` when you need the HTML without updating the webview:

```perl
my $html = $md->render("# Heading\nParagraph text.");
```
