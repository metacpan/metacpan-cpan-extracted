# Welcome

This is the home page of the documentation.

Getting started is easy — choose a topic from the navigation on the left.

## Overview

Chandra::Markdown renders GitHub Flavored Markdown inside your Chandra app.
It supports:

- **Tables** — pipe-delimited, auto-aligned
- **Strikethrough** — `~~like this~~`
- **Task lists** — `- [x] done` / `- [ ] todo`
- **Fenced code blocks** — with language hints
- **Autolinks** — bare URLs become clickable

## Quick example

```perl
my $md = Chandra::Markdown->new(app => $app);
$md->set("# Hello\nThis is **Markdown**.");
```
