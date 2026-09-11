[Home](index.html) &nbsp;•&nbsp; [About](EN.About_AmberDB.html) &nbsp;•&nbsp; [Quick Start](#quick-start) &nbsp;•&nbsp; [Tutorial](EN.AmberDB_User-Guide.html) &nbsp;•&nbsp; [Benchmark](EN.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](EN.AmberDB-Locale_User-Guide.html) &nbsp;•&nbsp; [SQL Guide](EN.AmberDB-vs-SQL_User-Guide.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [Türkçe](index_tr.html)

---

[![CPAN version](https://badge.fury.io/pl/AmberDB.svg)](https://metacpan.org/pod/AmberDB)
[![Perl Version](https://img.shields.io/badge/perl-5.16%2B-blue.svg)](https://www.perl.org)
[![License](https://img.shields.io/badge/license-Artistic_2.0-brightgreen.svg)](https://github.com/marufcetin/amberdb/blob/main/LICENSE)
[![CI](https://github.com/marufcetin/amberdb/actions/workflows/ci.yml/badge.svg)](https://github.com/marufcetin/amberdb/actions)
[![Documentation](https://img.shields.io/badge/docs-GitHub_Pages-blue.svg)](https://marufcetin.github.io/amberdb/)
[![GitHub Repository](https://img.shields.io/badge/GitHub-marufcetin%2Famberdb-181717?logo=github)](https://github.com/marufcetin/amberdb)

**AmberDB** is a high-performance, schema-driven, embedded NoSQL database engine for Perl. Built on Berkeley DB (`DB_File`), it provides $O(1)$ 64-bit packed binary indexing, ACID transactions with Strict Two-Phase Locking (Strict 2PL), JSON-like nested extensible array records without relational SQL JOIN bottlenecks, faceted category filtering, and a multi-tier hot/cold junk architecture.

---

## Documentation & Guides

| Section | Description | Link |
| :--- | :--- | :--- |
| **About AmberDB** | Architecture overview, design philosophy, why AmberDB, and core capabilities. | [Read About AmberDB](EN.About_AmberDB.html) |
| **Tutorial & Developer Guide** | Comprehensive manual covering CRUD operations, schemas, transactions, indexing, search, and best practices. | [Open Developer Guide](EN.AmberDB_User-Guide.html) |
| **AmberDB for SQL Developers** | Practical migration guide with side-by-side SQL vs. AmberDB code equivalents, relations without JOINs, and cheat sheet. | [Open SQL Guide](EN.AmberDB-vs-SQL_User-Guide.html) |
| **Large-Scale Benchmark Report (600K Movies)** | Extensive benchmark on 600,000 real IMDb records: AmberDB vs SQLite 3 deep pagination, multi-field filtering, search, and point reads. | [Read Benchmark Report](EN.AmberDB-vs-SQLite_Benchmark.html) |
| **AmberDB::Locale Guide** | Multilingual (10 languages with Global Base default) string processing, locale-aware case folding, accent/circumflex unfolding, and collation. | [Open Locale Guide](EN.AmberDB-Locale_User-Guide.html) |
| **Release Changes** | Version history, recent architectural updates, and changelog. | [View Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) |
| **Project Wiki** | Method-by-method API documentation, concept deep-dives, flags, and file format references. | [Open Project Wiki](https://github.com/marufcetin/amberdb/wiki) |
| **Türkçe Dokümantasyon** | Türkçe ana sayfa, mimari makale, geliştirici kılavuzu ve dil kütüphanesi dokümanları. | [Türkçe Sayfaya Geç](index_tr.html) |

---

## Quick Start

### 1. Installation

Install AmberDB via CPAN or build from source:

```bash
# Via cpanm (Recommended)
cpanm AmberDB

# Or via standard CPAN shell
cpan AmberDB
```

Or install from GitHub source:

```bash
git clone https://github.com/marufcetin/amberdb.git
cd amberdb
perl Makefile.PL
make test
make install
```

---

### 2. Basic CRUD Example

Here is a complete, authentic CRUD walkthrough using AmberDB's array-based records:

```perl
use strict;
use warnings;
use AmberDB;

# 1. Initialize Database Instance
my $adb = AmberDB->new(
    cfg  => { user => 'admin', language => 'gb' },
    path => { dbase_dir => './dbstore' }
);

# 2. Define Record (Array-Based Document Structure)
my @product = (
    0,                          # [0] id (0 indicates auto-increment ID)
    "Wireless Headphones",      # [1] name
    149.99,                     # [2] price
    "Sony",                     # [3] brand
    "Electronics",              # [4] category
    { status => "In Stock" }    # [5] attributes (hash reference)
);

# 3. Insert Record
my $id = $product[0] = $adb->insert_id( "products", @product );

# 4. Read Record by ID
my @from_db = $adb->read_id( "products", $id );
print "Product: $from_db[1], Price: $from_db[2], Status: $from_db[5]->{status}\n";

# 5. Modify Record
$product[2] = 129.99; # Update price block
$adb->modify_id( "products", @product );

# 6. Full-Text Search
my @results = $adb->search_table( "products", "sony headphones" );
foreach my $p (@results) {
    print "ID: $p->[0] | Name: $p->[1] | Price: $p->[2]\n";
}

# 7. Delete Record
$adb->delete_id( "products", $id );
```

---

## Core Architecture & Capabilities

### 1. JOIN-Free Hierarchical Records
Instead of distributing data across multiple normalized tables and reassembling via costly SQL `JOIN`s, AmberDB stores records as natural, nested array tuples (including sub-arrays and sub-hashes). This matches Perl's native data structures and delivers ultra-fast retrieval.

### 2. 64-Bit Big-Endian Binary Indexing
Primary and secondary indexes use fixed 8-byte packed Big-Endian unsigned integer buffers (`Q*`). This guarantees $O(1)$ binary slicing, zero string-unpacking heuristics, and sub-millisecond pagination even across datasets scaling into millions of rows.

### 3. ACID Transactions with Strict 2PL
Full multi-table transaction support with a disk-backed undo journal (`.txn`) and Strict Two-Phase Locking (Strict 2PL). Abnormal terminations trigger automatic LIFO rollbacks upon recovery.

### 4. High-Throughput Batch Ingestion
Bulk ETL methods (`insert_list`, `modify_list`, `delete_list`) open master tables once and merge indexes in a single pass, delivering 50x-100x higher throughput compared to single-record loops.

### 5. Multi-Tier Junk & Archiving
Active records (`.db`) are seamlessly segregated from historical or archived rows (`.jnk`), supporting unified single-pass queries (`jnktype => 'A' | 'B' | 'AB' | 'BA'`).

### 6. Faceted Category Filter Engine
Built-in columnar facet indexing (`.fac`) with bitwise set intersections and string dictionaries (`.str`) enables instant e-commerce filtering menus without external search appliances.

---

## Feature Comparison

| Capability | AmberDB | SQLite | Traditional RDBMS (PostgreSQL/MySQL) |
| :--- | :--- | :--- | :--- |
| **Architecture** | Embedded (In-process Perl object) | Embedded C Library | Standalone Client-Server Daemon |
| **External Dependencies** | Standard Perl (`DB_File`) | C Library / DBI Driver | Server Daemon, Networking, ORM |
| **Record Model** | Extensible Array Document | Relational Rows & Columns | Relational Rows & Columns |
| **Relational JOINs** | JOIN-Free Nested Records | SQL `JOIN` | SQL `JOIN` |
| **Indexing Structure** | 64-bit Packed Binary (`Q*`) | B-Tree | B-Tree / GiST / GIN |
| **Full-Text Search** | Built-in (Locale & Accent-Aware) | SQLite FTS5 Module | Full-Text Engine / External (Elasticsearch) |
| **Faceted Filtering** | Built-in Columnar Bitwise (`.fac`) | Manual Queries | Manual Queries / External Engine |
| **ACID Transactions** | Undo Journal + Strict 2PL | WAL / Rollback Journal | WAL / MVCC |

---

## Resources & Community

* **GitHub Repository:** [https://github.com/marufcetin/amberdb](https://github.com/marufcetin/amberdb)
* **Comprehensive Wiki:** [https://github.com/marufcetin/amberdb/wiki](https://github.com/marufcetin/amberdb/wiki)
* **MetaCPAN Distribution:** [https://metacpan.org/pod/AmberDB](https://metacpan.org/pod/AmberDB)
* **Bug Tracker & Issues:** [https://github.com/marufcetin/amberdb/issues](https://github.com/marufcetin/amberdb/issues)
* **License:** [Artistic License 2.0](https://github.com/marufcetin/amberdb/blob/main/LICENSE)
