# Heading 1

## Heading 2 with [link](https://example.com)

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

Normal text with **bold** and *italic* and ~~strikethrough~~.

Underscore bold: __double underscore__ and italic: _single underscore_.

`inline code with **not bold**`

More text with `code` inside.

Multi-backtick: `` `**` `` and ``` ``code`` ```.

```bash
echo "code block"
```

~~~python
print("tilde code block")
~~~

Nested code block (tilde wrapping backticks):

~~~markdown
Here is how to write a code block:

```bash
echo "Hello"
```
~~~

Four-space indented fence becomes content (CommonMark rule):

```markdown
- List item with code block:

    ```bash
    echo "indented code"
    ```
```

> blockquote with **bold** text

> nested > quote

---

***

[simple link](https://example.com)

![image alt](https://example.com/img.png)

[![linked image](https://example.com/img.png)](https://example.com)

<!-- HTML comment -->

<!--
multi-line comment
-->

## Heading with [link](https://example.com) inside

**bold with `code` inside**

Escaped: \**not bold\** and \`not code\`

Word boundaries: abc_def_ghi and foo__bar__baz and x___y___z.

## Table Example

|Name|Description|Status|
|-|-|-|
|greple|Pattern matching tool|active|
|ansifold|ANSI-aware text folding|active|
|ansicolumn|Column formatting with ANSI support|active|

## Aligned Table

| Left | Center | Right | Default |
|:-----|:------:|------:|---------|
| a    | b      | c     | d       |
| long | x      | y     | z       |

## List Example

- First item with `inline code`
- Second item with **bold text** and _italic_
- Third item with a longer description that might wrap to multiple lines when displayed in a narrow terminal window

## Definition List Example

greple
: Pattern matching and highlighting tool with extensive regex support for syntax highlighting

ansifold
: ANSI-aware text folding utility that wraps long lines while preserving escape sequences and maintaining proper indentation

Term with blank line

: Definition after a blank line with `inline code` and **bold text** that might wrap to multiple lines

## Headings with Indentation

   ### Indented heading 3

#Not a heading

####### Not a heading either

####

## Combined Emphasis

***bold italic*** and ___bold italic___ in a line.

## Fences

````markdown
Closing fence is longer than the opening one:
```
inner
```
`````

## Block Quotes

> A long block quote line is folded with the marker repeated on the continuation lines, so that the text stays inside the quote when the pane is narrow.

> > A nested quote repeats both markers on the continuation lines when it is long enough to be folded by the fold width.

> - A list item in a quote continues under its text and the list marker is not repeated, while the quote marker is repeated on each line.

   > An indented quote keeps its indentation before the marker on the continuation lines when it is folded.

> **Bold at the start** of a quote does not make the continuation lines bold when the line is long enough to be folded here.

> 引用の中の日本語の長い行も、引用符を繰り返しながら折り返されます。禁則処理も効くので、句読点や閉じ括弧が行頭に来ることはありません。

## Paragraphs for Refill

These three lines are one paragraph,
and `--refill` joins them into one line,
which is folded to the width of the pane.

A hard break with two spaces  
stays, and one with a backslash\
stays too, while an escaped backslash\\
does not make a break.

日本語の段落は
行をつなぐときに
空白を入れません。

Text right above a list:
- list item stays apart
- another item

> A quoted paragraph
> is joined too.

1. A list item with
   a continuation line

[^note]: A footnote definition
[^other]: stays on its own line

## Long Text

- 日本語の長いリスト項目は、単語の区切りではなく文字単位で折り返され、禁則処理によって句読点や閉じ括弧「」が行頭に来ないようになっています。
- A long item with a word that should not be broken in the middle: internationalization, and a [link inside](https://example.com/a/very/long/path/name) to fold around.

## Tables for Wrapping

Use `--ts=3line` or `--ts=simple` for the table styles, and a narrow `-w` to wrap the cells.

| Key | Description | Note |
|-----|-------------|------|
| k1 | The quick brown fox jumps over the lazy dog, and the description goes on so that it does not fit in the width of a pane | short |
| k2 | 日本語のセルも幅に合わせて折り返され、禁則処理が効きます。長い説明が続いても表の形は崩れません。 | 備考 |
| k3 | **bold** and `code` and [link](https://example.com) in a cell, and an escaped \| pipe stays in its cell | x |

A table with spaces after the last pipe is still one table:

| a | b |   
|---|---|   
| 1 | 2 |   
| 3 | 4 |   

## Colors in the File

Colors stay: [31mred[m, [38;2;0;128;0mgreen[m and [4:3mcurly underline[m.
