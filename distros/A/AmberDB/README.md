# AmberDB

[![CPAN version](https://badge.fury.io/pl/AmberDB.svg)](https://metacpan.org/pod/AmberDB)
[![Perl Version](https://img.shields.io/badge/perl-5.16%2B-blue.svg)](https://www.perl.org)
[![License](https://img.shields.io/badge/license-Artistic_2.0-brightgreen.svg)](LICENSE)
[![CI](https://github.com/marufcetin/amberdb/actions/workflows/ci.yml/badge.svg)](https://github.com/marufcetin/amberdb/actions)
[![Documentation](https://img.shields.io/badge/docs-GitHub_Pages-blue.svg)](https://marufcetin.github.io/amberdb/)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey.svg)](https://github.com/marufcetin/amberdb)

**AmberDB** is a high-performance, schema-driven NoSQL database engine for Perl, featuring ACID transactions and precomputed inverted indexing on top of Berkeley DB (`DB_File`). It delivers zero-overhead schema management, extensible JSON-like block records without relational SQL JOIN bottlenecks, 8-byte packed binary indexing, intelligent locale-aware full-text search, Strict 2-Phase Locking (Strict 2PL), a 2-Pillar continuous disaster recovery and `.amberdb` native archiving architecture, and high-throughput batch operations.

---

## Key Features

- **Ultra High-Performance**: Leverages Berkeley DB (`DB_File`) hash storage with $O(1)$ binary slicing and configurable in-memory buffers.
- **JOIN-Free JSON-like Extensible Block Records**: Eliminates complex relational SQL `JOIN` overhead by storing hierarchical, extensible block records. Newly added blocks and attributes are automatically indexed on the fly for low-latency multi-dimensional querying.
- **Schema-Driven Dynamic Runtime Manipulation**: Table-specific schemas govern field validations, encodings, and index mappings. Schemas and values are fully mutable and can be modified dynamically at runtime without requiring table recreation or migrations.
- **8-Byte Packed Binary Indexing**: Primary and secondary indexes use unified 8-byte packed binary buffers (`Q>*`), enabling $O(1)$ substring slicing, sub-millisecond pagination, and memory-efficient `keys_only` scalar pipelines (with `use_simple => 1` mode for arbitrary string keys).
- **Intelligent & Locale-Aware Accent Search**: Advanced full-text search engine (`.src`) equipped with regional language and accent intelligence, phonetic devoicing (`b/d/g -> p/t/k`), circumflex/accent unfolding (`â/î/û -> a/i/u`), apostrophe suffix stop-words, and prefix wildcard matching.
- **Columnar Facet Indexing (`.fac`)**: High-performance multi-dimensional facet filtering with index-level bitwise intersections and bidirectional string dictionaries (`.str`) for e-commerce, catalogs, and large categorical datasets.
- **Multi-Tier Junk & Lifecycle Management**: Segregates active records from historical/archived data (`.db` master vs `.jnk` tier) with seamless single-pass hybrid queries (`jnktype => 'A' | 'B' | 'AB' | 'BA'`).
- **ACID-Compliant Undo-Journal Transactions**: Full ACID multi-table transactions with disk-backed journaling (`.txn`), Strict Two-Phase Locking (Strict 2PL), automatic LIFO rollback upon failure or abnormal process exit, and orphaned journal recovery.
- **2-Pillar Disaster Recovery & Native `.amberdb` Archiving**: 
  - **Pillar 1 (Continuous Recovery Stream):** Automatic append-only audit stream in `backup/YYYY/YYYY-MM-DD.csv` capturing every `insert`, `modify`, and `delete`.
  - **Pillar 2 (Native Portable Archive):** Compressed, portable `.amberdb` archives containing schemas (`schema/*.table`, `schema/*.dbase`) and authoritative data files (`table/*.db`, `table/*.del`, `table/*.aut`, `table/*.cnt`, `table/*_*.str`) with SHA-256 integrity verification. Derived indexes are excluded to save space and reconstructed deterministically on restore.
- **Multi-Granularity Concurrency Control**: Non-blocking shared reads and exclusive writes at both table-level and individual record-level using OS-native `flock`.
- **ORM & Data Hydration (`inflate` / `deflate`)**: Native transformation between flat storage arrays and schema-mapped hash structures (`$adb->inflate` and `$adb->deflate`), including automatic RDBM foreign relationship resolution and repeating child rows.
- **Granular Field Operations**: Direct field mutation without full record rewriting via `update_field`, positional child block insertion via `insert_field`, and safe targeted child deletion via `delete_field`.
- **Multilingual Locale Engine**: Out-of-the-box support for 10 languages (`gb` [default Global Base], `en`, `tr`, `de`, `fr`, `es`, `ja`, `ru`, `ar`, `az`) with language-specific case folding (e.g. Turkish `ı/I` and `i/İ`), cross-lingual accent folding, collation, currency, and date formatting.
- **High-Throughput 2-Phase Batch Operations**: High-performance batch ingestion pipeline (`insert_list`, `modify_list`, `delete_list`) opens master `.db` once for batch writing and executes single-pass index merging (`.inx`, `.src`, `.fld`, `.fac`, `.srt`), delivering 50x-100x faster ETL data imports without per-record locking overhead.
- **Transparent Physical RAM-Disk Acceleration**: Integrated cross-platform orchestration (`tmpfs` Linux, `APFS` macOS, `ImDisk` Windows) across 4 operational tiers (0: Disk, 1: Hybrid Index-only, 2: Full RAM Mirror with dual-write, 3: Volatile pure RAM-disk with sliding TTL `ramdisk_ttl`). Supports custom directory isolation (`table_dir`).

---

## File System & Storage Architecture

AmberDB organizes database files into a clean, deterministic physical directory structure:

```text
dbstore/
├── schema/                     ← Database Group & Table Schemas
│   ├── catalog.dbase           ← Database group configuration
│   └── catalog_product.table   ← Product table schema
├── table/                      ← Master Data & Derived Index Files
│   ├── catalog_product.db      ← Primary key-value data table (DB_File Hash)
│   ├── catalog_product.del     ← Soft-deleted records archive (keep_deleted)
│   ├── catalog_product.aut     ← User audit trail log (log_owner)
│   ├── catalog_product.cnt     ← View/hit counters (use_counter)
│   ├── catalog_product.unq     ← Bidirectional string-to-ID dictionary
│   ├── catalog_product.inx     ← Primary 8-byte packed ID and sort index
│   ├── catalog_product.fld     ← Inverted exact-match field index ("$blk:$val")
│   ├── catalog_product.src     ← Full-text keyword search index
│   └── catalog_product.fac     ← Columnar facet filter index
└── backup/                     ← Disaster Recovery & Archives
    └── 2026/
        ├── 2026-08-28.csv      ← Continuous time-series audit stream (Pillar 1)
        └── full_backup.amberdb ← Compressed native database archive (Pillar 2)
```

### File Extension Reference

| File Extension | Classification | Reconstructible? | Description |
| :--- | :--- | :--- | :--- |
| **Authoritative Master Data** | | | |
| `.db` | **Primary Data (Source of Truth)** | **No** (Authoritative) | Berkeley DB master document table (`DB_File` Hash) |
| `.del` | **Soft-Deleted Archive** | **No** (Authoritative) | Archive of soft-deleted records (`keep_deleted`) |
| `.aut` | **User Audit Trail** | **No** (Authoritative) | Chronological user action log (`log_owner`) |
| `.str` | **String Dictionary** | **No** (Authoritative) | Bidirectional string-to-foreign-key dictionary (`_${blk}.str`) |
| **Derived Secondary Indexes** | | | |
| `.inx` | **Record Index** |  **Yes** (`set_index`) | Binary array of all active IDs, total count, highest ID |
| `.fld` | **Inverted Match Index** |  **Yes** (`set_index`) | Block-level key-to-IDs inverted index (`match_block`) |
| `.src` | **Full-Text Search Index** |  **Yes** (`set_index`) | Word-level token inverted index (`search_block`) |
| `.srt` | **Sorted Index** |  **Yes** (`set_index`) | Pre-sorted binary array of record IDs (`sort_block`) |
| `.fac` | **Facet Navigation Index** |  **Yes** (`set_index`) | Forward bitset index for faceted filter navigation (`facet_block`) |
| `.slg` | **URL Slug Map** |  **Yes** (`set_index`) | Bidirectional map: `_0.slg` (ID→Slug) and `_1.slg` (Slug→ID) |
| `.jinx`| **Junk Record Index** |  **Yes** (`set_index`) | Binary primary index for cold/archived records (`use_junk`) |
| `.jfld`| **Junk Match Index** |  **Yes** (`set_index`) | Field match index for cold records (`jnktype => 'B'/'AB'`) |
| `.jsrc`| **Junk Full-Text Search** |  **Yes** (`set_index`) | Word-level inverted index for cold records (`jnktype => 'B'/'AB'`) |
| **Runtime & Backup Files** | | | |
| `.amberdb` | **Native Database Archive** | Portable Archive | Compressed tar archive with schemas, data files, and SHA-256 manifest |
| `.csv` | **Continuous WAL Stream** | Append-Only Log | Daily chronological audit stream (`backup/YYYY/YYYY-MM-DD.csv`) |
| `.cnt` | **View / Hit Counter** | Counter State | High-throughput concurrent counter store (`use_counter`) |
| `.txn` | **Transaction Undo Journal** | Transient (Runtime) | Active transaction rollback journal file (`txn/`) |
| `.tmp` | **Disk Buffer File** | Transient (Staging) | Disk staging buffer file under `dbstore/buffer/` (`buffer_write`) |
| `.lock` | **Process Mutex Lock** | Transient (Mutex) | OS `flock` process synchronization lock file |

---

## Installation

### Via CPAN (Recommended)

AmberDB can be installed directly from CPAN across Linux, macOS, and Windows (Strawberry Perl / MSYS2 / MSYS64):

```bash
cpanm AmberDB
# or
cpan AmberDB
```

### Manual Build from Source

```bash
git clone https://github.com/marufcetin/amberdb.git
cd amberdb
perl Makefile.PL
make
make test
make install
```

*(On Windows, you can also install locally via `cpanm .` or `cpan .`)*

---

## Quick Start

### 1. Initialization

```perl
use strict;
use warnings;
use AmberDB;

# Initialize AmberDB instance handle ($adb)
my $adb = AmberDB->new(
    cfg  => { user => 'admin_user', language => 'gb' },
    path => { dbase_dir => './dbstore' }
);
```

### 2. CRUD Operations

```perl
# --- INSERT ---
# Record structure: (ID, Title, Category, Price, CreatedDate, Status)
# Pass ID = 0 to auto-generate a unique 64-bit ID
my $id = $adb->insert_id("catalog_product", 0, "Wireless Headphones", "Electronics", 149.99, "2026-08-28", 1);
print "Created Product ID: $id\n";

# --- READ ---
my @product = $adb->read_id("catalog_product", $id);
print "Product Title: $product[1]\n";

# --- UPDATE ---
$product[3] = 129.99; # Update Price
$adb->update_id("catalog_product", @product); # alias: modify_id

# --- DELETE ---
$adb->delete_id("catalog_product", $id);
```

### 3. Querying & Pagination

> [!IMPORTANT]
> **List Return Signature Convention:**
> In `read_all`, `field_fetch`, and `search_table`, when `limit > 0` (paginated), the method returns **`($total_count, @records)`** where the **first scalar** is the total matched count integer. When `limit` is omitted or 0 (unpaginated), it returns **`@records`** directly.
> Unpacking a paginated query as `my @records` causes `$records[0]` to be the integer count, throwing a fatal error on `$records[0]->[1]`.

```perl
# --- 1. Unpaginated Queries (Returns pure record or ID array) ---
my @all_products = $adb->read_all("catalog_product");
my @all_ids      = $adb->read_all("catalog_product", { keys_only => 1 }); # ID list (ultra low-memory)
my @sorted_all   = $adb->read_all("catalog_product", { sort => -3 });      # Unpaginated ascending sort

# --- 2. Paginated Queries (limit > 0: first element is $total_count integer) ---
my ($total_count, @page_products) = $adb->read_all(
    "catalog_product",
    {
        offset => 0,
        limit  => 20,
        sort   => { blk => 3, reverse => 1 }, # Sort descending by Price (field 3)
    }
);
print "Total Matching: $total_count, Page Size: " . scalar(@page_products) . "\n";

# Paginated high-efficiency pipeline returning only record IDs (keys_only)
my ($total, @page_ids) = $adb->read_all("catalog_product", { offset => 0, limit => 50, keys_only => 1 });
```

### 4. Full-Text Search

```perl
# Search product catalog with language normalization and filtering
my ($total, @results) = $adb->search_table(
    "catalog_product",
    "wireless headphone",
    {
        offset => 0,
        limit  => 20,
    }
);
```

### 5. Multi-Block Field & Facet Filtering

```perl
my $res = $adb->field_filter("catalog_product", {
    type   => "and",
    filter => {
        2 => "Electronics",
        5 => 1 # Active status
    },
    sort   => { blk => 3, reverse => 0 }, # Ascending price
    offset => 0,
    limit  => 10,
});

print "Found $res->{count} matching products.\n";
```

### 6. ACID Transactions & Strict 2PL (Undo-Journal)

AmberDB provides full **ACID-compliant transactions** via disk-backed undo-journaling and Strict Two-Phase Locking (Strict 2PL):

```perl
# Start atomic multi-table transaction
$adb->transact_start();

# 1. Check & deduct balance (acquires record lock, writes undo log)
my @account = $adb->read_id("user_account", $user_id);
if ($account[2] < 100.00) {
    $adb->transact_error("user_account", "Insufficient balance");
} else {
    $account[2] -= 100.00;
    $adb->modify_id("user_account", @account);

    # 2. Create order
    my $order_id = $adb->insert_id("order_master", 0, $user_id, 100.00, "COMPLETED");
}

# 3. Finalize transaction (commits if clean, automatically rolls back on error)
my $status = $adb->transact_end();
if ($status->{status} eq 'commit') {
    print "Order created and balance deducted successfully.\n";
} else {
    warn "Transaction aborted and changes rolled back automatically.\n";
}
```

### 7. Native Database Backup & Restore (`.amberdb`)

```perl
use AmberDB::Tools;

my $tools = AmberDB::Tools->new($adb);

# Create a compressed .amberdb backup archive
my $archive = $tools->dump();
# Archive created at: dbstore/backup/2026/amberdb_2026-08-28_180000.amberdb

# Restore archive with SHA-256 verification and automatic index rebuilding
my $result = $tools->restore(
    file    => "backup/2026/full_backup.amberdb",
    force   => 1, # Overwrite authorization for non-empty directories
    reindex => 1  # Automatically reconstruct .inx, .src, .fld, .fac, .srt
);
```

### 8. High-Throughput Batch Operations (Batch ETL & Ingestion)

When importing or updating hundreds or thousands of records from CSV, JSON, or external APIs, use the 2-phase batch methods (`insert_list`, `modify_list`, `delete_list`). These methods open the master `.db` file once and update all secondary indexes in a single batched pass, avoiding per-record locking and disk I/O overhead:

```perl
# --- BATCH INSERT ---
# Array of record tuples: [ [ID (0 for auto-assign), Title, Category, Price, Date, Status], ... ]
my @batch_products = (
    [ 0, "Mechanical Keyboard RGB", "Accessories", 129.99, "2026-08-28", 1 ],
    [ 0, "Ergonomic Office Chair",   "Furniture",   349.50, "2026-08-28", 1 ],
    [ 0, "4K Ultra-Wide Monitor",    "Electronics", 799.00, "2026-08-28", 1 ],
);

# Ingest batch in a single I/O pass with automatic index compilation
my $status = $adb->insert_list("catalog_product", @batch_products);
# Returns hashref of created IDs: { 101 => 1, 102 => 1, 103 => 1 }

# --- BATCH UPDATE ---
my @updates = (
    [ 101, "Mechanical Keyboard RGB v2", "Accessories", 139.99, "2026-08-28", 1 ],
    [ 102, "Ergonomic Office Chair XL",  "Furniture",   369.50, "2026-08-28", 1 ],
);
$adb->modify_list("catalog_product", @updates);

# --- BATCH DELETE ---
$adb->delete_list("catalog_product", 101, 102, 103);
```

---

## CLI Utilities

AmberDB ships with two consolidated, production-ready command-line tools in `bin/`:

### 1. `bin/amberdb_setup.pl` (Setup, Infrastructure & Maintenance)
Unified administrative entry point for setup, RAM-disk management, table upgrades, backups, and re-indexing:
```bash
# Display comprehensive usage and available actions
perl bin/amberdb_setup.pl

# Full infrastructure installation & permission setup
sudo perl bin/amberdb_setup.pl --action=install --user=eticaretim --size=256M --cron

# RAM-disk management (Linux tmpfs, macOS APFS, Windows ImDisk)
perl bin/amberdb_setup.pl --action=ramdisk --start --size=512M
perl bin/amberdb_setup.pl --action=ramdisk --status
perl bin/amberdb_setup.pl --action=ramdisk --stop

# Native backup (.amberdb dump and restore)
perl bin/amberdb_setup.pl --action=backup --dump --file=backup/catalog.amberdb
perl bin/amberdb_setup.pl --action=backup --restore --file=backup/catalog.amberdb --force

# Table migration (upgrade legacy tables to current ABR v1 binary format)
perl bin/amberdb_setup.pl --action=update --all

# Re-index secondary binary indexes (.inx, .fld, .src, .srt)
perl bin/amberdb_setup.pl --action=reindex
```

### 2. `bin/amberdb_daemon.pl` (Service Supervisor & Sync Daemon)
Unified process controller, self-healing cron watchdog, and Tier 4 background write-behind sync engine:
```bash
# Start background write-behind sync daemon
perl bin/amberdb_daemon.pl start

# Inspect running daemon, RAM-disk status, and journal queue
perl bin/amberdb_daemon.pl status

# Synchronous flush of all pending journal events
perl bin/amberdb_daemon.pl flush

# Gracefully stop daemon process
perl bin/amberdb_daemon.pl stop

# Cron watchdog (exits in <1ms if healthy, auto-restarts if dead)
perl bin/amberdb_daemon.pl watchdog
```

---

## Multilingual Locale Engine

AmberDB includes a built-in localization and text processing engine (`AmberDB::Locale`):

```perl
my $locale = AmberDB::Locale->new('tr');

# Correct Turkish case folding
print $locale->uc('ışık');        # "IŞIK"
print $locale->uc('istanbul');    # "İSTANBUL"
print $locale->lc('İZMİR');       # "izmir"

# Word normalization and phonetic devoicing
print $locale->normalize("Ahmet'in kitabı"); # "ahmet kitabi"

# Currency and number formatting
print $locale->format_currency(1250.50, 'TRY'); # "₺1.250,50"
```

Supported Languages: **Global Base (`gb`)**, **English (`en`)**, **Turkish (`tr`)**, **German (`de`)**, **French (`fr`)**, **Spanish (`es`)**, **Japanese (`ja`)**, **Russian (`ru`)**, **Arabic (`ar`)**, **Azerbaijani (`az`)**.

---

## Documentation

Full comprehensive guides are available in the [`docs/`](docs/) directory:

- **English Documentation**:
  - [AmberDB Database System & Architecture Guide](docs/EN.AmberDB_User-Guide.md)
  - [AmberDB::Locale User Guide](docs/EN.AmberDB-Locale_User-Guide.md)
  - [AmberDB vs SQL Comparison Guide](docs/EN.AmberDB-vs-SQL_User-Guide.md)
  - [AmberDB vs SQLite Benchmark Report (600K Movies)](docs/EN.AmberDB-vs-SQLite_Benchmark.md)
- **Türkçe Dokümantasyon**:
  - [AmberDB Veritabanı Sistemi & Mimari Rehberi](docs/TR.AmberDB_Veritabani_Sistemi.md)
  - [AmberDB::Locale Kullanım Rehberi](docs/TR.AmberDB-Locale_Kullanim_Rehberi.md)
  - [AmberDB vs SQL Karşılaştırmalı Kullanım Rehberi](docs/TR.AmberDB-vs-SQL_Kullanim_Rehberi.md)
  - [AmberDB vs SQLite Kıyaslama Raporu (600K Film)](docs/TR.AmberDB-vs-SQLite_Benchmark.md)

---

## Running Tests

AmberDB includes an exhaustive test suite covering core operations, indexing, transactions, search, facets, locales, and backups, along with multi-process concurrency stress tests:

```bash
# Run standard unit & integration test suite (51 test files, 470+ assertions)
prove -l t/

# Run author & extended integration test suite (RAM-disk & multi-process stress)
prove -l xt/
# or directly:
perl -Ilib xt/amberdb_ramdisk.t
perl -Ilib xt/amberdb_concurrency_stress.t
```

---

## Contributing

Contributions, bug reports, and pull requests are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Author

**Maruf Cetin**  
Email: [marufcetin@gmail.com](mailto:marufcetin@gmail.com)  
GitHub: [@marufcetin](https://github.com/marufcetin)

---

## License and Copyright

Copyright (C) 2005-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. See [LICENSE](LICENSE) for details.
