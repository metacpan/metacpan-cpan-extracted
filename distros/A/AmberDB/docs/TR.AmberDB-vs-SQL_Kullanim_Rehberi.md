[Ana Sayfa](index_tr.html) &nbsp;•&nbsp; [Hakkında](TR.AmberDB-Hakkinda.html) &nbsp;•&nbsp; [Hızlı Başlangıç](index_tr.html#hızlı-başlangıç) &nbsp;•&nbsp; [Tutorial](TR.AmberDB_Veritabani_Sistemi.html) &nbsp;•&nbsp; [Benchmark](TR.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](TR.AmberDB-Locale_Kullanim_Rehberi.html) &nbsp;•&nbsp; [SQL Rehberi](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [English](EN.AmberDB-vs-SQL_User-Guide.html)

---

# SQL ile Karşılaştırmalı AmberDB Kullanım Rehberi

> Bu kılavuz, geleneksel ilişkisel veritabanı (RDBMS / SQL) deneyimi olan geliştiricilerin AmberDB'ye hızla adapte olabilmesi için hazırlanmıştır. Kuramsal ve felsefi detaylar yerine, **"SQL'de şu şekilde yapılan işlem AmberDB'de şu şekilde yapılır"** yaklaşımıyla doğrudan çalışan kod örneklerine odaklanır.

---

## İçindekiler

1. [Geliştiricinin Bilmesi Gereken Temel Notlar (Hızlı Giriş)](#1-geliştiricinin-bilmesi-gereken-temel-notlar-hızlı-giriş)
2. [Temel CRUD İşlemleri (DML)](#2-temel-crud-işlemleri-dml)
   - [2.1 INSERT (Tekil Kayıt Ekleme)](#21-insert-tekil-kayıt-ekleme)
   - [2.2 BULK INSERT (Toplu Kayıt Ekleme)](#22-bulk-insert-toplu-kayıt-ekleme)
   - [2.3 SELECT by ID (Birincil Anahtarla Okuma)](#23-select-by-id-birincil-anahtarla-okuma)
   - [2.4 UPDATE by ID (Kayıt Güncelleme)](#24-update-by-id-kayıt-güncelleme)
   - [2.5 BULK UPDATE (Toplu Güncelleme)](#25-bulk-update-toplu-güncelleme)
   - [2.6 DELETE (Kayıt Silme & Soft-Delete)](#26-delete-kayıt-silme--soft-delete)
   - [2.7 BULK DELETE (Toplu Silme)](#27-bulk-delete-toplu-silme)
   - [2.8 COUNT(*) (Kayıt Sayısı)](#28-count-kayıt-sayısı)
3. [Sorgulama, Filtreleme ve Arama (SELECT, WHERE, LIKE)](#3-sorgulama-filtreleme-ve-arama-select-where-like)
   - [3.1 Tekil Değer Eşleşmesi (WHERE field = value)](#31-tekil-değer-eşleşmesi-where-field--value)
   - [3.2 Çoklu Değer Listesi (WHERE id IN (...))](#32-çoklu-değer-listesi-where-id-in-)
   - [3.3 Metin Arama (WHERE col LIKE '%...%' / FTS)](#33-metin-arama-where-col-like--fts)
   - [3.4 Çok Kriterli Filtreleme (WHERE A = x AND B = y)](#34-çok-kriterli-filtreleme-where-a--x-and-b--y)
   - [3.5 Sayfalama (LIMIT & OFFSET)](#35-sayfalama-limit--offset)
4. [Sıralama (ORDER BY) ve Alfabetik Yerelleştirme (Collation)](#4-sıralama-order-by-ve-alfabetik-yerelleştirme-collation)
   - [4.1 Sayısal ve Alfabetik Sıralama](#41-sayısal-ve-alfabetik-sıralama)
   - [4.2 Türkçe ve Çok Dilli Karakter Sıralaması (Collation)](#42-türkçe-ve-çok-dilli-karakter-sıralaması-collation)
5. [İlişkiler ve JOIN Mantığı (En Büyük Mimari Fark)](#5-ilişkiler-ve-join-mantığı-en-büyük-mimari-fark)
   - [5.1 SQL Normalize Tablo + JOIN Modeli](#51-sql-normalize-tablo--join-modeli)
   - [5.2 AmberDB İç İçe Belge + match_block Tersine İndeks Modeli](#52-amberdb-i̇ç-i̇çe-belge--match_block-tersine-i̇ndeks-modeli)
6. [Gruplama ve Filtre Sayaçları (GROUP BY vs. Facet)](#6-gruplama-ve-filtre-sayaçları-group-by-vs-facet)
7. [İşlem Güvenliği ve ACID (Transactions: COMMIT & ROLLBACK)](#7-i̇şlem-güvenliği-ve-acid-transactions-commit--rollback)
8. [Veri Tanımlama (DDL: CREATE TABLE vs. AmberDB Şeması)](#8-veri-tanımlama-ddl-create-table-vs-amberdb-şeması)
9. [SQL'de Harici Kod Gerektiren Yerleşik AmberDB Artıları](#9-sqlde-harici-kod-gerektiren-yerleşik-amberdb-artıları)
10. [Hızlı Referans ve Kopya Kağıdı (Cheat Sheet)](#10-hızlı-referans-ve-kopya-kağıdı-cheat-sheet)
11. [Kavramlar Sözlüğü (Terminology Glossary)](#11-kavramlar-sözlüğü-terminology-glossary)

---

## 1. Geliştiricinin Bilmesi Gereken Temel Notlar (Hızlı Giriş)

AmberDB ile kod geliştirmeye başlamadan önce bilmeniz gereken 4 pratik kural:

1. **Ayrı Bir Veritabanı Sunucusu Yoktur:** `MySQL` veya `PostgreSQL` gibi bir servis başlatmanız veya ağ bağlantısı kurmanız gerekmez. AmberDB, uygulamanızın içine bir Perl nesnesi olarak dahil edilir ve doğrudan yerel diskte çalışır.
   ```perl
   use AmberDB;
   my $adb = AmberDB->new(
       cfg  => { user => 'admin', language => 'tr' },
       path => { dbase_dir => './dbstore' }
   );
   ```
2. **Kayıtlar Doğal Perl Dizileridir (`@record`):** SQL'deki tablo satırı, AmberDB'de `($id, $alan1, $alan2, ...)` şeklinde bir Perl dizisidir.
3. **0. İndis Daima Primary Key ID'dir:** Dizinin 0. elemanı (`$record[0]`) kaydın benzersiz kimliğidir. Yeni kayıtlarda buraya `0` veya `undef` verilir; `insert_id` çağrısı otomatik artan ID'yi üretir.
4. **Sütun İsimleri Yerine Blok Numaraları:** SQL'deki `name`, `price`, `status` sütun adları yerine tablodaki pozisyonel blok indisleri (`1`, `2`, `3`...) kullanılır. Alanlarda düz skalar değerlerin yanı sıra iç içe `ARRAY` veya `HASH` referansları da doğrudan saklanabilir.

> [!NOTE]
> AmberDB'nin derin mimari altyapısı, disk dosya formatları ve benchmark sonuçları için [AmberDB Hakkında](TR.AmberDB-Hakkinda.html), [Kapsamlı Tutorial](TR.AmberDB_Veritabani_Sistemi.html) ve [Benchmark Raporu](TR.AmberDB-vs-SQLite_Benchmark.html) sayfalarına başvurabilirsiniz.

---

## 2. Temel CRUD İşlemleri (DML)

### 2.1 INSERT (Tekil Kayıt Ekleme)

* **SQL:**
  ```sql
  INSERT INTO products (name, price, brand, category_id)
  VALUES ('Sony WH-1000XM5', 149.99, 'Sony', 5);
  ```

* **AmberDB:**
  ```perl
  # [0] ID (0: otomatik artan), [1] Ad, [2] Fiyat, [3] Marka, [4] Kategori ID
  my $id = $adb->insert_id("products", 0, "Sony WH-1000XM5", 149.99, "Sony", 5);
  ```

* **Açıklama:** `insert_id` ilk parametrede tablo adını, ikinci parametrede ID'yi (yeni kayıtlarda 0) ve ardından alanları alır. Otomatik atanan yeni ID numarasını skalar olarak döner. Tüm tanımlı indeksler eşzamanlı güncellenir.
* **Referans:** [Tutorial Bölüm 3.1: insert_id](TR.AmberDB_Veritabani_Sistemi.html#31-kayıt-ekleme-insert_id)

---

### 2.2 BULK INSERT (Toplu Kayıt Ekleme)

* **SQL:**
  ```sql
  INSERT INTO products (name, price, brand) VALUES
    ('Ürün 1', 10.00, 'A'),
    ('Ürün 2', 20.00, 'B'),
    ('Ürün 3', 30.00, 'C');
  ```

* **AmberDB:**
  ```perl
  my @records = (
      [ 0, "Ürün 1", 10.00, "A" ],
      [ 0, "Ürün 2", 20.00, "B" ],
      [ 0, "Ürün 3", 30.00, "C" ],
  );
  my $status = $adb->insert_list("products", @records);
  # $status->{1} = ilk eklenen ID, $status->{total} vb.
  ```

* **Açıklama:** `insert_list`, dizi referanslarını toplu oturumda yazar. Tek tek eklemek yerine I/O ve kilit açma/kapama maliyetini minimuma indirir.
* **Referans:** [Tutorial Bölüm 8: insert_list Toplu İşlemler](TR.AmberDB_Veritabani_Sistemi.html#8-yüksek-başarımlı-toplu-batch-işlemler-batch-etl--ingestion)

---

### 2.3 SELECT by ID (Birincil Anahtarla Okuma)

* **SQL:**
  ```sql
  SELECT * FROM products WHERE id = 101;
  ```

* **AmberDB:**
  ```perl
  my @product = $adb->read_id("products", 101);
  if (@product) {
      print "ID: $product[0], Ad: $product[1], Fiyat: $product[2]\n";
  }
  ```

* **Açıklama:** `read_id`, birincil anahtara doğrudan erişerek kaydı dizi olarak döner. Kayıt yoksa boş liste döner. Sorgu planlama veya derleme yükü yoktur, $O(1)$ doğrudan anahtar erişimidir.
* **Referans:** [Tutorial Bölüm 3.2: read_id](TR.AmberDB_Veritabani_Sistemi.html#32-kayıt-okuma-read_id)

---

### 2.4 UPDATE by ID (Kayıt Güncelleme)

* **SQL:**
  ```sql
  UPDATE products
  SET price = 129.99
  WHERE id = 101;
  ```

* **AmberDB:**
  ```perl
  my @p = $adb->read_id("products", 101);
  $p[2] = 129.99; # 2. bloktaki fiyatı güncelle
  $adb->update_id("products", @p);
  ```

* **Açıklama:** AmberDB kayıtları bir bütün olarak saklar. Kaydı okuyup ilgili dizi elemanını değiştirdikten sonra `@p` dizisini `update_id`'ye göndermek standart ve güvenli yoldur. `@p[0]` zaten kayıt ID'sini içerdiğinden tablo ve dizi parametreleri yeterlidir.
* **Referans:** [Tutorial Bölüm 3.3: update_id](TR.AmberDB_Veritabani_Sistemi.html#33-kayıt-güncelleme-update_id)

---

### 2.5 BULK UPDATE (Toplu Güncelleme)

* **SQL:**
  ```sql
  -- Genellikle transaction veya geçici tablo ile yürütülür
  UPDATE products SET price = price * 1.10 WHERE id IN (101, 102);
  ```

* **AmberDB:**
  ```perl
  my @updates = (
      [ 101, "Sony WH-1000XM5", 139.99, "Sony", 5 ],
      [ 102, "Apple AirPods Max", 549.99, "Apple", 5 ],
  );
  my $status = $adb->update_list("products", @updates);
  ```

* **Açıklama:** Güncellenecek kayıt listesini `update_list` metoduna göndererek tek seferde ve kilit verimliliğiyle tüm indeksleri güncelleyebilirsiniz.
* **Referans:** [Tutorial Bölüm 8: update_list](TR.AmberDB_Veritabani_Sistemi.html#8-yüksek-başarımlı-toplu-batch-işlemler-batch-etl--ingestion)

---

### 2.6 DELETE (Kayıt Silme & Soft-Delete)

* **SQL:**
  ```sql
  DELETE FROM products WHERE id = 101;
  ```

* **AmberDB:**
  ```perl
  $adb->delete_id("products", 101);
  ```

* **Açıklama:** `delete_id`, kaydı tablodan ve tüm ilişkili indekslerden (`.inx`, `.fld`, `.src`, `.fac`, `.srt`) anında kaldırır. Eğer tablonun şemasında `keep_deleted => 1` etkinse kayıt yok edilmez; `.del` soft-delete çöp kutusuna taşınarak kurtarılabilir kılınır.
* **Referans:** [Tutorial Bölüm 3.4: delete_id](TR.AmberDB_Veritabani_Sistemi.html#34-kayıt-silme-delete_id)

---

### 2.7 BULK DELETE (Toplu Silme)

* **SQL:**
  ```sql
  DELETE FROM products WHERE id IN (101, 102, 103);
  ```

* **AmberDB:**
  ```perl
  my $status = $adb->delete_list("products", 101, 102, 103);
  ```

* **Açıklama:** Birden çok ID'yi liste olarak siler. Döngü içinde tek tek `delete_id` çağırmaktan çok daha hızlıdır.
* **Referans:** [Tutorial Bölüm 8: delete_list](TR.AmberDB_Veritabani_Sistemi.html#8-yüksek-başarımlı-toplu-batch-işlemler-batch-etl--ingestion)

---

### 2.8 COUNT(*) (Kayıt Sayısı)

* **SQL:**
  ```sql
  SELECT COUNT(*) FROM products;
  ```

* **AmberDB:**
  ```perl
  my $total = $adb->table_count("products");
  ```

* **Açıklama:** Tablodaki toplam etkin kayıt sayısını anında döner. Bütün tabloyu taramaz; Berkeley DB anahtar sayısını doğrudan okur.
* **Referans:** [Tutorial Bölüm 15: table_count](TR.AmberDB_Veritabani_Sistemi.html#15-veri-yapıları-düşük-seviyeli-tablo-ve-akış-işlemleri)

---

## 3. Sorgulama, Filtreleme ve Arama (SELECT, WHERE, LIKE)

### 3.1 Tekil Değer Eşleşmesi (WHERE field = value)

* **SQL:**
  ```sql
  SELECT * FROM products WHERE category_id = 5;
  ```

* **AmberDB:**
  ```perl
  # 4. blok: category_id
  my ($total, @products) = $adb->field_fetch("products", 4, 5);
  print "Toplam $total adet kategori-5 ürünü bulundu.\n";
  ```

* **Açıklama:** Şemada `match_block => [4]` tanımlanmışsa, motor `.fld` tersine indeksinden doğrudan `5` anahtarını arar ve eşleşen kayıtları getirir.
* **Referans:** [Tutorial Bölüm 4.2: field_fetch](TR.AmberDB_Veritabani_Sistemi.html#42-blok-indeksiyle-filtreleme-ve-sayfalama-field_fetch)

---

### 3.2 Çoklu Değer Listesi (WHERE id IN (...))

* **SQL:**
  ```sql
  SELECT * FROM products WHERE id IN (10, 25, 42);
  ```

* **AmberDB:**
  ```perl
  my @products = $adb->read_list("products", [ 10, 25, 42 ]);
  ```

* **Açıklama:** `read_list` metodu verilen ID listesini sırasıyla doğrudan diskten çeker ve kayıt referanslarını döner.
* **Referans:** [Tutorial Bölüm 4.1: read_list](TR.AmberDB_Veritabani_Sistemi.html#41-toplu-ve-sıralı-okuma)

---

### 3.3 Metin Arama (WHERE col LIKE '%...%' / FTS)

* **SQL:**
  ```sql
  -- LIKE ile (İndekssiz veya yavaş):
  SELECT * FROM products WHERE name LIKE '%kulaklık%' OR description LIKE '%kulaklık%';

  -- veya Full-Text Search ile:
  SELECT * FROM products WHERE MATCH(name, description) AGAINST('kulaklık');
  ```

* **AmberDB:**
  ```perl
  my ($total, @results) = $adb->search_table("products", "kulaklık");
  foreach my $item (@results) {
      print "Bulunan ID: $item->[0], Ad: $item->[1]\n";
  }
  ```

* **Açıklama:** `search_table` hem şemasız basit modda hem de `.src` tam metin indeksi tanımlı tablolarda çalışır. İç içe dizilerin derinliklerindeki kelimeleri de bulur. Harici arama motoru gerektirmeden `AmberDB::Locale` altyapısıyla Türkçe aksan ve büyük/küçük harf duyarsızlığını (İ/ı, ç/c) doğal olarak çözer.
* **Referans:** [Tutorial Bölüm 6: İndeksleme ve Arama Mekanizması](TR.AmberDB_Veritabani_Sistemi.html#6-indeksleme-ve-arama-mekanizması)

---

### 3.4 Çok Kriterli Filtreleme (WHERE A = x AND B = y)

* **SQL:**
  ```sql
  SELECT * FROM products
  WHERE category_id = 5 AND brand = 'Sony';
  ```

* **AmberDB:**
  ```perl
  my $res = $adb->field_filter("products", {
      filter => {
          4 => 5,       # Blok 4 (category_id) = 5
          3 => "Sony",  # Blok 3 (brand) = "Sony"
      }
  });
  my @matched_ids = @{ $res->{ids} };
  my @records = $adb->read_list("products", \@matched_ids); # veya 
  my @records = $adb->read_list("products", $res->{ids}); 
  ```

* **Açıklama:** `field_filter`, birden fazla alanın eşleşme indekslerini binary küme kesişimi (set intersection) ile birleştirir.
* **Referans:** [Tutorial Bölüm 4.3: field_filter](TR.AmberDB_Veritabani_Sistemi.html#43-gelişmiş-arama-ve-dinamik-kombinasyonlar-field_filter)

---

### 3.5 Sayfalama (LIMIT & OFFSET)

* **SQL:**
  ```sql
  SELECT * FROM products
  ORDER BY id DESC
  LIMIT 20 OFFSET 40;
  ```

* **AmberDB:**
  ```perl
  # Parametreler: tablo, \%secenekler (offset, limit, sort)
  my ($total, @page) = $adb->read_all("products", { offset => 40, limit => 20, sort => { reverse => 1 } });
  print "Toplam $total kayıttan 40-60 arası gösteriliyor:\n";
  ```

* **Açıklama:** `read_all` metodu veritabanının kayıt ID dizisi üzerinde doğrudan ikili arama ve dilimleme yapar. SQLite ve MySQL'in yüksek offset değerlerinde yaşadığı derin sayfalama yavaşlığını yaşamaz.
* **Referans:** [Tutorial Bölüm 4.1: read_all](TR.AmberDB_Veritabani_Sistemi.html#41-toplu-ve-sıralı-okuma)

---

## 4. Sıralama (ORDER BY) ve Alfabetik Yerelleştirme (Collation)

### 4.1 Sayısal ve Alfabetik Sıralama

* **SQL:**
  ```sql
  SELECT * FROM products
  WHERE category_id = 5
  ORDER BY price ASC;
  ```

* **AmberDB:**
  ```perl
  # field_fetch içinde dinamik sıralama:
  # tabloid, blok_indis, blok_değeri, \%secenekler
  my ($total, @sorted) = $adb->field_fetch(
      "products", 4, 5,
      { offset => 0, limit => 20, sort => { blk => 2, reverse => 0 } } # Blok 2 (fiyat) artan
  );
  ```

* **Açıklama:** Tablo şemasında `sort_block => [2]` tanımlanmışsa, motor `.srt` indeksini kullanarak ekstra bellek sıralaması yapmadan veriyi doğrudan sıralı getirir.
* **Referans:** [Tutorial Bölüm 6.4: Sıralama İndeksleri (.srt)](TR.AmberDB_Veritabani_Sistemi.html#64-sıralama-indeksleri-srt)

---

### 4.2 Türkçe ve Çok Dilli Karakter Sıralaması (Collation)

* **SQL:**
  ```sql
  SELECT * FROM members
  ORDER BY name COLLATE utf8mb4_turkish_ci;
  ```

* **AmberDB:**
  ```perl
  # Nesne başlatılırken belirtilen dil motoru otomatik çalışır:
  # cfg => { language => 'tr' }
  my ($total, @members) = $adb->read_all("members", { offset => 0, limit => 50, sort => { blk => 1 } });
  ```

* **Açıklama:** AmberDB, harici veritabanı collation paketlerine veya işletim sistemi yereline bağımlı olmadan kendi bünyesindeki `AmberDB::Locale` motorunu çalıştırır. Türkçe `Ç, Ğ, I, İ, Ö, Ş, Ü` harfleri ASCII karmaşasına uğramadan evrensel standartta doğru sırada dizilir.
* **Referans:** [AmberDB::Locale Rehberi](TR.AmberDB-Locale_Kullanim_Rehberi.html)

---

## 5. İlişkiler ve JOIN Mantığı (En Büyük Mimari Fark)

Geleneksel ilişkisel SQL ile AmberDB arasındaki en büyük zihniyet ve performans farkı ilişkisel verilerin modellenmesindedir.

### 5.1 SQL Normalize Tablo + JOIN Modeli

SQL'de bir siparişin kalemlerini ve müşteri ilişkisini tutmak için en az 3 ayrı tablo ve bunları bağlayan yabancı anahtarlar (Foreign Keys) gereklidir:

```sql
-- 1. Siparişleri ve Kalemleri Bulmak için SQL JOIN:
SELECT o.id AS order_id, o.customer_name, oi.product_id, oi.quantity, p.name AS product_name
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE oi.product_id = 101;
```

**Maliyet:** 3 ayrı B-Tree indeks taraması, çoklu disk I/O, geçici tablo belleği ve CPU sorgu planlama yükü.

---

### 5.2 AmberDB İç İçe Belge + match_block Tersine İndeks Modeli

AmberDB'de sipariş kaydı, kalemlerini kendi içinde **doğal bir Perl iç içe dizi referansı (`ARRAY ref`)** olarak barındırır:

```perl
# 1. Sipariş Kaydının Yapısı (@order):
my @order = (
    0,                             # [0] Sipariş ID (Örn: 5001)
    "Ahmet Yılmaz",                # [1] Müşteri Adı
    "2026-09-06",                  # [2] Tarih
    [                              # [3] Kalemler (İç içe ARRAY): [ [ ÜrünID, Adet, Fiyat ], ... ]
        [ 101, 2, 149.99 ],
        [ 105, 1,  49.90 ],
    ],
    { status => "kargoda" }        # [4] Ek Bilgiler (HASH ref)
);

# Siparişi kaydet:
my $order_id = $adb->insert_id("orders", @order);
```

Şema dosyasında (`orders.table`) Blok 3 eşleştirme listesine eklenir:
```perl
{
    match_block => [ 3 ], # Blok 3 içindeki tüm alt dizi elemanlarını otomatik indeksle
}
```

#### "101 nolu ürünü içeren tüm siparişleri getir" Sorgusu:

* **AmberDB Kodu:**
  ```perl
  my @orders = $adb->field_fetch("orders", 3, 101);
  foreach my $ord (@orders) {
      print "Sipariş ID: $ord->[0], Müşteri: $ord->[1]\n";
  }
  ```

* **Neden JOIN Gerektirmez?**
  AmberDB'de her blok için ayrı dosya açılmaz; tüm alan eşleşmeleri tek bir `<tablo>.fld` (burada `orders.fld`) dosyasında toplanır. Kayıt eklenirken iç içe dizideki `101` ve `105` ID'leri otomatik olarak `3:101` ve `3:105` anahtarlarıyla `orders.fld` tersine indeksine yazılır. `field_fetch("orders", 3, 101)` çağrıldığında motor, `orders.fld` dosyasından `"3:101"` anahtarına **tek bir doğrudan hash aramasıyla** bu ürünü içeren tüm sipariş ID'lerini ($O(1)$) anında döner.
* **Sonuç:** JOIN overhead'i sıfırdır; ekstra `order_items` tablosu gerekmez; veri bütünlüğü bozulmaz.
* **Referans:** [Tutorial Bölüm 9: match_block](TR.AmberDB_Veritabani_Sistemi.html#9-şema-yapılandırması-table-ve-kod-içi--in-memory) ve [Tutorial Bölüm 24.2: match_block İlişki Kurma](TR.AmberDB_Veritabani_Sistemi.html#242-birleşik-kayıtlarda-match_block-ile-düşük-io-ile-ilişki-kurma)

---

## 6. Gruplama ve Filtre Sayaçları (GROUP BY vs. Facet)

E-ticaret ve arama sayfalarında kullanıcıların sol tarafta gördüğü *"Sony (12), Apple (8), Samsung (5)"* gibi kategori filtre sayaçları SQL'de `GROUP BY` ile hesaplanır.

* **SQL:**
  ```sql
  SELECT brand, COUNT(*) AS count
  FROM products
  WHERE category_id = 5
  GROUP BY brand;
  ```

* **AmberDB (`field_fltkeys` Facet Motoru):**
  ```perl
  # 1. Facet Sayaçlarını Alma (Sadece { Değer => Adet } haritası döner, kayıt getirmez):
  # Tablo şemasında facet_block => [ 3 ] tanımlandığında:
  my $facets = $adb->field_fltkeys("products", {
      target_block => 3,          # Sayımı çıkarılacak hedef özellik bloku (Marka)
      filter       => { 4 => 5 }, # Filtrelenen blok: Blok 4 (Kategori ID) = 5
  });
  # $facets döner: { "Sony" => 12, "Apple" => 8, "Samsung" => 5 }

  # 2. Seçilen Facet Değerine Göre Kayıtları Çekme (read_list):
  # Kullanıcı "Sony" filtresine tıkladığında kayıtları getirmek için:
  my $res = $adb->field_filter("products", {
      filter => { 4 => 5, 3 => "Sony" }
  });
  my @records = $adb->read_list("products", $res->{ids});
  # (Veya tekil blok için doğrudan: my @prods = $adb->field_fetch("products", 3, "Sony");)
  ```

* **Açıklama:** `field_fltkeys` doğrudan kayıtları değil, yalnızca belirtilen filtre altındaki alan dağılım sayaçlarını döner. SQL büyük tablolarda `GROUP BY` yaparken geçici tablolar oluşturup yüksek CPU harcarken; AmberDB'nin Facet motoru `.fac` ikili indekslerini kullanarak sayaçları mikro-saniye seviyesinde üretir. Kayıtların kendisi ise filtrelenen ID'ler üzerinden `read_list` ile diskten tek seferde çekilir.
* **Referans:** [Tutorial Bölüm 16: Facet Sistemi](TR.AmberDB_Veritabani_Sistemi.html#16-filtre-ve-kategori-menüsü-facet-sistemi)

---

## 7. İşlem Güvenliği ve ACID (Transactions: COMMIT & ROLLBACK)

AmberDB, çökmelere karşı korumalı geri alma günlüğü (undo-log) ve Strict 2PL (Two-Phase Locking) transaction desteğine sahiptir.

* **SQL:**
  ```sql
  START TRANSACTION;
  UPDATE accounts SET balance = balance - 100 WHERE id = 1;
  UPDATE accounts SET balance = balance + 100 WHERE id = 2;
  -- Hata varsa:
  -- ROLLBACK;
  -- Başarılıysa:
  COMMIT;
  ```

* **AmberDB:**
  ```perl
  # 1. İşlemi Başlat
  $adb->transact_start();

  my @sender   = $adb->read_id("accounts", 1);
  my @receiver = $adb->read_id("accounts", 2);

  if ($sender[1] >= 100) { # Bakiye kontrolü
      $sender[1]   -= 100;
      $receiver[1] += 100;
      
      $adb->update_id("accounts", @sender);
      $adb->update_id("accounts", @receiver);
  } else {
      # Hata bildir (transact_end'in otomatik rollback yapmasını sağlar)
      $adb->transact_error("accounts", "Yetersiz bakiye");
  }

  # 2. İşlemi Tamamla (Hata varsa otomatik ROLLBACK, yoksa COMMIT)
  my $txn = $adb->transact_end();
  if ($txn->{status} eq "commit") {
      print "Transfer başarılı!\n";
  } else {
      print "İşlem iptal edildi ve değişiklikler geri alındı!\n";
  }
  ```

* **Açıklama:** `$adb->transact_start()` ve `$adb->transact_end()` arasında yapılan tüm `insert`, `modify`, `delete` işlemleri loglanır. Hata olduğunda motor diski işlem öncesi durumuna kusursuz şekilde geri döndürür. Beklenmeyen elektrik kesintilerinde `transact_recover()` yarım kalan işlemleri otomatik temizler.
* **Referans:** [Tutorial Bölüm 7: İşlem Güvenliği, ACID Garantileri ve Kurtarma](TR.AmberDB_Veritabani_Sistemi.html#7-işlem-güvenliği-acid-garantileri-ve-kurtarma-transactions)

---

## 8. Veri Tanımlama (DDL: CREATE TABLE vs. AmberDB Şeması)

* **SQL:** Katı şema tanımları, veri tipi kısıtlamaları ve migrasyon betikleri (`ALTER TABLE`) zorunludur:
  ```sql
  CREATE TABLE products (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(255) NOT NULL,
      price DECIMAL(10,2) NOT NULL,
      brand VARCHAR(100),
      category_id INT,
      INDEX idx_cat (category_id),
      FULLTEXT idx_search (name)
  );
  ```

* **AmberDB:**
  - **Şemasız Çalışabilme:** Küçük projelerde şema dosyası oluşturmadan doğrudan `$adb->insert_id("products", ...)` çağrısıyla tablo oluşturulabilir.
  - **Şema Tanımı (`products.table` veya `table_attr`):** Büyük ölçekli ve indeksli tablolar için blokların üstleneceği roller tek bir Hash yapısında tanımlanır:
  ```perl
  $adb->table_attr("products", {
      match_block  => [ 4 ],       # Kategori ID eşleşmesi (.fld)
      search_block => [ 1 ],       # Ürün adı tam metin araması (.src)
      sort_block   => [ 2 ],       # Fiyat sıralaması (.srt)
      facet_block  => [ 3, 4 ],    # Marka ve kategori filtre sayaçları (.fac)
      slug_block   => [ 1 ],       # Başlıktan otomatik SEO URL üretimi (.slg)
      keep_deleted => 1,           # Silinenleri .del dosyasında sakla (Soft-delete)
      log_owner    => 1,           # Hangi kullanıcı ne zaman değiştirdi kaydet (.aut)
  });
  ```

* **Açıklama:** AmberDB şeması sütun tiplerini zorlamaz (JSON / NoSQL esnekliği sağlar). Şema yalnızca motorun hangi bloklar için hangi tersine indeksleri (`.fld`, `.src`, `.fac`, `.srt`) otomatik inşa edeceğini belirler.
* **Referans:** [Tutorial Bölüm 9: Şema Yapılandırması](TR.AmberDB_Veritabani_Sistemi.html#9-şema-yapılandırması-table-ve-kod-içi--in-memory)

---

## 9. SQL'de Harici Kod Gerektiren Yerleşik AmberDB Artıları

SQL veritabanı kullanan projelerde geliştiricilerin harici kütüphaneler, trigger'lar, ayrı önbellek sunucuları veya Cron betikleriyle çözdüğü birçok operasyon AmberDB'de çekirdek motora dahildir:

| Özellik | Geleneksel SQL Dünyasında Çözüm | AmberDB'deki Yerleşik Çözüm |
|---|---|---|
| **Otomatik SEO URL Slug** | Uygulama kodu, harici slugify kütüphaneleri, çakışma kontrolü için veritabanı sorguları. | `slug_block => [1]` tanımlandığında motor başlık değiştiğinde `/urun/sony-wh-1000xm5` URL'ini otomatik üretir ve çakışmaları çözer (`get_slug`). |
| **Kullanıcı İşlem Denetimi (Audit Log)** | Ekstra audit tablosu, trigger'lar veya ORM middleware kodları. | `log_owner => 1` tanımlandığında her ekleme/güncelleme `.aut` dosyasına işlenir. `$adb->auth_view("tablo", $id)` ile HTML raporu alınır. |
| **Yüksek Hızlı Bellek İçi Önbellek ve Geçici Veri (RAM-Disk)** | Disk I/O darboğazını aşmak veya geçici oturum/sepetleri tutmak için harici bir önbellek sunucusu (`Redis` veya `Memcached`) kurup yönetmek, ağ gecikmesi (TCP) ve senkronizasyon kodlarıyla uğraşmak. | Ayrı bir sunucu veya servis kurmadan; süreç içi L1 bellek nesne önbelleği (`set_cache`, `get_cache`) ve işletim sistemi paylaşımlı belleği (RAM-Disk) üzerinde doğrudan çalışan yerel tablo motoru (`use_ramdisk`, `ramdisk_*`). Sıfır ağ gecikmesi, sıfır harici servis bağımlılığı. |
| **Güvenli Silme (Soft-Delete)** | Tabloya `is_deleted` sütunu eklemek ve yazılan her `SELECT` sorgusuna `WHERE is_deleted = 0` eklemeyi unutmamak. | `keep_deleted => 1` ile silinen kayıtlar ana tablodan kaldırılıp `.del` arşivine taşınır. Veri sızıntısı riski olmadan güvenle saklanır. |

* **Referans:** [Tutorial Bölüm 12: URL Slug Yönetimi](TR.AmberDB_Veritabani_Sistemi.html#12-otomatik-slug-kaydı-url-slug-yönetimi) · [Bölüm 13: RAM Önbellek](TR.AmberDB_Veritabani_Sistemi.html#13-birleşik-paylaşımlı-ram-önbellek-db--inx-ve-buffer) · [Bölüm 17: Audit Log](TR.AmberDB_Veritabani_Sistemi.html#17-kullanıcı-denetim-izi-audit-ve-yedekleme)

---

## 10. Hızlı Referans ve Kopya Kağıdı (Cheat Sheet)

Günlük kod yazarken başvurabileceğiniz hızlı dönüşüm tablosu:

| SQL İşlemi | AmberDB Metodu | AmberDB Örnek Kullanımı |
|---|---|---|
| `INSERT INTO t VALUES (...)` | `insert_id` | `$id = $adb->insert_id("t", 0, @alanlar);` |
| `INSERT INTO t VALUES (...), (...)` | `insert_list` | `$adb->insert_list("t", @records);` |
| `SELECT * FROM t WHERE id = ?` | `read_id` | `my @rec = $adb->read_id("t", $id);` |
| `SELECT * FROM t WHERE id IN (...)` | `read_list` | `my @recs = $adb->read_list("t", $res->{ids});` |
| `SELECT * FROM t LIMIT 20 OFFSET 0` | `read_all` | `my ($tot, @recs) = $adb->read_all("t", { offset => 0, limit => 20 });` |
| `UPDATE t SET ... WHERE id = ?` | `update_id` | `$adb->update_id("t", @guncel_kayit);` |
| `DELETE FROM t WHERE id = ?` | `delete_id` | `$adb->delete_id("t", $id);` |
| `DELETE FROM t WHERE id IN (...)` | `delete_list` | `$adb->delete_list("t", @id_list);` |
| `SELECT COUNT(*) FROM t` | `table_count` | `my $count = $adb->table_count("t");` |
| `SELECT * FROM t WHERE col = val` | `field_fetch` | `my @recs = $adb->field_fetch("t", $blk, $val);` |
| `SELECT * FROM t WHERE col LIKE '%s%'` | `search_table` | `my @recs = $adb->search_table("t", "kelime");` |
| `SELECT * FROM t WHERE a=? AND b=?` | `field_filter` | `$adb->field_filter("t", { filter => { 1 => $a, 2 => $b } });` |
| `SELECT col, COUNT(*) GROUP BY col` | `field_fltkeys`| `$adb->field_fltkeys("t", { target_block => $blk, filter => { $fld => $val } });` |
| `START TRANSACTION` / `COMMIT` | `transact_*` | `$adb->transact_start(); ... $adb->transact_end();` |
| `CREATE TABLE` / `CREATE INDEX` | `table_attr` | `$adb->table_attr("t", { match_block => [ 1, 2 ] });` |

* **Tüm Metotların Tam Listesi İçin:** [Tutorial Bölüm 23: Metod Hızlı Referans Tablosu](TR.AmberDB_Veritabani_Sistemi.html#23-metod-hızlı-referans-tablosu)

---

## 11. Kavramlar Sözlüğü (Terminology Glossary)

SQL dünyasındaki kavramların AmberDB mimarisindeki teknik karşılıkları:

| SQL / RDBMS Kavramı | AmberDB Karşılığı | Açıklama ve Mimari Anlamı |
|---|---|---|
| **Database Server / Instance** | `AmberDB` Nesnesi (`$adb`) | Harici bir daemon veya TCP portu yoktur; uygulama prosesinin içinde gömülü (embedded) bir nesne olarak yaşar. |
| **Table (Tablo)** | Tablo (`.db`) | Verilerin saklandığı Berkeley DB (`DB_File`) anahtar-değer dosyası. |
| **Row / Record (Satır / Kayıt)** | Dizi Kaydı (`@record`) | Sabit kolonlu C-struct benzeri satırlar yerine doğal bir Perl listesidir. Skalar, `ARRAY` veya `HASH` referansı taşıyabilir. |
| **Column / Field (Sütun / Kolon)** | Blok / Alan İndisi (`$record[$i]`) | Kolon adları yerine pozisyonel indisler (`1`, `2`, `3`...) kullanılır. |
| **Primary Key (PK, AUTO_INCREMENT)** | 0. İndis (`$record[0]`) | Her kaydın ilk elemanıdır. Motor tarafından sıralı veya benzersiz sayısal ID atanır. |
| **Foreign Key & JOINs** | İç İçe Dizi (`ARRAY ref`) & `match_block` | Normalize edilmiş çoklu tablolar yerine döküman içine gömülü listeler tutulur; `.fld` tersine indeksleriyle sıfır JOIN maliyetiyle sorgulanır. |
| **Index (`CREATE INDEX`)** | Şema İndeks Blokları | Tablo şemasında tanımlanan tersine indeksler: Eşleştirme (`.fld`), Metin arama (`.src`), Filtre/Facet (`.fac`), Sıralama (`.srt` / `.inx`). |
| **Query Planner / Optimizer** | Doğrudan İndeks Anahtarı Erişimi | SQL sözdizimi ayrıştırma, AST ağacı oluşturma ve maliyet hesaplama yükü yoktur; binary RID blokları doğrudan diskten okunur. |
| **Collation / Charset** | `AmberDB::Locale` | Harici işletim sistemi veya veritabanı ayarına ihtiyaç duymaksızın Türkçeye ve 10+ dile tam uyumlu yerel alfabe motoru. |
| **Audit Table & Triggers** | `log_owner` & `.aut` Dosyası | Kaydı kimin ne zaman eklediğini veya güncellediğini takip eden yerleşik denetim izi mekanizması. |
| **Soft Delete (`is_deleted`)** | `keep_deleted` & `.del` Dosyası | Silinen kayıtların ana tablodan çıkarılıp kurtarılabilir ayrı bir dosyaya taşındığı yerleşik çöp kutusu. |
| **Harici Önbellek / Oturum Sunucusu (Redis / Memcached Alternatifi)** | `set_cache` / `get_cache` & RAM-Disk (`use_ramdisk`) | Harici bir daemon/sunucu kurmaksızın; uygulama düzeyinde L1 süreç içi nesne önbelleği ve kritik/geçici tablolar için işletim sistemi paylaşımlı belleğinde (RAM-Disk) dosya tabanlı, TTL destekli yerel hızlandırma. |
