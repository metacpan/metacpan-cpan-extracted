# Markdown Syntax Demo

## Emphasis

**bold text** and *italic text* and ~~strikethrough~~.

__bold underscore__ and _italic underscore_.

***bold italic*** and ___bold italic underscore___.

Mixed: **bold with *italic* inside** is not fully supported.

## Code

Inline `code` and multi-backtick `` `literal` `` example.

```bash
echo "fenced code block"
ls -la
```

## Links

[Greple](https://metacpan.org/pod/App::Greple) is a pattern matching tool.

See [mdee documentation](https://metacpan.org/pod/App::mdee) for details.

## Images

![Logo](https://example.com/logo.png)

[![Linked image](https://example.com/thumb.png)](https://example.com)

## Headings

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

## Blockquotes

> This is a blockquote with **bold** and `code`.
>
> > Nested quote with *italic*.

## Table

| Command | Description | Version |
| - | - | - |
| greple | Pattern matching | 10.04 |
| ansifold | Text folding | 2.26 |
| ansicolumn | Column formatting | 1.44 |
| nup | Multi-column output | 0.22 |

## Lists

- First item with `inline code` and a description long enough to demonstrate line folding behavior when the terminal width is narrower than the text content
- Second item with **bold** and *italic* and ***bold italic*** combined in a single line that also extends beyond the typical display width to show proper indentation after wrapping
- Third item with a [link](https://example.com) and `code` and ~~strikethrough~~ mixed together in a line that should definitely wrap at some point
  - Nested item with a longer description to verify that nested list indentation is preserved correctly when ansifold wraps the text at the configured width
  - Another nested item

1. Numbered list item with enough text to demonstrate that numbered list markers are handled correctly during the folding process and indentation is maintained
2. With **emphasis** and [links](https://example.com) and `inline code` all in one long line
3. Third numbered item

## Definition Lists

greple
: A pattern matching and highlighting tool with extensive regex support for syntax highlighting, used as the core engine for **mdee** Markdown rendering

ansifold
: An ANSI-aware text folding utility that wraps long lines while preserving escape sequences and maintaining proper indentation for nested list items

## Horizontal Rules

---

## Combined Formatting

> **Important:** Markers are hidden by default. Use `--no-theme` to show them.
>
> ***Bold italic*** in a blockquote with [a link](https://example.com).

## Escaped Characters

\**not bold\** and \~~not strike\~~.
