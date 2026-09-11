---
layout: default
title: Large-Scale Benchmark on 600,000 Real IMDb Records - AmberDB vs SQLite 3
description: Comparative benchmark evaluating AmberDB vs SQLite 3 on 600,000 real-world IMDb movies, deep offset pagination (read_all), inverted index search, multi-field filtering, and point read latency.
---

[Home](index.html) &nbsp;•&nbsp; [About](EN.About_AmberDB.html) &nbsp;•&nbsp; [Quick Start](index.html#quick-start) &nbsp;•&nbsp; [Tutorial](EN.AmberDB_User-Guide.html) &nbsp;•&nbsp; [Benchmark](EN.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](EN.AmberDB-Locale_User-Guide.html) &nbsp;•&nbsp; [SQL Guide](EN.AmberDB-vs-SQL_User-Guide.html) &nbsp;•&nbsp; [Türkçe](TR.AmberDB-vs-SQLite_Benchmark.html)

---

# Large-Scale Benchmark on 600,000 Real IMDb Records: AmberDB vs SQLite 3

**Publication Date:** September 2026 (Version 5.24.0)  
**Author / Project:** Maruf Çetin (AmberDB Project)  
**Test Environment:** Ubuntu 24.04 LTS (Linux Kernel 6.8.0) | 8 vCPU | 8 GiB RAM | Ext4 Filesystem  
**Engines Evaluated:** **AmberDB v5.24.0** (Pure Perl + Berkeley DB) vs **SQLite 3** (v3.45.1 / `DBD::SQLite` + FTS5)  
**Dataset:** 100% Authentic IMDb Official Dumps (**600,000 Feature Films**)

---

## 1. Introduction and Motivation

The true merit of a database engine's architecture cannot be measured by toy synthetic data; it must be tested against **real-world scale, diversity, and natural data distributions**.

This comprehensive benchmark evaluates AmberDB (an embedded NoSQL document database for Perl) against SQLite 3 (the world's most widely deployed C-based embedded database) across **600,000 real feature films** sourced from official IMDb data dumps (`datasets.imdbws.com`).

This report documents:
1. Complete isolation of write and read sessions to prevent dirty page-cache artifacts.
2. How AmberDB's fixed 8-byte binary indexing **beat SQLite by 10x in deep offset pagination (`read_all`)**.
3. Random primary key lookups (Point Read) clocking at **1.7 microseconds (5.3x faster than SQLite)**.
4. Multi-field compound filtering finishing **10.2x faster than SQLite**.
5. Sub-millisecond full-record retrieval across multiple columns in Omnibox search.

---

## 2. Methodology & Fair Benchmarking Principles

### A. Physical Severing of Write and Read Sessions
* **SQLite:** Upon bulk insert completion, `PRAGMA wal_checkpoint(TRUNCATE)` was executed, statement handles were finished, and the database connection (`$dbh->disconnect`) was closed.
* **AmberDB:** All tables and secondary index files were closed (`table_close`), flushing buffers, and the database coordinator instance was destroyed.
* **Isolated Processes:** Both engines were benchmarked in completely separate OS processes with a 3-second cooldown between runs.

### B. 100% Authentic IMDb Dumps
Downloaded directly from CloudFront (`datasets.imdbws.com`): mapping 600,000 feature films, 227,000 directors, 540,000 movie casts, and authentic IMDb ratings.

### C. SQLite Transaction Scope & Synchronous Pragma (Durability & ACID)
* **Single Enclosing Transaction:** Ingestion was wrapped in a single explicit transaction to unleash SQLite's compiled C throughput.
* **`PRAGMA synchronous = NORMAL;` (NOT `OFF`):** Adhered strictly to production engineering standards: WAL journal mode with `NORMAL` synchronization for crash resilience.

---

## 3. Head-to-Head Benchmark Results (600,000 Records)

All benchmarks below were executed on Linux Ext4 targeting pre-written disk files:

| Benchmark Metric / Scenario | SQLite 3 (FTS5 Indexed) | AmberDB v5.24.0 (Indexed) | Winner / Delta |
| :--- | :---: | :---: | :---: |
| **Total Real Records** | 600,000 movies | 600,000 movies | - |
| **Point Read Latency (Random Lookup)** | 9.0 µs | **1.7 µs** | **AmberDB (5.3x Faster - 588K ops/s)** |
| **Deep Paginated Scan (Offset: 430K, Limit: 20)** | 32.59 ms | **3.26 ms** | **AmberDB (10.0x FASTER!)** |
| **Multi-Field Filter (Director + Genre + Language)** | 91.84 ms | **8.96 ms** | **AmberDB (10.2x FASTER!)** |
| **Single-Block Fetch (All Director Movies)** | 24.05 ms | **21.99 ms** | **AmberDB (Faster)** |
| **Date Range Filter (1990-2016)** | **0.22 ms** | 2.79 ms | Both sub-3 ms |
| **Cross-Block Multi-Word (`Canadian Moore`)** | **0.32 ms** | 1.00 ms | Both millisecond-scale |
| **Omnibox Search (`beyaz 2012 ölü`)** | **0.23 ms** | 0.46 ms | Both under 0.5 ms |
| **Omnibox Search (`venky 2003 nenu`)** | **0.22 ms** | 0.44 ms | Both under 0.5 ms |
| **Omnibox Search (`natale 1996 green`)** | **0.38 ms** | 0.99 ms | Both under 1.0 ms |
| **Disk Storage Footprint** | **488.91 MB** | 522.95 MB | Close parity (AmberDB only +7%) |
| **Bulk Ingest Rate** | **12.55 sec** (47,814 r/s) | 433.64 sec (1,384 r/s) | SQLite (Compiled C) |

---

## 4. Architectural Deep Dive

### A. 1.7 Microsecond Point Reads: Direct C-Level Key Access and ABR v5
When querying an individual record by primary key (`table_readid` or `read_id`):
* AmberDB operates with zero SQL parsing, zero execution planning, and zero statement handle overhead.
* It performs direct key retrieval (`$db->get($id, $rec)`) via the native Berkeley DB (`DB_File`) C engine.
* The returned binary payload is decoded instantaneously in pure Perl via AmberDB v5.24.0's optimized binary record serializer (ABR v5).
* This enables AmberDB to serve point reads in **1.7 microseconds** (**588,000 ops/sec**), outperforming SQLite (9.0 µs / 111,000 ops/sec) by **5.3x**.

### B. Why AmberDB is 10x Faster in Deep Pagination (`read_all`)
In web applications and APIs, jumping to deep offsets (e.g. row 430,717) is an infamous performance trap:
* **SQLite's B-Tree Limitation:** SQLite must traverse 430,000 leaf entries sequentially in memory, consuming **32.59 ms**.
* **AmberDB's $O(1)$ Binary Mathematics:** AmberDB leaps directly to `430,717 * 8 bytes = 3,445,736 bytes` in its `.inx` key index, extracting the target 20 IDs in under 1 microsecond. The entire operation finishes in **3.26 ms** (**10x faster**).

### C. Multi-Field Compound Filtering: 10.2x Speedup
When intersecting multiple non-key conditions (Director + Genre + Language):
* SQLite combines FTS5 and B-Tree indexes, requiring 91.84 ms.
* AmberDB v5.24.0 uses **Adaptive Binary Search Pruning (`bin_crop`)** across memory-aligned 8-byte binary posting lists, resolving the intersection in **8.96 ms**.

---

## 5. Reproducing the Benchmark

All benchmarks and drivers are open-source and included in the repository:

```bash
# 1. Clone repository
git clone https://github.com/marufcetin/amberdb.git
cd amberdb

# 2. Download official IMDb dumps and build the 600K+ master dataset (~633K movies)
perl benchmark/download_real_imdb.pl

# (Alternative: Generate offline synthetic test data instantly without downloading)
# perl benchmark/data/prepare_data.pl --generate --total=100000

# 3. Run the 600K benchmark in isolated processes
perl -Ilib benchmark/run_benchmark.pl total=600000 motors=amberdb,sqlite -with-index -random action=read
```

---

## 6. Executive Conclusion

SQLite is a masterwork of 24 years of micro-optimized C engineering. Its compiled C engine provides unmatched bulk ingestion speed.

However, **AmberDB v5.24.0 (written in pure Perl)** delivers a historic software architecture lesson:

> **"The right choice of algorithms and binary data structures can outperform even compiled C."**

Across 600,000 real-world movies:
* **10x faster** in deep offset pagination (3.26 ms vs 32.59 ms),
* **5.3x faster** in primary key point reads (1.7 µs vs 9.0 µs),
* **10.2x faster** in multi-field compound filtering (8.96 ms vs 91.84 ms),
* **Sub-millisecond** cross-block fulltext record retrieval (0.4 - 0.9 ms).

AmberDB establishes itself as a state-of-the-art embedded NoSQL document database for Perl.
