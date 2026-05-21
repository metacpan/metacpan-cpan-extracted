# App::PerlGlue

**Glue messy text into useful shapes.**

PerlGlue is a command-line tool for connecting real-world text formats:
logs, CSV/TSV, JSON Lines, and plain text.

It is designed for the moment when simple one-liners stop being simple.

---

## Philosophy

> sed when it’s simple.  
> awk when it’s tabular.  
> perlglue when it gets messy.

PerlGlue is **not** a replacement for `sed` or `awk`.

Instead, it fills the gap when:

- your one-liner becomes unreadable
- your data stops being clean text
- you need to move between formats (CSV ⇄ JSON ⇄ logs)
- you start wishing you could just write Perl

---

## Why PerlGlue?

### 1. Real regex power

Perl’s regex engine handles complex patterns cleanly:

```bash
perlglue replace 's/(?<=user=)\w+/REDACTED/g' app.log
````

---

### 2. Correct CSV/TSV handling

Unlike `awk -F,`, PerlGlue handles quoted fields properly:

```csv
name,email,note
Alice,a@example.com,"hello, world"
```

```bash
perlglue pick users.csv --csv name,email
```

---

### 3. Native Perl expressions

Write filters in Perl, not another DSL:

```bash
perlglue where access.log '$_ =~ /ERROR/ && $_ =~ /timeout/'
perlglue jsonl logs.jsonl '$_->{status} >= 500'
```

---

### 4. Works across formats

Glue different data formats together:

```bash
perlglue csv users.csv --to jsonl \
  | perlglue jsonl --where '$_->{age} >= 30' \
  | perlglue template '{{name}} <{{email}}>'
```

---

### 5. One tool instead of many

Instead of combining:

* sed
* awk
* jq
* custom scripts

Use a single, consistent interface.

---

## Relationship to JQ::Lite

PerlGlue is not a jq clone.

* **JQ::Lite** → querying JSON
* **PerlGlue** → preparing, transforming, and connecting data

Use JQ::Lite when working with clean JSON:

```bash
jq-lite '.users[] | select(.age > 30)' users.json
```

Use PerlGlue when your data is messy or not JSON yet:

```bash
perlglue from-csv users.csv --to jsonl \
  | jq-lite '.[] | select(.age > 30)'
```

---

## When to use what

| Tool     | Use case                       |
| -------- | ------------------------------ |
| sed      | simple text substitution       |
| awk      | simple column/field processing |
| jq-lite  | structured JSON queries        |
| perlglue | messy, mixed, real-world data  |

---

## Examples

```bash
# filter logs
perlglue lines access.log --where '$_ =~ /ERROR/'

# pick fields from CSV
perlglue pick users.csv --csv name,email

# convert CSV → JSONL
perlglue convert users.csv --to jsonl

# template output
perlglue template users.csv 'Hello, {{name}}'

# safe rename
perlglue rename 's/\s+/_/g' *.txt
```

---

## Status

Early-stage. Expect rapid changes.

---

## License

Artistic License 2.0
