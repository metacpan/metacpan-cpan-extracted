[Home](index.html) &nbsp;•&nbsp; [About](EN.About_AmberDB.html) &nbsp;•&nbsp; [Quick Start](index.html#quick-start) &nbsp;•&nbsp; [Tutorial](EN.AmberDB_User-Guide.html) &nbsp;•&nbsp; [Benchmark](EN.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](EN.AmberDB-Locale_User-Guide.html) &nbsp;•&nbsp; [SQL Guide](EN.AmberDB-vs-SQL_User-Guide.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [Türkçe](TR.AmberDB-Hakkinda.html)

---

# About

**AmberDB** is an embedded NoSQL database engine for Perl that processes Array-based records supporting JSON-like nested and complex structures. Thanks to custom indexes generated through schema definitions, it performs block matching, querying, full-text search, filtering, and sorting operations swiftly, while also preserving the same search and querying quality in a schemaless and indexless setup.

It is built on the C code of Berkeley DB (`DB_File`) provided by the standard Perl package and does not use any other database engine. `DB_File` is Berkeley DB's low-level interface that provides key-value access via Perl. AmberDB constructs a data model, indexing, querying, transaction, and backup layer on top of it.

---

## Why AmberDB?

AmberDB brings together diverse capabilities within a single Perl database engine:

* **No External Database Server:** Embedded directly into the application as an in-process object.
* **Array-Based Records:** Database records are Arrays (lists) supporting JSON-like nested structures.
* **Full CRUD Operations:** Fast, direct insert, read, update, and delete methods.
* **Flexible Indexing:** Operates seamlessly both with and without indexes. Requires no separate setup for indexing.
* **Full-Text Search:** High-performance search (both indexed and unindexed).
* **Sorting & Versatile Queries:** Multi-field sorting, range queries, and regex filtering.
* **Nested & Repeating Blocks:** Automatic management of relational and repeating data blocks.
* **Multi-Table Relational Transactions:** ACID-compliant transaction management with Strict 2-Phase Locking (Strict 2PL).
* **Faceted Filtering:** Dynamic faceted filtering generation, just like on modern e-commerce sites.
* **RAM-to-Disk Tiering:** Embedded OS-level RAM-Disk acceleration layer without external cache daemons.
* **High-Throughput Batch Processing:** Dedicated bulk ingestion and index-merge pipeline.
* **Audit Logging:** Built-in logging of user operations on each record.
* **Soft Deletes:** Table-definition-specific soft delete (stores deleted records in an archive tier).
* **Automatic SEO Slugs:** Automatic URL slug generation for catalog tables.
* **Portable Backups:** Portable `.amberdb` database archives and restore tools with SHA-256 verification.

> **Core Principle:**  
> The database should make common application data operations simple, fast, and predictable.

---

## Quick Introductory Example

```perl
use strict;
use warnings;
use AmberDB;

# 1. Create AmberDB instance
my $adb = AmberDB->new(
    cfg  => { user => 'admin', language => 'gb' },
    path => { dbase_dir => './dbstore' }
);

# 2. Define product record
my @product = (
    0,                       # id (0 for auto-increment)
    "Wireless Headphones",   # name
    149.99,                  # price
    "Sony",                  # brand
    "Electronics",              # category
    { status => "In Stock" }    # status hash ref
);

# 3. Insert the product record into the "products" table
my $id = $product[0] = $adb->insert_id(
    "products",              # table
    @product                 # record
);

# 4. Reading the record back:
my @product_fromdb = $adb->read_id("products", $id);

# Print the record read from the database
print "Price: $product_fromdb[2], Status: $product_fromdb[5]->{status}\n";

# 5. Modification:
$product[2] = 129.99; # Assign a new value to block #2 and update the record using modify_id
$adb->modify_id("products", @product);

# 6. Search:
# AmberDB's `search_table` method locates terms appearing deep within lists, hash keys, and values.
my @search_result = $adb->search_table("products", "sony electronics headphones");
foreach my $product (@search_result) {
    print "Product ID : $product->[0]\n";
    print "Name       : $product->[1]\n";
    print "Price      : $product->[2]\n";
    print "Status     : $product->[5]->{status}\n";
}

# 7. And deletion:
$adb->delete_id("products", $id);
```

This is an example of the basic CRUD API. No SQL queries are used, no ORM is needed, and there is no separate query language between the Perl application and the database. Consequently, database access inside your application looks very much like working with an ordinary Perl object.

---

## Using Schemas for Advanced Applications

AmberDB runs without schema definitions. This can be practical for small tables (e.g., 10K records), but if you are dealing with large and relational tables scaling into millions, you must attach indexes via table schemas. Schemas can significantly boost the engine's capabilities by defining a table's structure and dictating how its data should be indexed and queried.

When you instantiate an AmberDB object, it will create a directory named `schema` under the path you provided as `dbase_dir`. You should create your `.table` extension schemas here:

```perl
my $adb = AmberDB->new( path => { dbase_dir => './dbstore' } );
# "dbstore/schema" will be created automatically.
```

Each table has a schema bearing the same name. In the example above, the schema for the `products` table must reside under `dbstore/schema/products.table`. There is no separate indexing system to configure. Once the schema is defined, AmberDB builds the necessary indexes automatically.

For example:

```perl
# dbstore/schema/products.table
{
    name         => "Products Table",
    record_index => 1,                  # all record keys will be indexed
    search_block => [2, 4, 5, 8],        # search keywords in these blocks will be indexed
    match_block  => [1, 3, 8],           # exact match indexes for these blocks
    sort_block   => [1, 3, 5, 7],        # sorting indexes for these blocks
}
```

AmberDB automatically builds inverted indexes for the blocks defined by the table schema. These indexes ensure exceptionally fast search and filtering operations even on massive datasets.

---

## Indexed Reads Instead of Scanning Records

AmberDB's index system is designed to perform the bulk of the work when data is inserted or when indexes are rebuilt, rather than repeatedly carrying out expensive workloads during queries.

This makes tasks such as filtering, sorting, pagination, and searching across large datasets feasible and straightforward without requiring an external search server.

```perl
my ($total, @products) = $adb->search_table(
    "products",              # table id
    "wireless headphones",   # query string
    {
        offset => 0,              # offset for pagination
        limit  => 20              # number of records per page
    }
);
```

In this example, all data for the first 0-20 slice matching the string `"wireless headphones"` in the `products` table is returned as an array of arrays within `@products`. Thanks to indexing, the result arrives within milliseconds even if the database holds millions of records.

> **Important Note:** If `limit` parameter is passed to `search_table`, it prepends `$total` to the return list. `$total` reports how many matching records exist in the table, which is essential for pagination.

---

## AmberDB Does Not Perform Joins

A record can contain or link to relational data from other tables. For instance, an order record may contain customer details, payment information, shipping and delivery details, various dates, and an order line items collection that includes product ID, title, unit price at purchase, applied discounts, and other metadata.

AmberDB treats these structures as part of the record model itself and leverages engine-level specialized indexes in the background to make querying straightforward.

This is especially advantageous when the application's natural domain model looks like this:

```
Order
├── Order ID
├── Customer ID
├── Address
├── Dates [as an array: order date, shipping date, delivery date]
├── Payment
├── Status
└── Products (repeating rows, each row being an array)
    ├── Product ID
    ├── Product Name
    ├── Quantity
    ├── Price
    └── Discount
```

Instead of distributing information across multiple tables and reconstructing it via joins at read time as in SQL, the application retains it directly as a single variable (array), matching Perl's native data model much more closely.

---

## Transactions and ACID Compliance

Despite being a performance-oriented NoSQL engine, AmberDB provides multi-table ACID transactions using an undo log and Strict Two-Phase Locking (Strict 2PL). AmberDB also supports concurrent access via OS-level file locking, making it suitable for multi-process Perl applications. The AmberDB Transaction API is straightforward to use, and its underlying mechanisms ensure atomicity, consistency, isolation, and durability across related operations.

```perl
$adb->transact_start();

# 1. Update order status
# 2. Update customer account
# 3. Update inventory
# 4. Insert payment record

$adb->transact_end();
```

If an error occurs, the entire transaction - including associated index changes - is rolled back. The undo log also ensures recovery following an unexpected process or system failure.

---

## Batch Operations for Large Imports

AmberDB utilizes batch operations for bulk data ingestion and processing. It provides dedicated methods for loading bulk records via imports such as XML, ETL, and CSV, updating existing records (e.g., updating a price list), or performing bulk deletions. Batch operations update all corresponding indexes in a single pass while refreshing the records.

AmberDB provides the following batch methods:

```perl
$adb->insert_list("products", @records); # batch insert
$adb->modify_list("products", @records); # batch modify
$adb->delete_list("products", @ids);     # batch delete
```

For instance, when inserting a list of one thousand records using `insert_list`, AmberDB creates the records and their indexes in a single batch process. Similarly, a massive price list can be modified within a single batch operation. This makes batch methods particularly useful for imports, migrations, synchronization tasks, and other high-volume data operations.

---

## Portable Backups

Because AmberDB is file-based, it is fully portable. It also includes safer native database tools for backup and restoration.

A database can be exported into a portable `.amberdb` archive containing the authoritative database state and schema. Integrity is verified using SHA-256, and derived indexes are rebuilt during restoration. This makes it possible to migrate or archive a complete database without requiring a separate database server. This process is also exceptionally well-suited for chronological backups and archiving.

---

## Epilogue

AmberDB provides an experience close to **PostgreSQL + Elasticsearch + Redis**, achieving this at an extremely low footprint and cost. It requires no standalone server installation and embeds directly into your application. It consumes minimal system resources, delivers rapid search and querying performance, and prevents bottlenecks even with large data files reaching into millions of records. It fits both tiny workloads and extensive, complex projects alike.

AmberDB is released under the **Artistic License 2.0**. Source code, documentation, and examples are available and actively maintained on CPAN and GitHub.

* **GitHub Issues:** [https://github.com/marufcetin/amberdb/issues](https://github.com/marufcetin/amberdb/issues)
* **MetaCPAN:** [https://metacpan.org/pod/AmberDB](https://metacpan.org/pod/AmberDB)

If you are interested in database systems or are a Perl developer, explore AmberDB and give it a try!
