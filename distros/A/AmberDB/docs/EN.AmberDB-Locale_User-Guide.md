[Home](index.html) &nbsp;•&nbsp; [About](EN.About_AmberDB.html) &nbsp;•&nbsp; [Quick Start](index.html#quick-start) &nbsp;•&nbsp; [Tutorial](EN.AmberDB_User-Guide.html) &nbsp;•&nbsp; [Benchmark](EN.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](EN.AmberDB-Locale_User-Guide.html) &nbsp;•&nbsp; [SQL Guide](EN.AmberDB-vs-SQL_User-Guide.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [Türkçe](TR.AmberDB-Locale_Kullanim_Rehberi.html)

---

# AmberDB::Locale - Comprehensive Guide

## 1. Overview

`AmberDB::Locale` is a **locale-aware text processing engine** designed for multilingual applications. Written in Perl, it provides the following core capabilities:

| Capability | Description |
|---|---|
| Case conversion | Locale-aware `uc`, `lc`, `ucfirst` |
| Sorting | Unicode Collation Algorithm (UCA) based |
| ASCII transliteration | Convert accented characters to plain ASCII (slugs, IDs) |
| Number → Text | Written-out numbers for invoices/documents |
| Date/time formatting | Locale-specific date formats |
| Number/currency formatting | Grouping separators, decimal separators, symbol placement |
| HTML entity decoding | Named + numeric entity decode |
| Plural rules | CLDR-based plural form selection |
| UTF-8 safe substring | Character-based slicing (not byte-based) |

**Architectural principle:** Engine logic lives in `AmberDB::Locale.pm`, while language data resides in `AmberDB::Locale::Lang::*` packages as **pure data**. Engine and data are completely separated.

---

## 2. Architecture

```
AmberDB::Locale                 ← Main engine (all logic here)
├── AmberDB::Locale::Lang::gb   ← Global Base data (default/fallback)
├── AmberDB::Locale::Lang::en   ← English data
├── AmberDB::Locale::Lang::tr   ← Turkish data
├── AmberDB::Locale::Lang::de   ← German data
├── AmberDB::Locale::Lang::fr   ← French data
├── AmberDB::Locale::Lang::es   ← Spanish data
├── AmberDB::Locale::Lang::ru   ← Russian data
├── AmberDB::Locale::Lang::az   ← Azerbaijani data
├── AmberDB::Locale::Lang::ar   ← Arabic data
├── AmberDB::Locale::Lang::ja   ← Japanese data
└── AmberDB::Locale::Currency   ← ISO 4217 universal currency data
```

Each `Lang::*` module contains only a single subroutine called `data()` and returns a hash-ref. **No logic is included.**

---

## 3. Object Construction (Constructor)

```perl
use AmberDB::Locale;

# 1) Named-param API (recommended)
my $lang = AmberDB::Locale->new(language => "tr");

# 2) Hashref API
my $lang = AmberDB::Locale->new({ language => "de" });

# 3) Positional string API
my $lang = AmberDB::Locale->new("fr");

# 4) No args → defaults to "gb" (Global Base)
my $lang = AmberDB::Locale->new();
```

### Internal behaviors

- **Caching:** A second `new()` call for the same language returns the existing instance (singleton-like).
- **Alias support:** Labels like `"global"`, `"gl"`, `"turkish"`, `"tr_tr"`, `"tr-tr"` are automatically mapped to canonical codes.
- **Fallback:** If an unknown language is requested, a `cluck` warning is emitted and it falls back to `gb`.
- **Collator:** Attempts to load `Unicode::Collate::Locale`; if it fails, falls back to base `Unicode::Collate`, and if that's also unavailable, uses a custom `sort_map` Schwartzian transform.

### AmberDB integration

```perl
# Language is automatically pulled from cfg
my $db = AmberDB->new(cfg => { language => "tr" });
$db->uc("ığdır");   # works via inheritance: IĞDIR
```

---

## 4. Language Data Structure (`data()` Hash-Ref)

Complete schema of the structure returned by each language module:

```perl
{
    uc_map          => { },   # Character mapping applied before uc()
    lc_map          => { },   # Character mapping applied before lc()
    sort_map        => { },   # Custom sort weights (if no collator)
    alphabet_chars  => "...",  # Safe character class for normalize()
    accent_map      => { },   # normalize() accent → local equivalent
    ascii_map       => { },   # to_ascii() pre-mapping before NFD
    numbers         => { },   # num2text number words
    html_entities   => { },   # Locale-specific extra HTML entities
    months          => [ ],   # 12-element month names
    days            => [ ],   # 7-element day names (Sunday → Saturday)
    number_format   => { },   # Decimal/grouping separator settings
    default_currency    => "",
    currency_position   => "prefix|suffix",
    currency_space      => 0|1,
    date_format     => { },   # short, medium, long, full, time, datetime
    plural_rule     => "...", # CLDR plural rule expression
}
```

---

## 5. Public API - Method Reference

### 5.1 Case Conversions

#### `uc($string)` - Convert to uppercase

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->uc("ığdır");       # "IĞDIR"
$tr->uc("istanbul");    # "İSTANBUL"  (i → İ, Turkish rule)

my $de = AmberDB::Locale->new(language => "de");
$de->uc("straße");      # "STRASSE"   (ß → SS)
```

> **Turkish detail:** The mapping `'i' => "\x{130}"` inside `uc_map` is applied **before** Perl's `CORE::uc()` call. This ensures the `i → İ` conversion is done correctly.

#### `lc($string)` - Convert to lowercase

```perl
$tr->lc("İSTANBUL");    # "istanbul"  (İ → i, I → ı)
$tr->lc("IĞDIR");       # "ığdır"
```

> Inside `lc_map`, the mappings `'I' => "\x{131}"` and `"\x{130}" => 'i'` are applied before `CORE::lc()`.

#### `ucfirst($string)` - Capitalize word beginnings

```perl
$tr->ucfirst("istanbul büyükşehir belediyesi");
# "İstanbul Büyükşehir Belediyesi"
```

First the entire string is lowercased via `lc()`, then the first character after spaces, periods, exclamation marks, colons, quotes, `/`, `(`, `)` is uppercased.

#### `fold($string)` - Normalization for search

```perl
my $key = $tr->fold("İSTANBUL");   # "istanbul" (NFKC + lc)
```

Applies Unicode NFKC decomposition + locale `lc()`. Designed for search indexing and matching.

#### `ieq($str1, $str2)` - Case-insensitive comparison

```perl
$tr->ieq("İstanbul", "istanbul");  # 1 (true)
$tr->ieq("Ankara", "ankara");      # 1 (true)
$tr->ieq("Ankara", "İzmir");       # 0 (false)
```

If a `Unicode::Collate::Locale` collator is available, it uses that for comparison; otherwise it compares `fold()` results with `eq`.

---

### 5.2 Sorting

#### `sort(\@list [, $field])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");

# Simple array sorting
my @sorted = $tr->sort(["İzmir", "Ankara", "Van", "Şanlıurfa", "Bursa", "Çanakkale"]);
# => ("Ankara", "Bursa", "Çanakkale", "İzmir", "Şanlıurfa", "Van")

# Array of hashrefs - sort by field name
my @sorted = $tr->sort(\@products, "name");

# Array of arrayrefs - sort by index number
my @sorted = $tr->sort(\@rows, 2);
```

**Sorting strategy (priority order):**
1. `Unicode::Collate::Locale` (locale-specific UCA table)
2. `Unicode::Collate` (base UCA)
3. Custom `sort_map` Schwartzian transform (last resort)

---

### 5.3 Text Normalization

#### `normalize($string)` - Clean up

```perl
my $clean = $tr->normalize('<p>Kâr &amp; zarar &ccedil;izelgesi</p>');
# "Kar zarar cizelgesi"
```

Processing order:
1. HTML entity decoding (`decode_entities`)
2. HTML tag removal (`<...>` → space)
3. Clean remaining entities
4. Apply `accent_map` (e.g., `â → a`, `ô → ö`)
5. Remove characters outside the safe character class
6. Collapse multiple whitespace to single space, trim edges

#### `to_ascii($string [, $nonspace])` - ASCII transliteration

```perl
$tr->to_ascii("çarşı");           # "carsi"
$tr->to_ascii("İstanbul", 1);     # "istanbul"  (slug mode)
$tr->to_ascii("Große Straße");    # "Grosse Strasse" (de locale)

my $de = AmberDB::Locale->new(language => "de");
$de->to_ascii("Müller");          # "Mueller"  (DIN 5007-2: ü → ue)
```

Processing order:
1. Optional `lc()` (if `$nonspace` is provided)
2. `normalize()`
3. Apply `ascii_map` (characters NFD can't decompose: `ı → i`, `ß → ss`, `ä → ae`, etc.)
4. NFD decomposition + strip `\p{M}` (combining marks)
5. Clean anything outside `[a-z0-9,.\-_ ]`
6. In `$nonspace` mode: spaces → `_`, clean underscore repetition

---

### 5.4 Number → Text Conversion

#### `num2text($number [, %options])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->num2text(0);           # "Sıfır"
$tr->num2text(1);           # "Bir TL"
$tr->num2text(1000);        # "Bin TL"          (NOT "Bir Bin")
$tr->num2text(100);         # "Yüz TL"          (NOT "Bir Yüz")
$tr->num2text(1234.56);     # "Bin İki Yüz Otuz Dört TL Elli Altı KR"
$tr->num2text(-42);         # "Eksi Kırk İki TL"

# With custom currency
$tr->num2text(99.99, currency => { main => "EUR", sub => "cent" });

# With completely custom number data
$tr->num2text(5, numbers => { zero => "Yok", ones => [...], ... });
```

**Supported options:**

| Option | Description |
|---|---|
| `currency => { main => "...", sub => "..." }` | Main/sub currency names |
| `numbers => \%hash` | Full or partial number word data override |

**Locale-specific rules:**

| Rule | Description | Example (tr) |
|---|---|---|
| `hundred_one_prefix` | "One" prefix for 100 | `0` → "Yüz" |
| `thousand_one_prefix` | "One" prefix for 1000 | `0` → "Bin" |
| `decimal_sep` | Decimal separator | `','` → "1.234,56" format |

> Eastern Arabic digits (`٠١٢٣٤٥٦٧٨٩`) and Persian digits (`۰۱۲۳۴۵۶۷۸۹`) are automatically converted to Western digits.

---

### 5.5 Text Cleaning and Safe Characters

#### `safe_chars($string)`

```perl
$lang->safe_chars("hello world! @#$ 123");
# "hello world 123"
```

Strips all foreign or special characters not matching the language's `alphabet_chars` definition.

---

### 5.6 Full-Text Search and Phonetic Word Normalization

Core morphological and phonetic analysis methods powering `AmberDB` full-text search engine:

#### `normalize_word($word [, $mode_write])`

Normalizes a word phonetically and morphologically for search indexing and query matching:

```perl
my $tr = AmberDB::Locale->new(language => "tr");

# 1. Query mode (default, mode_write = 0): Strips suffixes / clitics
$tr->normalize_word("Türkiye'nin"); # "turkiye" (apostrophe suffix 'nin' stripped as stop-word)
$tr->normalize_word("Türkiye'de");  # "turkiye"

# 2. Write mode (mode_write = 1): Generates both root and joined compound for indexing
$tr->normalize_word("Türkiye'de", 1); # "turkiye turkiyede"

# 3. Circumflex / accent normalization
$tr->normalize_word("kârın");       # "karin"
$tr->normalize_word("ÂLÎM");        # "alim"

# 4. Word-final consonant devoicing / phonetic assimilation
$tr->normalize_word("tevhid");      # "tevhit"  (d$ => t)
$tr->normalize_word("gazab");       # "gazap"   (b$ => p)
$tr->normalize_word("mehmed");      # "mehmet"  (d$ => t)
```

#### `search_pattern($query)`

Converts a search query string into a locale-aware regex pattern matching regional character variants:

```perl
my $pattern = $tr->search_pattern("Türkiye");
# Produces regex token pattern matching Turkish and ASCII variants (e.g. "t[uü]rk[iıİI]y[eE]")
```

#### `search_regex($string, $pattern)`

Performs a case-insensitive, locale-aware regex match of `$pattern` inside target `$string`. Returns `1` on match, `0` otherwise:

```perl
my $found = $tr->search_regex("İstanbul Boğazı", "istanbul"); # 1
my $match = $tr->search_regex("İzmir Kordon", $pattern);       # 1
```

---

### 5.7 HTML Entity Decoding

#### `decode_entities($string)`

```perl
$lang->decode_entities("&amp; &lt; &gt; &#x20AC; &#8364; &ccedil;");
# "& < > € € ç"
```

Three stages:
1. **Hex numeric:** `&#x20AC;` → `€`
2. **Decimal numeric:** `&#8364;` → `€`
3. **Named entities:** Universal set (`&amp;`, `&lt;`, `&nbsp;`, `&euro;`, etc.) + locale-specific extras (`&ccedil;`, `&scaron;`, `&gbreve;`, etc.)

---

### 5.8 UTF-8 Safe Substring

#### `substring($string, [$offset], $length)`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->substring("Çanakkale", 0, 4);     # "Çana"  (4 characters, not 4 bytes!)
$tr->substring("İstanbul", 2, 3);      # "tan"

# Also safe with raw UTF-8 byte strings:
my $raw = encode('UTF-8', "Şanlıurfa");
$tr->substring($raw, 0, 5);            # "Şanlı" (correctly re-encoded)
```

> Checks whether the string is decoded using `Encode::is_utf8()`. If it's raw bytes, the `decode → substr → encode` chain is applied; this prevents multibyte characters from being cut in half.

---

### 5.9 Date/Time Operations

#### `format_date($time [, $pattern_or_style])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
my $epoch = time();   # e.g.: 2026-08-09

$tr->format_date($epoch);                    # "09.08.2026"
$tr->format_date($epoch, 'medium');          # "9 Ağu 2026"
$tr->format_date($epoch, 'long');            # "9 Ağustos 2026"
$tr->format_date($epoch, 'full');            # "Pazar, 9 Ağustos 2026"
$tr->format_date($epoch, 'time');            # "14:30"
$tr->format_date($epoch, 'datetime');        # "09.08.2026 14:30"

# Custom pattern
$tr->format_date($epoch, 'YYYY-MM-DD');     # "2026-08-09"
$tr->format_date($epoch, 'DD/MM/YYYY');     # "09/08/2026"

# Also accepts date strings
$tr->format_date("2026-08-09", 'full');     # "Pazar, 9 Ağustos 2026"
```

**Supported tokens:**

| Token | Meaning | Example |
|---|---|---|
| `YYYY` / `YY` | 4/2-digit year | 2026 / 26 |
| `MMMM` / `MMM` / `MM` / `M` | Month name / short / 2-digit / single | Ağustos / Ağu / 08 / 8 |
| `DD` / `D` | Day (2-digit / single) | 09 / 9 |
| `dddd` / `ddd` | Day name / short | Pazar / Paz |
| `HH` / `H` | Hour | 14 / 14 |
| `mm` / `m` | Minute | 05 / 5 |
| `ss` / `s` | Second | 09 / 9 |

**Accepted input formats:**
- Unix timestamp: `1786345200`
- Date string: `2026-08-09`, `2026/08/09`, `2026.08.09`
- Date + time: `2026-08-09 14:30:00`, `2026-08-09T14:30`

#### `parse_date($string [, %opts])`

```perl
my $epoch = $tr->parse_date("09.08.2026");            # Unix timestamp
my $h     = $tr->parse_date("09.08.2026", hash => 1);
# { year => 2026, month => 8, day => 9, hour => 0, minute => 0, second => 0 }
```

> The short date format automatically detects whether it's `DD.MM.YYYY` or `MM/DD/YYYY` based on the locale's `date_format.short` value.

---

### 5.10 Number and Currency Formatting

#### `format_number($num [, %opts])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->format_number(1234567.89);              # "1.234.567,89"
$tr->format_number(1234567.89, decimals => 0); # "1.234.568"
$tr->format_number(1234567.89, decimals => 3); # "1.234.567,890"

my $en = AmberDB::Locale->new(language => "en");
$en->format_number(1234567.89);              # "1,234,567.89"

my $fr = AmberDB::Locale->new(language => "fr");
$fr->format_number(1234567.89);              # "1 234 567,89"
```

| Locale | Decimal | Grouping | Example |
|---|---|---|---|
| `tr` | `,` | `.` | 1.234.567,89 |
| `en` | `.` | `,` | 1,234,567.89 |
| `de` | `,` | `.` | 1.234.567,89 |
| `fr` | `,` | *(space)* | 1 234 567,89 |
| `ru` | `,` | *(space)* | 1 234 567,89 |
| `ar` | `٫` | `٬` | ١٬٢٣٤٬٥٦٧٫٨٩ |

#### `format_currency($amount [, $code | %opts])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->format_currency(1234.50);                    # "₺1.234,50"
$tr->format_currency(1234.50, 'EUR');             # "1.234,50 €"  (suffix + space)
$tr->format_currency(1234.50, currency => 'USD'); # "$1.234,50"

my $de = AmberDB::Locale->new(language => "de");
$de->format_currency(1234.50, 'EUR');             # "1.234,50 €"
```

**Resolution priority:**
`%opts override` → `locale currencies` → `AmberDB::Locale::Currency` universal data → default values

---

### 5.11 Plural Rules (Pluralization)

#### `plural($count, \%forms)`

```perl
my $en = AmberDB::Locale->new(language => "en");
$en->plural(1, { one => "{count} item",  other => "{count} items" });
# "1 item"
$en->plural(5, { one => "{count} item",  other => "{count} items" });
# "5 items"

my $tr = AmberDB::Locale->new(language => "tr");
$tr->plural(1, { one => "{count} ürün", other => "{count} ürün" });
# "1 ürün"
$tr->plural(5, { one => "{count} ürün", other => "{count} ürün" });
# "5 ürün"

# Russian - 4 different forms
my $ru = AmberDB::Locale->new(language => "ru");
$ru->plural(1,  { one => "{count} яблоко", few => "{count} яблока",
                  many => "{count} яблок",  other => "{count} яблока" });
# "1 яблоко"
$ru->plural(3,  { ... });   # "3 яблока"   (few)
$ru->plural(5,  { ... });   # "5 яблок"    (many)
$ru->plural(11, { ... });   # "11 яблок"   (many)
```

**CLDR rule string format:**

```
one{n==1}other
zero{n==0}one{n==1}two{n==2}few{n%100>=3&&n%100<=10}many{n%100>=11&&n%100<=99}other
one{n%10==1&&n%100!=11}few{n%10>=2&&n%10<=4&&(n%100<10||n%100>=20)}many{...}other
```

> `{count}` or `{n}` placeholders are replaced with locale-appropriately formatted numbers (via `format_number` with `decimals => 0`).

---

### 5.12 Other Accessors

```perl
$lang->language();   # "tr" - active language tag
$lang->months();     # ["Ocak", "Şubat", ..., "Aralık"]
$lang->days();       # ["Pazar", "Pazartesi", ..., "Cumartesi"]
```

#### `first_char($string)` - Alphabetical index character

```perl
$tr->first_char("  çarşı  ");    # "Ç"
$tr->first_char("123abc");       # "0-9"
$tr->first_char("İzmir");        # "İ"
```

---

## 6. `AmberDB::Locale::Currency` - Universal Currency Data

**12 currencies** are defined in the ISO 4217 standard:

| Code | Name | Symbol | Decimals |
|---|---|---|---|
| TRY | Türk Lirası | ₺ | 2 |
| USD | ABD Doları | $ | 2 |
| EUR | Euro | € | 2 |
| GBP | İngiliz Sterlini | £ | 2 |
| RUB | Rus Rublesi | ₽ | 2 |
| AZN | Manat | ₼ | 2 |
| SAR | Suudi Riyali | ر.س | 2 |
| JPY | Japon Yeni | ¥ | **0** |
| CHF | İsviçre Frangı | CHF | 2 |
| CAD | Kanada Doları | CA$ | 2 |
| AUD | Avustralya Doları | A$ | 2 |
| CNY | Çin Yuanı | ¥ | 2 |

```perl
AmberDB::Locale::Currency->by_code('TRY');   # { num=>'949', name=>'Türk Lirası', symbol=>'₺', digits=>2 }
AmberDB::Locale::Currency->symbol('EUR');    # "€"
AmberDB::Locale::Currency->name('USD');      # "ABD Doları"
AmberDB::Locale::Currency->all();            # [ ['TRY','Türk Lirası'], ['USD','ABD Doları'], ... ]
AmberDB::Locale::Currency->active_codes();   # qw(TRY USD EUR GBP RUB AZN SAR JPY CHF CAD AUD CNY)
```

---

## 7. Language Data Module Writing Guide

To add a new language, create an `Amber/Locale/Lang/<code>.pm` file:

```perl
package AmberDB::Locale::Lang::it;   # Italian example
use strict;
use warnings;

our $VERSION = '1.0';

sub data {
    return {
        uc_map         => {},
        lc_map         => {},
        sort_map       => {},
        alphabet_chars => "\x{E0}\x{E8}\x{E9}\x{EC}\x{F2}\x{F9}",  # à è é ì ò ù
        accent_map     => {},
        ascii_map      => {},    # NFD handles all accents

        numbers => {
            zero     => 'Zero',
            ones     => [qw(Uno Due Tre Quattro Cinque Sei Sette Otto Nove)],
            tens     => [qw(Dieci Venti Trenta Quaranta Cinquanta Sessanta Settanta Ottanta Novanta)],
            hundred  => 'Cento',
            thousand => 'Mille',
            million  => 'Milione',
            billion  => 'Miliardo',
            currency => { main => 'EUR', sub => 'centesimo' },
            decimal_sep => ',',
            hundred_one_prefix  => 0,
            thousand_one_prefix => 0,
        },

        html_entities => {},

        months => [qw(Gennaio Febbraio Marzo Aprile Maggio Giugno
                      Luglio Agosto Settembre Ottobre Novembre Dicembre)],
        days   => [qw(Domenica Lunedì Martedì Mercoledì Giovedì Venerdì Sabato)],

        number_format => {
            decimal_sep => ',',
            group_sep   => '.',
            group_size  => 3,
        },
        default_currency  => 'EUR',
        currency_position => 'suffix',
        currency_space    => 1,
        date_format => {
            short    => 'DD/MM/YYYY',
            medium   => 'D MMM YYYY',
            long     => 'D MMMM YYYY',
            full     => 'dddd D MMMM YYYY',
            time     => 'HH:mm',
            datetime => 'DD/MM/YYYY HH:mm',
        },
        plural_rule => 'one{n==1}other',
    };
}

1;
```

> The file name is automatically `require`d by `_load_locale()` in `AmberDB::Locale`. No additional registration is needed.

---

## 8. Performance Notes

| Topic | Detail |
|---|---|
| **Instance cache** | Only **1 instance** is created per language; subsequent `new()` calls return from cache |
| **Regex pre-compile** | All patterns (`_uc_re`, `_lc_re`, `_sort_re`, `_accent_re`, `_ascii_re`, `_safe_re`) are compiled at construction time; not recompiled on each method call |
| **Sort key length** | `uc_map`/`lc_map` keys are sorted by **length descending** → multi-character mappings match first |
| **Unicode::Collate** | May be slow on first load (table reading), but subsequent calls are fast |

---

## 9. Common Mistakes and Solutions

| Problem | Cause | Solution |
|---|---|---|
| `i` → `I` instead of `İ` | Using `en` locale | Provide `language => "tr"` |
| `to_ascii` output has `a` instead of `ae` | In `en` locale, NFD does `ä → a` | Use `de` locale (DIN 5007-2: `ä → ae`) |
| Number text returns empty | Input contains only separators/punctuation | Check for valid digit input |
| Eastern Arabic digits not converted | `normalize_num` not called explicitly | `num2text`/`format_number` does it automatically; no manual call needed |
| Unknown language error | Lang module file doesn't exist | Create `Amber/Locale/Lang/<code>.pm` or accept `en` fallback |

---

## 10. Quick Reference Card

```perl
my $L = AmberDB::Locale->new(language => "tr");

# Text transformations
$L->uc("ığdır")                    # IĞDIR
$L->lc("İSTANBUL")                 # istanbul
$L->ucfirst("merhaba dünya")       # Merhaba Dünya
$L->fold("İSTANBUL")               # istanbul
$L->ieq("İstanbul", "istanbul")    # 1
$L->normalize("<b>Kâr</b> &amp;")  # Kar &
$L->to_ascii("çarşı")              # carsi
$L->to_ascii("çarşı", 1)           # carsi (slug)
$L->first_char("çarşı")            # Ç
$L->substring("Şanlıurfa", 0, 5)   # Şanlı

# Sorting
$L->sort(["İzmir","Ankara","Van"]) # Ankara, İzmir, Van

# Numbers
$L->num2text(1234.56)              # Bin İki Yüz Otuz Dört TL Elli Altı KR
$L->format_number(1234567.89)      # 1.234.567,89
$L->format_currency(99.9, 'TRY')   # ₺99,90

# Date
$L->format_date(time, 'full')      # Pazar, 9 Ağustos 2026
$L->parse_date("09.08.2026")       # epoch

# Plural
$L->plural(1, {one=>"{count} adet", other=>"{count} adet"})  # 1 adet

# Accessors
$L->language()                     # tr
$L->months()                       # [Ocak, Şubat, ...]
$L->days()                         # [Pazar, Pazartesi, ...]
```
