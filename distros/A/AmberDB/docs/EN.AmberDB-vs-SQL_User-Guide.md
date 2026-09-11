[Home](index.html) &nbsp;•&nbsp; [About](EN.About_AmberDB.html) &nbsp;•&nbsp; [Quick Start](index.html#quick-start) &nbsp;•&nbsp; [Tutorial](EN.AmberDB_User-Guide.html) &nbsp;•&nbsp; [Benchmark](EN.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](EN.AmberDB-Locale_User-Guide.html) &nbsp;•&nbsp; [SQL Guide](EN.AmberDB-vs-SQL_User-Guide.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [Türkçe](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html)

---

# AmberDB for SQL Developers: A Comparative Practical Guide

> This guide is designed for software engineers coming from traditional relational database management systems (RDBMS / SQL) who want to quickly build applications with AmberDB. Rather than focusing on abstract theory or database philosophy, it adopts a direct **"In SQL it is done like X, in AmberDB it is done like Y"** approach with production-ready Perl code examples.

---

## Table of Contents

1. [Essential Practical Notes for Developers (Quick Intro)](#1-essential-practical-notes-for-developers-quick-intro)
2. [Basic CRUD Operations (DML)](#2-basic-crud-operations-dml)
   - [2.1 INSERT (Single Record)](#21-insert-single-record)
   - [2.2 BULK INSERT (Batch Ingestion)](#22-bulk-insert-batch-ingestion)
   - [2.3 SELECT by ID (Primary Key Point Read)](#23-select-by-id-primary-key-point-read)
   - [2.4 UPDATE by ID (Single Record Mutation)](#24-update-by-id-single-record-mutation)
   - [2.5 BULK UPDATE (Batch Mutation)](#25-bulk-update-batch-mutation)
   - [2.6 DELETE (Single Record Deletion & Soft-Delete)](#26-delete-single-record-deletion--soft-delete)
   - [2.7 BULK DELETE (Batch Deletion)](#27-bulk-delete-batch-deletion)
   - [2.8 COUNT(*) (Table Record Count)](#28-count-table-record-count)
3. [Querying, Filtering, and Search (SELECT, WHERE, LIKE)](#3-querying-filtering-and-search-select-where-like)
   - [3.1 Exact Match (WHERE field = value)](#31-exact-match-where-field--value)
   - [3.2 Multi-Value IN Lookup (WHERE id IN (...))](#32-multi-value-in-lookup-where-id-in-)
   - [3.3 Text Search (WHERE col LIKE '%...%' / FTS)](#33-text-search-where-col-like--fts)
   - [3.4 Compound Multi-Field Filtering (WHERE A = x AND B = y)](#34-compound-multi-field-filtering-where-a--x-and-b--y)
   - [3.5 Pagination (LIMIT & OFFSET)](#35-pagination-limit--offset)
4. [Sorting (ORDER BY) and Multilingual Collation](#4-sorting-order-by-and-multilingual-collation)
   - [4.1 Numeric and Text Sorting](#41-numeric-and-text-sorting)
   - [4.2 Multilingual and Turkish Character Collation](#42-multilingual-and-turkish-character-collation)
5. [Relationships and JOINs: The Core Architectural Difference](#5-relationships-and-joins-the-core-architectural-difference)
   - [5.1 SQL Normalized Multi-Table + JOIN Model](#51-sql-normalized-multi-table--join-model)
   - [5.2 AmberDB Embedded Document + match_block Inverted Index Model](#52-amberdb-embedded-document--match_block-inverted-index-model)
6. [Grouping and Filter Facet Counters (GROUP BY vs. Facet)](#6-grouping-and-filter-facet-counters-group-by-vs-facet)
7. [Transaction Safety and ACID (COMMIT & ROLLBACK)](#7-transaction-safety-and-acid-commit--rollback)
8. [Data Definition (DDL: CREATE TABLE vs. AmberDB Schema)](#8-data-definition-ddl-create-table-vs-amberdb-schema)
9. [Built-in AmberDB Capabilities Beyond Standard SQL](#9-built-in-amberdb-capabilities-beyond-standard-sql)
10. [Quick Reference Cheat Sheet](#10-quick-reference-cheat-sheet)
11. [Terminology Glossary](#11-terminology-glossary)

---

## 1. Essential Practical Notes for Developers (Quick Intro)

Before writing queries, keep these 4 operational rules in mind:

1. **No External Database Server or Daemon:** There is no `mysqld` or `postgres` background daemon to start, configure, or connect to over TCP. AmberDB is an embedded Perl object running directly inside your application process:
   ```perl
   use AmberDB;
   my $adb = AmberDB->new(
       cfg  => { user => 'admin', language => 'en' },
       path => { dbase_dir => './dbstore' }
   );
   ```
2. **Records Are Native Perl Arrays (`@record`):** An SQL table row corresponds to a native Perl array `($id, $field1, $field2, ...)`.
3. **Index 0 is ALWAYS the Primary Key ID:** The first element (`$record[0]`) is the unique identifier. Pass `0` or `undef` when inserting; `insert_id` assigns and returns the auto-incremented ID.
4. **Positional Block Indices Instead of Column Names:** Instead of named columns (`name`, `price`), AmberDB uses positional block indices (`1`, `2`, `3`...). Each block can hold scalars, nested `ARRAY` references, or `HASH` references directly.

> [!NOTE]
> For deep architectural mechanics, disk file specs, and benchmarks, refer to [About AmberDB](EN.About_AmberDB.html), [Comprehensive Developer Guide](EN.AmberDB_User-Guide.html), and [Large-Scale Benchmark](EN.AmberDB-vs-SQLite_Benchmark.html).

---

## 2. Basic CRUD Operations (DML)

### 2.1 INSERT (Single Record)

* **SQL:**
  ```sql
  INSERT INTO products (name, price, brand, category_id)
  VALUES ('Sony WH-1000XM5', 149.99, 'Sony', 5);
  ```

* **AmberDB:**
  ```perl
  # [0] ID (0: auto-assigned), [1] Name, [2] Price, [3] Brand, [4] Category ID
  my $id = $adb->insert_id("products", 0, "Sony WH-1000XM5", 149.99, "Sony", 5);
  ```

* **Explanation:** `insert_id` accepts the table identifier, the ID (0 for new records), followed by the field values. It returns the generated numeric ID. All configured inverted indexes are updated synchronously.
* **Reference:** [User Guide Section 3.1: insert_id](EN.AmberDB_User-Guide.html#31-single-record-insertion-insert_id)

---

### 2.2 BULK INSERT (Batch Ingestion)

* **SQL:**
  ```sql
  INSERT INTO products (name, price, brand) VALUES
    ('Item 1', 10.00, 'A'),
    ('Item 2', 20.00, 'B'),
    ('Item 3', 30.00, 'C');
  ```

* **AmberDB:**
  ```perl
  my @records = (
      [ 0, "Item 1", 10.00, "A" ],
      [ 0, "Item 2", 20.00, "B" ],
      [ 0, "Item 3", 30.00, "C" ],
  );
  my $status = $adb->insert_list("products", @records);
  # $status->{1} = first assigned ID, $status->{total}, etc.
  ```

* **Explanation:** `insert_list` ingests record arrays in a single atomic pass, minimizing file descriptor I/O and lock acquisition costs compared to iterative single inserts. Note that `@records` is passed as a list, without backslash.
* **Reference:** [User Guide Section 8: Batch ETL & Ingestion](EN.AmberDB_User-Guide.html#8-high-throughput-batch-operations-batch-etl--ingestion)

---

### 2.3 SELECT by ID (Primary Key Point Read)

* **SQL:**
  ```sql
  SELECT * FROM products WHERE id = 101;
  ```

* **AmberDB:**
  ```perl
  my @product = $adb->read_id("products", 101);
  if (@product) {
      print "ID: $product[0], Name: $product[1], Price: $product[2]\n";
  }
  ```

* **Explanation:** `read_id` looks up the primary key directly from Berkeley DB with zero SQL parsing or query optimizer overhead ($O(1)$ direct hash seek). Returns an empty list if not found.
* **Reference:** [User Guide Section 3.2: read_id](EN.AmberDB_User-Guide.html#32-record-retrieval-read_id)

---

### 2.4 UPDATE by ID (Single Record Mutation)

* **SQL:**
  ```sql
  UPDATE products
  SET price = 129.99
  WHERE id = 101;
  ```

* **AmberDB:**
  ```perl
  my @p = $adb->read_id("products", 101);
  $p[2] = 129.99; # Mutate Price in Block 2
  $adb->update_id("products", @p);
  ```

* **Explanation:** AmberDB stores records as cohesive documents. The recommended idiom is reading the record array, modifying the desired indices, and passing `@p` back to `update_id`. Since `$p[0]` holds `101`, the table name and array are sufficient.
* **Reference:** [User Guide Section 3.3: update_id](EN.AmberDB_User-Guide.html#33-record-mutation-update_id)

---

### 2.5 BULK UPDATE (Batch Mutation)

* **SQL:**
  ```sql
  UPDATE products SET price = 139.99 WHERE id = 101;
  UPDATE products SET price = 549.99 WHERE id = 102;
  ```

* **AmberDB:**
  ```perl
  my @updates = (
      [ 101, "Sony WH-1000XM5", 139.99, "Sony", 5 ],
      [ 102, "Apple AirPods Max", 549.99, "Apple", 5 ],
  );
  my $status = $adb->update_list("products", @updates);
  ```

* **Explanation:** Pass the array of updated record tuples directly to `update_list` without backslash. All secondary indexes are synchronized in batch mode.
* **Reference:** [User Guide Section 8: update_list](EN.AmberDB_User-Guide.html#8-high-throughput-batch-operations-batch-etl--ingestion)

---

### 2.6 DELETE (Single Record Deletion & Soft-Delete)

* **SQL:**
  ```sql
  DELETE FROM products WHERE id = 101;
  ```

* **AmberDB:**
  ```perl
  $adb->delete_id("products", 101);
  ```

* **Explanation:** `delete_id` removes the record and cleans up all inverted index keys (`.inx`, `.fld`, `.src`, `.fac`). If the schema defines `keep_deleted => 1`, the record is automatically moved to a `.del` archive rather than permanently purged.
* **Reference:** [User Guide Section 3.4: delete_id](EN.AmberDB_User-Guide.html#34-record-deletion-delete_id)

---

### 2.7 BULK DELETE (Batch Deletion)

* **SQL:**
  ```sql
  DELETE FROM products WHERE id IN (101, 102, 103);
  ```

* **AmberDB:**
  ```perl
  my $status = $adb->delete_list("products", 101, 102, 103);
  ```

* **Explanation:** Accepts a list of IDs to delete in a single batch pass.
* **Reference:** [User Guide Section 8: delete_list](EN.AmberDB_User-Guide.html#8-high-throughput-batch-operations-batch-etl--ingestion)

---

### 2.8 COUNT(*) (Table Record Count)

* **SQL:**
  ```sql
  SELECT COUNT(*) FROM products;
  ```

* **AmberDB:**
  ```perl
  my $total = $adb->table_count("products");
  ```

* **Explanation:** Reads the active key count directly without scanning table rows.
* **Reference:** [User Guide Section 15: Low-Level Table Operations](EN.AmberDB_User-Guide.html#15-data-structures-low-level-table-and-streaming-operations)

---

## 3. Querying, Filtering, and Search (SELECT, WHERE, LIKE)

### 3.1 Exact Match (WHERE field = value)

* **SQL:**
  ```sql
  SELECT * FROM products WHERE category_id = 5;
  ```

* **AmberDB:**
  ```perl
  # Block 4: category_id
  my ($total, @products) = $adb->field_fetch("products", 4, 5);
  print "Found $total products in Category 5.\n";
  ```

* **Explanation:** When `match_block => [4]` is declared, the engine retrieves matching records directly from the unified `.fld` inverted index file under the key `"4:5"` in $O(1)$ time.
* **Reference:** [User Guide Section 4.2: field_fetch](EN.AmberDB_User-Guide.html#42-field_fetch--inverted-match-index-fld-and-multi-value-querying)

---

### 3.2 Multi-Value IN Lookup (WHERE id IN (...))

* **SQL:**
  ```sql
  SELECT * FROM products WHERE id IN (10, 25, 42);
  ```

* **AmberDB:**
  ```perl
  my @products = $adb->read_list("products", [ 10, 25, 42 ]);
  ```

* **Explanation:** `read_list` fetches records for the given ID list in preserved order.
* **Reference:** [User Guide Section 4.1: read_list](EN.AmberDB_User-Guide.html#41-sequential-and-bulk-reading)

---

### 3.3 Text Search (WHERE col LIKE '%...%' / FTS)

* **SQL:**
  ```sql
  -- Via LIKE:
  SELECT * FROM products WHERE name LIKE '%headphones%' OR description LIKE '%headphones%';

  -- Or via Full-Text Search:
  SELECT * FROM products WHERE MATCH(name, description) AGAINST('headphones');
  ```

* **AmberDB:**
  ```perl
  my ($total, @results) = $adb->search_table("products", "headphones");
  foreach my $item (@results) {
      print "Matched ID: $item->[0], Name: $item->[1]\n";
  }
  ```

* **Explanation:** `search_table` searches against `.src` inverted indexes (or falls back to full scanning in simple mode). It deeply traverses nested lists and hashes, resolving casing and language accents natively via `AmberDB::Locale`.
* **Reference:** [User Guide Section 6: Indexing & Search](EN.AmberDB_User-Guide.html#6-indexing-and-search-mechanism)

---

### 3.4 Compound Multi-Field Filtering (WHERE A = x AND B = y)

* **SQL:**
  ```sql
  SELECT * FROM products
  WHERE category_id = 5 AND brand = 'Sony';
  ```

* **AmberDB:**
  ```perl
  my $res = $adb->field_filter("products", {
      filter => {
          4 => 5,       # Block 4 (category_id) = 5
          3 => "Sony",  # Block 3 (brand) = "Sony"
      }
  });
  my @matched_ids = @{ $res->{ids} };
  my @records = $adb->read_list("products", \@matched_ids); # or
  my @records = $adb->read_list("products", $res->{ids});
  ```

* **Explanation:** `field_filter` combines index lookups using fast binary set intersections (bitmask AND/OR) and returns matching IDs. `read_list` reads the full records.
* **Reference:** [User Guide Section 4.3: field_filter](EN.AmberDB_User-Guide.html#43-field_filter--multi-criteria-faceted-filtering)

---

### 3.5 Pagination (LIMIT & OFFSET)

* **SQL:**
  ```sql
  SELECT * FROM products
  ORDER BY id DESC
  LIMIT 20 OFFSET 40;
  ```

* **AmberDB:**
  ```perl
  # Parameters: tableid, \%options (offset, limit, sort)
  my ($total, @page) = $adb->read_all("products", { offset => 40, limit => 20, sort => { reverse => 1 } });
  print "Displaying 40-60 of $total records:\n";
  ```

* **Explanation:** `read_all` performs direct zero-copy byte offset slicing on the 8-byte binary ID array in `.inx`, completely avoiding SQLite/MySQL offset scan degradation on deep pages.
* **Reference:** [User Guide Section 4.1: read_all](EN.AmberDB_User-Guide.html#41-sequential-and-bulk-reading)

---

## 4. Sorting (ORDER BY) and Multilingual Collation

### 4.1 Numeric and Text Sorting

* **SQL:**
  ```sql
  SELECT * FROM products
  WHERE category_id = 5
  ORDER BY price ASC;
  ```

* **AmberDB:**
  ```perl
  # Dynamic sorting inside field_fetch:
  # tableid, block_index, block_val, \%options
  my ($total, @sorted) = $adb->field_fetch(
      "products", 4, 5,
      { offset => 0, limit => 20, sort => { blk => 2, reverse => 0 } } # Block 2 (price) ascending
  );
  ```

* **Explanation:** If `sort_block => [2]` is defined in the schema, the engine utilizes pre-sorted binary ID arrays in `.inx` to stream sorted records without runtime in-memory quicksort overhead.
* **Reference:** [User Guide Section 6.4: Sort Index](EN.AmberDB_User-Guide.html#64-sorting-mechanism-and-usage-guide)

---

### 4.2 Multilingual and Turkish Character Collation

* **SQL:**
  ```sql
  SELECT * FROM members
  ORDER BY name COLLATE utf8mb4_turkish_ci;
  ```

* **AmberDB:**
  ```perl
  # Configured language collation applies automatically:
  # cfg => { language => 'tr' }
  my ($total, @members) = $adb->read_all("members", { offset => 0, limit => 50, sort => { blk => 1 } });
  ```

* **Explanation:** AmberDB embeds its own multilingual collation engine (`AmberDB::Locale`). Non-ASCII characters (`Ç, Ğ, I, İ, Ö, Ş, Ü`) are properly alphabetized without external OS libc dependencies.
* **Reference:** [AmberDB::Locale Guide](EN.AmberDB-Locale_User-Guide.html)

---

## 5. Relationships and JOINs: The Core Architectural Difference

### 5.1 SQL Normalized Multi-Table + JOIN Model

SQL requires normalizing orders, line items, and products across separate tables joined via foreign keys:

```sql
SELECT o.id AS order_id, o.customer_name, oi.product_id, oi.quantity, p.name AS product_name
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE oi.product_id = 101;
```

**Cost:** Multiple B-Tree traversals, cross-table random disk seeks, temporary sorting buffers, and query-planner CPU overhead.

---

### 5.2 AmberDB Embedded Document + match_block Inverted Index Model

AmberDB embeds line items directly into the order record as a native Perl array reference (`ARRAY ref`):

```perl
my @order = (
    0,                             # [0] Order ID (auto-generated)
    "Ahmet Yılmaz",                # [1] Customer Name
    "2026-09-06",                  # [2] Date
    [                              # [3] Line Items (Nested ARRAY): [ [ ProductID, Qty, Price ], ... ]
        [ 101, 2, 149.99 ],
        [ 105, 1,  49.90 ],
    ],
    { status => "shipped" }        # [4] Metadata (HASH ref)
);

my $order_id = $adb->insert_id("orders", @order);
```

Schema declaration (`orders.table`):
```perl
{
    match_block => [ 3 ], # Index all nested item IDs automatically
}
```

#### Query: "Find all orders containing Product 101":

* **AmberDB Code:**
  ```perl
  my @orders = $adb->field_fetch("orders", 3, 101);
  foreach my $ord (@orders) {
      print "Order ID: $ord->[0], Customer: $ord->[1]\n";
  }
  ```

* **Why No JOIN is Needed:**
  All block matching indexes are consolidated into a single `<tableid>.fld` file (`orders.fld`). When an order is saved, IDs `101` and `105` inside the nested array are indexed under keys `"3:101"` and `"3:105"`. Querying `field_fetch("orders", 3, 101)` executes a **single direct hash seek** on `"3:101"` in $O(1)$ time.
* **Result:** Zero JOIN overhead, no secondary `order_items` junction table, and absolute data encapsulation.
* **Reference:** [User Guide Section 9: match_block](EN.AmberDB_User-Guide.html#9-schema-configuration-table-and-in-memory) & [Section 24.2: Low-I/O Relationships](EN.AmberDB_User-Guide.html#242-resolving-relationships-with-low-io-via-match_block)

---

## 6. Grouping and Filter Facet Counters (GROUP BY vs. Facet)

In e-commerce, sidebar facet counters such as *"Sony (12), Apple (8), Samsung (5)"* require SQL `GROUP BY` aggregates.

* **SQL:**
  ```sql
  SELECT brand, COUNT(*) AS count
  FROM products
  WHERE category_id = 5
  GROUP BY brand;
  ```

* **AmberDB (`field_fltkeys` Facet Engine):**
  ```perl
  # 1. Fetch Facet Counts (Returns count map only; does not fetch record bodies):
  # When facet_block => [ 3 ] is declared in schema:
  my $facets = $adb->field_fltkeys("products", {
      target_block => 3,          # Target attribute block to aggregate (Brand)
      filter       => { 4 => 5 }, # Active filter condition: Block 4 (Category ID) = 5
  });
  # $facets returns: { "Sony" => 12, "Apple" => 8, "Samsung" => 5 }

  # 2. Fetch Records When User Selects a Facet (read_list):
  # When user clicks "Sony", retrieve matching records:
  my $res = $adb->field_filter("products", {
      filter => { 4 => 5, 3 => "Sony" }
  });
  my @records = $adb->read_list("products", $res->{ids});
  # (Or directly for single block: my @prods = $adb->field_fetch("products", 3, "Sony");)
  ```

* **Explanation:** `field_fltkeys` returns the distribution count map directly from `.fac` columnar indexes in microseconds, avoiding heavy SQL `GROUP BY` temporary table builds. Records are then retrieved in batch via `read_list`.
* **Reference:** [User Guide Section 16: Facet System](EN.AmberDB_User-Guide.html#16-filter-and-category-menu-facet-system)

---

## 7. Transaction Safety and ACID (COMMIT & ROLLBACK)

AmberDB provides crash-safe undo-log transaction management and Strict 2PL (Two-Phase Locking).

* **SQL:**
  ```sql
  START TRANSACTION;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
  COMMIT; -- or ROLLBACK;
  ```

* **AmberDB:**
  ```perl
  # 1. Begin Transaction
  $adb->transact_start();

  my @sender   = $adb->read_id("accounts", 1);
  my @receiver = $adb->read_id("accounts", 2);

  if ($sender[1] >= 100) {
      $sender[1]   -= 100;
      $receiver[1] += 100;
      
      $adb->update_id("accounts", @sender);
      $adb->update_id("accounts", @receiver);
  } else {
      # Report error (triggers automatic rollback during transact_end)
      $adb->transact_error("accounts", "Insufficient funds");
  }

  # 2. Complete Transaction (Auto-rollback on error, otherwise commit)
  my $txn = $adb->transact_end();
  if ($txn->{status} eq "commit") {
      print "Transfer successful!\n";
  } else {
      print "Transaction aborted and changes rolled back!\n";
  }
  ```

* **Explanation:** Mutations between `transact_start` and `transact_end` are journaled to `.txn`. On failure or explicit rollback, all modified files (`.db`, `.del`, `.aut`, and indexes) are restored in reverse (LIFO) order. `transact_recover` automatically resolves incomplete transactions after abrupt server power outages.
* **Reference:** [User Guide Section 7: Transactions & Recovery](EN.AmberDB_User-Guide.html#7-transaction-safety-acid-guarantees-and-recovery-transactions)

---

## 8. Data Definition (DDL: CREATE TABLE vs. AmberDB Schema)

* **SQL:** Strict column typing, migration scripts (`ALTER TABLE`), and separate index definitions:
  ```sql
  CREATE TABLE products (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(255) NOT NULL,
      price DECIMAL(10,2) NOT NULL,
      brand VARCHAR(100),
      category_id INT,
      INDEX idx_cat (category_id),
      FULLTEXT idx_src (name)
  );
  ```

* **AmberDB:**
  - **Schemaless Operation:** Small applications can immediately write records via `$adb->insert_id("products", ...)` without defining schemas.
  - **Schema Declaration (`products.table` or `table_attr`):** For indexed and large-scale tables, declare index roles in a single Perl Hash:
  ```perl
  $adb->table_attr("products", {
      match_block  => [ 4 ],       # Category ID exact matching (.fld)
      search_block => [ 1 ],       # Title full-text search (.src)
      sort_block   => [ 2 ],       # Price pre-sorting (.inx)
      facet_block  => [ 3, 4 ],    # Brand and Category facet counters (.fac)
      slug_block   => [ 1 ],       # Auto-generate URL slugs from Title (.slg)
      keep_deleted => 1,           # Soft-delete recycle bin archive (.del)
      log_owner    => 1,           # Audit ledger (.aut)
  });
  ```

* **Explanation:** AmberDB schemas do not enforce rigid scalar data types, allowing NoSQL flexibility while automating inverted index derivation.
* **Reference:** [User Guide Section 9: Schema Configuration](EN.AmberDB_User-Guide.html#9-schema-configuration-table-and-in-memory)

---

## 9. Built-in AmberDB Capabilities Beyond Standard SQL

Common tasks that require external libraries, database triggers, or external cache daemons in SQL stacks are natively built into AmberDB:

| Feature | Standard Solution in SQL | Built-in AmberDB Solution |
|---|---|---|
| **Automatic SEO URL Slugs** | Custom slugify code, database uniqueness check queries. | `slug_block => [1]` automatically creates collision-free slugs like `/product/sony-wh-1000xm5` upon insert/update (`get_slug`). |
| **User Audit Trail (Audit Log)** | Separate audit tables, database triggers, or ORM event hooks. | `log_owner => 1` logs every modification into `.aut`. Call `$adb->auth_view("table", $id)` for an instant HTML timeline. |
| **High-Speed In-Memory Caching & Ephemeral Data (RAM-Disk)** | Installing and managing external caching servers (`Redis` or `Memcached`) to bypass disk I/O bottlenecks, managing TCP network overhead and cache-sync logic. | Zero external servers or daemons required: in-process L1 object caching (`set_cache`, `get_cache`) plus OS-level physical RAM-Disk acceleration (`use_ramdisk`, `ramdisk_*`) running directly on Berkeley DB files. Zero network hops, zero service dependencies. |
| **Safe Soft-Delete** | Adding `is_deleted` column and remembering `WHERE is_deleted = 0` on every query. | `keep_deleted => 1` moves deleted records to a `.del` archive. Prevents data leaks with zero query filtering overhead. |

* **Reference:** [User Guide Section 12: URL Slugs](EN.AmberDB_User-Guide.html#12-automated-url-slug-management) · [Section 13: Shared RAM Cache](EN.AmberDB_User-Guide.html#13-unified-shared-ram-cache-db--inx-and-buffer) · [Section 17: Audit Trail](EN.AmberDB_User-Guide.html#17-user-audit-trail-and-backup)

---

## 10. Quick Reference Cheat Sheet

A side-by-side mapping for common database operations:

| SQL Statement | AmberDB Method | AmberDB Usage Example |
|---|---|---|
| `INSERT INTO t VALUES (...)` | `insert_id` | `$id = $adb->insert_id("t", 0, @fields);` |
| `INSERT INTO t VALUES (...), (...)` | `insert_list` | `$adb->insert_list("t", @records);` |
| `SELECT * FROM t WHERE id = ?` | `read_id` | `my @rec = $adb->read_id("t", $id);` |
| `SELECT * FROM t WHERE id IN (...)` | `read_list` | `my @recs = $adb->read_list("t", $res->{ids});` |
| `SELECT * FROM t LIMIT 20 OFFSET 0` | `read_all` | `my ($tot, @recs) = $adb->read_all("t", { offset => 0, limit => 20 });` |
| `UPDATE t SET ... WHERE id = ?` | `update_id` | `$adb->update_id("t", @updated_rec);` |
| `DELETE FROM t WHERE id = ?` | `delete_id` | `$adb->delete_id("t", $id);` |
| `DELETE FROM t WHERE id IN (...)` | `delete_list` | `$adb->delete_list("t", @id_list);` |
| `SELECT COUNT(*) FROM t` | `table_count` | `my $count = $adb->table_count("t");` |
| `SELECT * FROM t WHERE col = val` | `field_fetch` | `my @recs = $adb->field_fetch("t", $blk, $val);` |
| `SELECT * FROM t WHERE col LIKE '%s%'` | `search_table` | `my @recs = $adb->search_table("t", "term");` |
| `SELECT * FROM t WHERE a=? AND b=?` | `field_filter` | `$adb->field_filter("t", { filter => { 1 => $a, 2 => $b } });` |
| `SELECT col, COUNT(*) GROUP BY col` | `field_fltkeys`| `$adb->field_fltkeys("t", { target_block => $blk, filter => { $fld => $val } });` |
| `START TRANSACTION` / `COMMIT` | `transact_*` | `$adb->transact_start(); ... $adb->transact_end();` |
| `CREATE TABLE` / `CREATE INDEX` | `table_attr` | `$adb->table_attr("t", { match_block => [ 1, 2 ] });` |

* **For Full Method Inventory:** [User Guide Section 23: Method Quick Reference Table](EN.AmberDB_User-Guide.html#23-method-quick-reference-table)

---

## 11. Terminology Glossary

Mapping SQL and relational concepts to AmberDB architecture:

| SQL / Relational Concept | AmberDB Equivalent | Technical Meaning |
|---|---|---|
| **Database Server / Instance** | `AmberDB` Object (`$adb`) | No background daemon or TCP port; lives embedded inside the application process. |
| **Table** | Table (`.db`) | Key-value store backed by Berkeley DB (`DB_File` Hash). |
| **Row / Record** | Array Record (`@record`) | Flexible Perl list rather than fixed-width C struct. Holds scalars, `ARRAY` refs, or `HASH` refs. |
| **Column / Field** | Block Index (`$record[$i]`) | Positional block index (`1`, `2`, `3`...) instead of column names. |
| **Primary Key (AUTO_INCREMENT)** | Index 0 (`$record[0]`) | The first element of the array. Auto-assigned monotonic numeric ID. |
| **Foreign Key & JOINs** | Nested Arrays & `match_block` | Denormalized documents with embedded lists; inverted index (`.fld`) provides $O(1)$ relationship lookups with zero JOINs. |
| **Index (`CREATE INDEX`)** | Schema Index Blocks | Inverted secondary indexes: Match (`.fld`), Full-text (`.src`), Facet (`.fac`), Sort (`.inx`). |
| **Query Optimizer / Planner** | Direct Key Seeks | Zero SQL parsing and cost compilation; binary RID blocks are read directly from disk. |
| **Collation / Charset** | `AmberDB::Locale` | Embedded multi-language and Turkish alphabet folding without external libc collation dependencies. |
| **Audit Table & Triggers** | `log_owner` & `.aut` | Built-in modification tracking recording user and timestamp. |
| **Soft-Delete (`is_deleted`)** | `keep_deleted` & `.del` | Deleted records are isolated in an archive file, preventing accidental data leaks. |
| **External Cache / Session Server (Redis / Memcached Alternative)** | `set_cache` / `get_cache` & RAM-Disk (`use_ramdisk`) | Without managing a separate daemon/server: in-process L1 object caching and OS-level shared memory RAM-Disk acceleration for critical and ephemeral tables with TTL support. |
