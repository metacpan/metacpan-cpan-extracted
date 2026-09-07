# Config::Access::Driver

De-/Serialising INI files into ready-to-use object structures

---

## Overview

`Config::Access::Driver` reads, manipulates, and writes INI configuration
files as ready-to-use objects. Instead of navigating raw hashes-of-hashes or
defining custom configuration classes, you get objects with convenient access
methods from the moment the file is parsed — **read → inspect → modify →
write** with zero preparation.

It combines the **convenient file access** of
[`File::Access::Driver`](https://metacpan.org/pod/File::Access::Driver)
with the **convenient object access** of [`Object::Meta`](https://metacpan.org/pod/Object::Meta),
adding an INI parser and ready-made section structures on top.

## Motivation

This library was conceived as result of the experience using `Config::IniHash`
extensively and the clumsy code it produces.\
So, it aims to make the work **de-/serialising INI files** **easier** and more **streamlined**.\
Especially data manipulation is simplified with the use of the convenient
`Object::Meta` library.\
But also file manipulation becomes more easier thanks to the use of the
convenient `File::Access::Driver` library.

## Key Features

- **Ready-to-use objects, no preparation** — Parsing yields
  `Config::Section` objects with a full method API (`get`, `set`, `add`,
  `hasKey`, `getName`, …). No classes to define, no structure mapping,
  no long setup.
- **Convenient key access with defaults** — `get('KEY', $default)`
  returns the value or falls back to your default in a single call.
  Combined with `hasKey('KEY')`, incomplete configurations can be
  detected and handled cleanly instead of tripping over `undef`.
- **Indexed section lookup** — Sections are indexed by name on the
  [`Object::Meta`](https://metacpan.org/pod/Object::Meta) backend, so
  `$seclist->getConfigSectionbyName($name)` is direct — no scanning,
  no hash-chaining, no string building of section keys.
- **Full round trip** — `Config::Section::Parser` implements both
  directions (`fillListFromArray` / `buildStringFromList`). Read, modify,
  and write back in three method calls.
- **Duplicate section headers are merged** — a repeated `[section]`
  header merges into the existing section instead of silently
  overwriting data.
- **Mixed section content** — Sections support classic `key = value`
  options *and* bare value lines collected as simple lists, so
  list-style configurations are handled natively.
- **No top-level section required** — Options before the first section
  header are captured into an auto-created section instead of being
  dropped or treated as errors.
- **Built-in error reporting** — The file driver tracks its own state;
  check `getErrorCode` after operations instead of stitching together
  `defined`/`-e`/`exists` guards.
- **Lightweight, pure Perl** — no XS, no native compilation; runs on
  Perl ≥ 5.010 with a minimal dependency footprint.
- **Clean separation of concerns** — File I/O lives in the reusable
  parent class [`File::Access::Driver`](https://metacpan.org/pod/File::Access::Driver);
  the config logic stays independent of how files are physically read
  and written.

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

**Requires:** _Perl_ ≥ `5.010`.

## Usage

```perl
use Config::Access::Driver;

my $config_file = Config::Access::Driver::->new(
    ( 'filedirectory' => $config_directory, 'filename' => $config_file_name ) );

my $config = $config_file->readList();

#Free the System Resources
$config_file->freeResources();

if ( $config_file->getErrorCode() == 0 ) {
    my $server_section = $config->getConfigSectionbyName($server_prefix);

    if ( defined $server_section ) {

        #------------------------
        #Server Backup Configuration

        #Value with fallback default in one call
        $backup_directory = $server_section->get( 'BACKUPDIR', $backup_directory );

        #Existence check without hash plumbing
        if ( $server_section->hasKey('SAVEDAYS') ) {
            $save_days = $server_section->get('SAVEDAYS');
        }
        else    #The Server Configuration is not complete
        {
            $error_message .=
              "Server '$server_prefix': Server is not completely configured.\n"
              . "Assuming SAVEDAYS = '$save_days'\n";
        }
    }
}
```

For a quick one-shot read without managing the driver instance:

```perl
my $config = Config::Access::Driver::readConfigSectionList('/path/to/config.ini');

#Fast indexed lookup by section name
my $db_config = $config->getConfigSectionbyName('database');
```

### Comparison with Config::IniHash

The same task — read a backup configuration, validate required keys — written with `Config::IniHash`:
```perl
$config = ReadINI $config_file_path;

if ( defined $config ) {
    if ( defined $config->{$server_prefix} ) {

        if ( defined $config->{$server_prefix}->{'BACKUPDIR'} ) {
            $backup_directory = $config->{$server_prefix}->{'BACKUPDIR'};
        }

        if ( defined $config->{$server_prefix}->{'MAILTO'} ) {
            $smailto = $config->{$server_prefix}->{'MAILTO'};
        }
        else    #The Server Configuration is not complete
        {
            $error_message .=
              "Server '$server_prefix': Server is not completely configured.\n";
        }
    }
}
```

Every access **repeats the full hash-of-hashes path** — `$config->{$server_prefix}->{'KEY'}` —
wrapped in exists guards.
Reconstructing numerically keyed options into an array gets worse:
```perl
if ( exists $config->{ $server_prefix . $backup_plan_section } ) {
    foreach ( keys %{ $config->{ $server_prefix . $backup_plan_section } } ) {
        $#backup_plan = $_ if ( $_ + 1 > @backup_plan );
        $backup_plan[$_] = $config->{ $server_prefix . $backup_plan_section }->{$_};
    }
}
```

With `Config::Access::Driver`, the same intent becomes named, typed method calls:
```perl
$backup_directory = $server_section->get( 'BACKUPDIR', $backup_directory );

if ( $server_section->hasKey('MAILTO') ) { ... }
```

The difference compounds in real applications: every hash-path access in the `Config::IniHash` version
is a potential `undef` dereference and must be guarded individually, while the object API concentrates
those checks into **get defaults**, `hasKey()`, and the **driver's Error Code**.

## Where the trade-off lies

Other INI readers are typically faster on raw parsing, and hash-of-hashes returns plain data with no dependencies.
But their speed is paid for in application code: hash chains to repeat, existence checks to hand-roll,
and no object behaviour whatsoever. `Config::Access::Driver` is optimised for **developer productivity**
and safe access patterns rather than absolute parse speed — lookups are still served through a name index
rather than linear scans, and parsing itself is a single pass over the file lines.

## Architecture
```perl
Config::Access::Driver           – File bound De-/Serialisation Driver
 └─ parent: File::Access::Driver – Reusable File Access Layer (I/O)
Config::Section::Parser          – parseLines ↔ buildString (De-/Serializer)
Config::Section::List            – Ordered, indexed list of Sections
Config::Section                  – Single INI section (options + value lists)
Object::Meta / Object::Meta::List – Lightweight meta-object indexing layer
```

Each layer is proven, published software in its own right — `File::Access::Driver` handles
any file I/O task and `Object::Meta` provides indexed collections for arbitrary objects —
with the `Config::*` layers adding only the INI-specific logic on top.

## Dependencies

Runtime dependencies are intentionally minimal:
| Module |  Purpose |
| :-- | :-- |
| File::Access::Driver |  Convenient file reading and writing |
| Object::Meta |  Indexed object collections |

Plus `Data::Dump` for **development/debugging**. No XS, no native compilation.

## Author

Bodo (Hugo) Barwich

## License

Distributed under the Artistic License / the same terms as _Perl_ itself. See `LICENSE` for details.