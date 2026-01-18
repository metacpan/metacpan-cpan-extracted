# H1: mdee Test Document

This is a test file for checking **bold text**, __also bold__, _italic text_, *also italic*, and `inline code` styles.

## H2: Pipeline Architecture

The `mdee` command constructs a **pipeline** of commands.

### H3: Processing Stages

Each stage can be enabled using `--fold`, `--table`, and `--nup` options.

#### H4: Syntax Highlighting

Uses `greple` with `-G` and `--ci=G` options.

##### H5: Color Specifications

Colors like `L00DE/${base}` use **Term::ANSIColor::Concise** format.

## H2: Code Block Examples

Here is a code block:

```bash
greple -G --ci=G --all --need=0 \
    --cm 'L00DE/${base}' -E '^#\h+.*' \
    file.md
```

Another example:

```perl
my $color = '#CCCDFF';
print "Base color: $color\n";
```

Tilde fence example:

~~~python
def hello():
    print("Hello, world!")
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

## H2: Table Example

|Name|Description|Status|
|-|-|-|
|greple|Pattern matching tool|active|
|ansifold|ANSI-aware text folding|active|
|ansicolumn|Column formatting with ANSI support|active|

## H2: List Example

- First item with `inline code`
- Second item with **bold text** and _italic_
- Third item with a longer description that might wrap to multiple lines when displayed in a narrow terminal window

## H2: Definition List Example

greple
: Pattern matching and highlighting tool with extensive regex support for syntax highlighting

ansifold
: ANSI-aware text folding utility that wraps long lines while preserving escape sequences and maintaining proper indentation

Term with blank line

: Definition after a blank line with `inline code` and **bold text** that might wrap to multiple lines

<!-- This is an HTML comment that should be dimmed -->

### H3: Nested Content

Some text with `multiple` inline `code` segments, **bold** words, and _italic_ text.

#### H4: More Details

Final section with `code` and **emphasis**.

##### H5: Deep Nesting

The deepest level with `L00DE/${base}` color specification.
