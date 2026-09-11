[Ana Sayfa](index_tr.html) &nbsp;•&nbsp; [Hakkında](TR.AmberDB-Hakkinda.html) &nbsp;•&nbsp; [Hızlı Başlangıç](index_tr.html#hızlı-başlangıç) &nbsp;•&nbsp; [Tutorial](TR.AmberDB_Veritabani_Sistemi.html) &nbsp;•&nbsp; [Benchmark](TR.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](TR.AmberDB-Locale_Kullanim_Rehberi.html) &nbsp;•&nbsp; [SQL Rehberi](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [English](EN.AmberDB_User-Guide.html)

---

# Geliştirici Kılavuzu ve Dokümantasyon

> **Mimari:** AmberDB v5 · **İlk Tasarım:** 2005 · **Son Güncelleme:** 2026  
> **Namespace:** `AmberDB`  
> **Modüler Çekirdek:** `AmberDB::Base::*` (`Encoder`, `Schema`, `Ramdisk`, `Cache`, `Index`, `Facet`, `Junk`, `Transact`)  
> **Bağımsız Bileşenler:** `AmberDB::Date`, `AmberDB::Locale`, `AmberDB::Tools`, `AmberDB::Array`

---

## İçindekiler

1. [AmberDB Nedir?](#1-amberdb-nedir)
2. [Hızlı Başlangıç](#2-hızlı-başlangıç)
3. [CRUD İşlemleri (Temel Veri Yönetimi)](#3-crud-işlemleri-temel-veri-yönetimi)
4. [Okuma, Filtreleme ve Sıralama](#4-okuma-filtreleme-ve-sıralama)
5. [Basit Mod ve İndekssiz Doğrudan Erişim (Simple Mode)](#5-basit-mod-ve-indekssiz-doğrudan-erişim-simple-mode)
6. [İndeksleme ve Arama Mekanizması](#6-indeksleme-ve-arama-mekanizması)
7. [İşlem Güvenliği, ACID Garantileri ve Kurtarma (Transactions)](#7-işlem-güvenliği-acid-garantileri-ve-kurtarma-transactions)
8. [Yüksek Başarımlı Toplu (Batch) İşlemler (Batch ETL & Ingestion)](#8-yüksek-başarımlı-toplu-batch-işlemler-batch-etl--ingestion)
9. [Şema Yapılandırması (.table ve Kod İçi / In-Memory)](#9-şema-yapılandırması-table-ve-kod-içi--in-memory)
10. [Veritabanı Grup Yapısı (.dbase)](#10-veritabanı-grup-yapısı-dbase)
11. [Akıllı Sıcak / Soğuk İndeksleme (Junk Sistemi)](#11-akıllı-sıcak--soğuk-indeksleme-junk-sistemi)
12. [Otomatik Slug Kaydı (URL Slug) Yönetimi](#12-otomatik-slug-kaydı-url-slug-yönetimi)
13. [Şeffaf Fiziksel RAM-Disk Hızlandırması ve Bellek İçi Depolama](#13-şeffaf-fiziksel-ram-disk-hızlandırması-ve-bellek-içi-depolama)
14. [Yapılandırma ve Deterministik Bayrak Yönetimi (`config`)](#14-yapılandırma-ve-deterministik-bayrak-yönetimi-config)
15. [Veri Yapıları, Düşük Seviyeli Tablo ve Akış İşlemleri](#15-veri-yapıları-düşük-seviyeli-tablo-ve-akış-işlemleri)
16. [Filtre ve Kategori Menüsü (Facet Sistemi)](#16-filtre-ve-kategori-menüsü-facet-sistemi)
17. [Kullanıcı Denetim İzi (Audit) ve Yedekleme](#17-kullanıcı-denetim-izi-audit-ve-yedekleme)
18. [Bakım ve Onarım Araçları (AmberDB::Tools)](#18-bakım-ve-onarım-araçları-amberdbtools)
19. [Dosya Uzantıları Haritası](#19-dosya-uzantıları-haritası)
20. [Dizin Yapısı](#20-dizin-yapısı)
21. [Geliştirici Tavsiyeleri ve En İyi Pratikler](#21-geliştirici-tavsiyeleri-ve-en-iyi-pratikler)
22. [Kapsamlı Uygulama Örneği (Sipariş & Stok Senaryosu)](#22-kapsamlı-uygulama-örneği-sipariş--stok-senaryosu)
23. [Metod Hızlı Referans Tablosu](#23-metod-hızlı-referans-tablosu)
24. [AmberDB Neden Kullanılmalıdır? (SQL ve SQLite ile Karşılaştırma)](#24-amberdb-neden-kullanılmalıdır-sql-ve-sqlite-ile-karşılaştırma)
25. [Sınırlar ve Çekişmeli Konular (Fiziksel Kısıtlar vs. Bilinçli Mimari Tercihler)](#25-sınırlar-ve-çekişmeli-konular-fiziksel-kısıtlar-vs-bilinçli-mimari-tercihler)

---

## 1. AmberDB Nedir?

`AmberDB`, Perl için geliştirilmiş; **Berkeley DB (`DB_File`) üzerinde çalışan, şema güdümlü (schema-driven), önceden hesaplanmış ters indekslemeye (precomputed inverted indexing), ACID uyumlu işlem (transaction) motoruna ve Strict 2PL kilit desteğine sahip** yüksek başarımlı bir NoSQL veritabanı motorudur.

Geliştirici açısından AmberDB, harici bir veritabanı sunucusu kurulumu ve bakımı gerektirmeyen; tek bir satır CRUD çağrısıyla tüm ilişkili arama, eşleştirme, facet filtreleme, sıralama ve URL slug eşleşmelerini senkronize eden bütünleşik bir veri katmanıdır.

### Dahili Mimari

AmberDB, harici üçüncü parti kütüphanelere bağımlı olmaksızın kendi içinde modüler bir yapı sunar:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                              AmberDB                                       │
├────────────────────────────────────────────────────────────────────────────┤
│  AmberDB::Base     → Şema yükleme, dosya yolları, veri serileştirme        │
│  AmberDB::Index    → Binary indeksler (.inx, .fld, .src, .fac, .srt)       │
│  AmberDB::Transact → Undo-log transaction, rollback & crash recovery       │
│  AmberDB::Ramdisk  → RAM-Disk (tmpfs/APFS/ImDisk) Paylaşımlı Bellek        │
│  AmberDB::Array    → Yüksek hızlı dizi yardımcıları (nodup, crop)          │
│  Amber::Util::String   → Metin işleme, HTML temizleme ve dönüştürme            │
│  AmberDB::Date     → Tarih hesaplamaları ve format dönüşümleri             │
│  AmberDB::Locale   → Dahili çok dilli sıralama ve arama motoru             │
├────────────────────────────────────────────────────────────────────────────┤
│  AmberDB::Tools    → Bağımsız bakım, reindex, vacuum ve onarım             │
└────────────────────────────────────────────────────────────────────────────┘
```

> **Not:** Dil duyarlı arama ve alfabetik sıralama yetenekleri motorun kendi bünyesindeki `AmberDB::Locale` modülü ile sağlanır; harici bir servis veya kütüphane gerektirmez.

---

## 2. Hızlı Başlangıç

### 2.1 Nesne Oluşturma

```perl
use AmberDB;

my $adb = AmberDB->new(
    cfg  => { 
        language => "tr",          # Dahili Locale motoru dili ("tr", "en", "de" vb.)
    },
    path => { 
        dbase_dir => "./dbstore",  # Veritabanı ana dizini
    },
);
```

> [!TIP]
> **Değişken Adlandırma Standardı (`$adb`):**
> AmberDB belgelerinde ve örnek kodlarında, Perl ekosisteminin geleneksel `$dbh` (Database Handle) standardına benzer şekilde, **AmberDB nesnesini temsil etmek üzere `$adb` (AmberDB Handle)** değişkeni tercih edilmiştir. Bu zorunlu olmamakla birlikte, SQL veritabanlarıyla (`$dbh`) birlikte çalışan projelerde isim çakışmalarını önlemek ve kod okunabilirliğini artırmak için `$adb` kullanımı önerilir.
>
> **Veritabanı Dizin Adlandırması (`dbstore`):**
> Benzer şekilde, döküman ve örnekler genelinde veritabanı kök klasörü için **`dbstore`** adı standart bir temsil olarak kullanılmıştır. Bu isim katı bir kalıp değildir; projelerinizde dilediğiniz bir klasör yolunu (örneğin `data`, `db`, `storage`, `/var/data/projem` vb.) belirleyebilirsiniz. Ancak platformlar arası dosya sistemi uyumluluğu açısından dizin yolunun **yalnızca küçük harfli ASCII karakterlerden** (özel/Türkçe karakter ve boşluk içermeyen) oluşması zorunludur.

### 2.2 Dizin Konfigürasyonu

AmberDB başlatıldığında kök dizin altında gerekli alt klasörleri otomatik olarak yapılandırır. Nesneyi oluşturduktan sonra veritabanı dizinini atamak veya değiştirmek isterseniz `set_datadir()` metodunu kullanabilirsiniz:

```perl
# Farklı bir veri dizini belirleme
$adb->set_datadir("/var/data/eticaretim/other/dir");
```

> [!WARNING]
> **Güvenlik Uyarısı (Web Erişimi Engeli):**
> AmberDB nesnesini oluştururken atadığınız kök veri dizininin (`dbase_dir`), web sunucusunun doğrudan internet üzerinden erişilebilen belge kök dizini (`public_html`, `htdocs`, `www` vb.) **dışında** olduğuna veya web sunucusu yapılandırmasıyla (örn: `.htaccess`, Nginx bloklama kuralları) dışarıdan doğrudan dosya indirmeye ve HTTP isteklerine kesinlikle kapatılmış olduğuna muhakkak dikkat edin.

### 2.3 Bir AmberDB Kaydının Yapısı ve Anatomisi

AmberDB'de her bir kayıt (döküman), doğal bir Perl dizi/liste yapısı (`@record`) olarak temsil edilir. SQL tablolarındaki katı sütun sınırlarının aksine, AmberDB kayıtları hafif, esnek ve nesne odaklı bir yapıya sahiptir:

* **0. İndis (Kayıt Anahtarı / ID):** Listenin ilk elemanı (`$record[0]`) kaydın benzersiz birincil anahtarıdır (Primary Key ID).
  - Kayıt eklerken `insert_id` kullanılır. `@record` dizisinin ilk elemanına (`$record[0]`) otomatik artan ID için `0` veya `undef` atanır ve dizi doğrudan `$adb->insert_id("tablo", @record)` şeklinde gönderilir (araya fazladan bir ID/`undef` parametresi eklenmez).
  - Kayıt okunduğunda (`read_id` veya `read_all`), dönen dizinin 0. indisi doğrudan veritabanında saklanan **kayıt ID'sini** içerir.
* **1. İndis ve Sonrası (Veri Blokları / Değerler):** 1. indisten itibaren gelen tüm elemanlar tablonun veri alanlarını (bloklarını) oluşturur.
* **Zengin Veri Tipleri Desteği:** Kaydın her bir bloku sadece düz metin veya sayı (**SCALAR**) olmak zorunda değildir; iç içe listeler (**ARRAY reference**) veya sözlükler (**HASH reference**) de doğrudan saklanabilir.

> [!TIP]
> **Temel AmberDB Metotları:**  
> Günlük uygulama geliştirmede en sık kullanılan temel çekirdek işlemler şunlardır:
> * **Yazma & Değiştirme:** `insert_id`, `update_id`, `delete_id`
> * **Okuma & Listeleme:** `read_id`, `read_all`, `read_list`
> * **Filtreleme & Arama:** `field_fetch`, `search_table`

```perl
# =========================================================================
# 1. Kayıt Oluşturma ve Ekleme (@record)
# =========================================================================
# AmberDB'de önerilen standart pratik, kayıt dizisinin 0. indisine ID değerini
# (yeni kayıtlarda 0 veya undef) atayarak diziyi bütüncül olarak yönetmektir:
my @record = (
    0,                                  # [0] İndis: Kayıt ID (0 veya undef: Otomatik ID)
    "Ahmet Yılmaz",                     # [1] İndis: Ad Soyad (Skalar Metin)
    "ahmet@ornek.com",                  # [2] İndis: E-Posta (Skalar Metin)
    "5,12",                             # [3] İndis: Kategori ID'leri (İlişkisel liste)
    1249.90,                            # [4] İndis: Bakiye / Tutar (Sayısal)
    [ "Yetki_A", "Yetki_B" ],           # [5] İndis: İzinler (İç içe ARRAY referansı)
    { status => "aktif", login_count => 12 }, # [6] İndis: Ek meta veriler (İç içe HASH referansı)
);

# Ekleme: Üretilen yeni ID'yi hem $id değişkenine hem de diziye ($record[0]) atama:
my $id = $record[0] = $adb->insert_id("member_user", @record);
print "Kayıt başarıyla eklendi, Üretilen ID: $id\n";

# =========================================================================
# 2. Kayıt Okuma, Güncelleme ve Silme (Standart CRUD Yaşam Döngüsü)
# =========================================================================
# Okuma: read_id ile dönen dizinin 0. indisi doğrudan kayıt ID'sidir:
my @gelen_kayit = $adb->read_id("member_user", $id);

my $kayit_id = $gelen_kayit[0]; # $id ile aynı (Örn: 1001)
my $ad_soyad = $gelen_kayit[1]; # "Ahmet Yılmaz"
my $email    = $gelen_kayit[2]; # "ahmet@ornek.com"
my $izinler  = $gelen_kayit[5]; # [ "Yetki_A", "Yetki_B" ] (ARRAY-ref)
my $meta     = $gelen_kayit[6]; # { status => "aktif", ... } (HASH-ref)

# Güncelleme: Alanları değiştirip doğrudan @gelen_kayit dizisini geçirme:
$gelen_kayit[4] = 1499.90; # Bakiyeyi güncelle
$adb->update_id("member_user", @gelen_kayit);

# Silme: 0. indisteki ID üzerinden kaydı silme:
$adb->delete_id("member_user", $gelen_kayit[0]);
```

---

## 3. CRUD İşlemleri (Temel Veri Yönetimi)

AmberDB'de temel veri ekleme, güncelleme, silme ve okuma işlemleri doğrudan veritabanı tablosu üzerinde yürütülür.

Tablolar için önceden bir `.table` şema dosyası oluşturmak **zorunlu değildir**; şemasız tablolarda da veri depolama ve ID bazlı doğrudan okuma tam verimle çalışır. Ancak **şemada indeksleme kuralları tanımlandıysa** (`record_index`, `match_block`, `search_block`, `facet_block`, `sort_block`, `slug_block`):
1. Yapılan her `insert_id`, `update_id` veya `delete_id` çağrısı, şemada belirtilen tüm arama, eşleştirme ve sıralama indekslerini **arka planda otomatik ve senkronize olarak oluşturur ve günceller**.
2. Okuma, arama ve sorgulama metotları (`read_all`, `field_fetch`, `search_table`, `facet_menu` vb.) bu önceden hesaplanmış indeksleri **otomatik olarak kullanarak** disk taraması (full table scan) yapmadan doğrudan anahtar eşleşmesiyle çalışır.

### 3.1 Kayıt Ekleme - `insert_id`

AmberDB'de ilişkisel alanlar (`match_block` ve `rdbm` tanımlı alanlar) doğrudan metin (string) olarak değil, **bağlı tablolardaki kayıtların birincil anahtarları (ID)** olarak saklanır. 

Birden fazla kategoriye veya birden fazla yazara ait ürünler için ID değerleri virgülle ayrılmış bir liste (örn: `"5,12"` veya `"7,9"`) veya dizi referansı olarak verilir. AmberDB'nin `get_fieldlist` / `set_fieldlist` mekanizması bu değerleri otomatik olarak ayrıştırarak her bir ID'yi eşleştirme ve facet filtre indekslerine bağımsız birer kayıt olarak yazar.

```perl
# =========================================================================
# ADIM 1: İlişkili Ana Tabloların (Master Tables) Oluşturulması
# =========================================================================

# 1. Kategori Tablosu (catalog_category):
my $kat_bilgisayar = $adb->insert_id("catalog_category", 0, "Bilgisayar & Bilişim", 1); # ID: 5
my $kat_ses        = $adb->insert_id("catalog_category", 0, "Kulaklık & Ses", 1);        # ID: 12

# 2. Marka / Üretici Tablosu (catalog_brand):
my $marka_sony     = $adb->insert_id("catalog_brand", 0, "Sony", "Japonya");             # ID: 3
my $marka_apple    = $adb->insert_id("catalog_brand", 0, "Apple", "ABD");                # ID: 8

# 3. Yazar / Tasarımcı Tablosu (catalog_author):
my $yazar_1        = $adb->insert_id("catalog_author", 0, "Ahmet Yılmaz", "Akustik Müh.");# ID: 7
my $yazar_2        = $adb->insert_id("catalog_author", 0, "Mehmet Öz", "Tasarımcı");     # ID: 9

# =========================================================================
# ADIM 2: Ürün Kaydının (catalog_product) Eklenmesi
# =========================================================================
# DİKKAT: 
# - Blok 1 (Kategori), Blok 2 (Marka) ve Blok 3 (Yazar) alanlarına doğrudan 
#   metin yazılmaz; ilgili tablolardaki kayıt ID'leri verilir.
# - Çoklu kategori veya yazar için değerler virgülle ("5,12" veya "7,9") birleştirilir.
# - Standart pratik: [0] indisine 0 atanır ve dizi doğrudan insert_id'ye verilir.

my @urun_bilgileri = (
    0,                            # [0] Kayıt ID (0: Otomatik Artan ID)
    "5,12",                       # [1] Kategori ID'leri (Çoklu: 5 ve 12 nolu kategoriler)
    "3",                          # [2] Marka ID'si (3 = Sony)
    "7,9",                        # [3] Yazar / Katkıda Bulunan ID'leri (Çoklu: 7 ve 9 nolu yazarlar)
    "WH-1000XM5 Kablosuz Kulaklık",# [4] Ürün Adı
    "Aktif Gürültü Engelleme ANC",# [5] Kısa Açıklama
    "Tedarikçi Ltd.",             # [6] Tedarikçi
    "Sony WH-1000XM5 üstün ses...",# [7] Detaylı Açıklama
    "",                           # [8] Ek Özellikler
    "8690001234567",              # [9] Barkod
    "12499.90",                   # [10] Fiyat
    "1"                           # [11] Satış Durumu (1: Aktif)
);

# Otomatik ID ile ekleme (Üretilen ID hem değişkene hem @urun_bilgileri[0]'a atanır)
my $yeni_id = $urun_bilgileri[0] = $adb->insert_id("catalog_product", @urun_bilgileri);
print "Eklenen ürünün ID'si: $yeni_id\n";

# Belirli bir manuel ID vererek ekleme ([0] indisine doğrudan manuel ID yazılır)
$urun_bilgileri[0] = 5001;
$adb->insert_id("catalog_product", @urun_bilgileri);

# =========================================================================
# ADIM 3: Çoklu Değer Eşleştirmesi (field_fetch) Nasıl Çalışır?
# =========================================================================
# AmberDB'nin 'set_fieldlist' mekanizması virgülle ayrılmış "5,12" ve "7,9" değerlerini
# otomatik olarak ayrıştırır ve her bir ID'yi ilgili eşleştirme indekslerine bağımsız olarak yazar.
# Böylece aşağıdaki bağımsız sorguların her ikisi de ürünü tekil indeks aramasıyla doğrudan bulur:
my @kat12_urunleri  = $adb->field_fetch("catalog_product", 1, "12"); # 12 nolu kategorideki ürünler
my @yazar9_urunleri = $adb->field_fetch("catalog_product", 3, "9");  # 9 nolu yazarın ürünleri
```

### 3.2 Kayıt Güncelleme - `update_id`

AmberDB'de kayıt güncelleme işlemi, kaydın 0. indiste ID değerini barındıran bütüncül dizi yapısı (`@kayit` veya `@alanlar`) üzerinden tek ve standart bir biçimde yürütülür. `update_id`, dizinin ilk elemanını (`$kayit[0]`) otomatik olarak güncellenecek kaydın ID'si kabul eder:

```perl
# 1. Yöntem: read_id ile mevcut kaydı okuyup güncelleme
my @kayit = $adb->read_id("catalog_product", 5001);

$kayit[1]  = "5,12,18";   # Yeni kategori ID'si ekle (18: Aksesuar)
$kayit[10] = "13499.90";  # Fiyatı güncelle

my $ok = $adb->update_id("catalog_product", @kayit);

# 2. Yöntem: Form/API'den gelen verilerle güncelleme dizisi hazırlama
my $kayit_id = 5001; # Formdan, URL'den veya API'den gelen hedef kayıt ID'si

my @alanlar = (
    $kayit_id,                    # [0] Güncellenecek Kayıt ID (Değişken veya sabit)
    "5,12,18",                    # [1] Kategori ID'leri
    "3",                          # [2] Marka ID
    "7,9",                        # [3] Yazar ID'leri
    "WH-1000XM5 Kulaklık",        # [4] Ürün Adı
    "Yeni Açıklama",              # [5] Kısa Açıklama
    "Tedarikçi Ltd.",             # [6] Tedarikçi
    "Sony WH-1000XM5 detay...",   # [7] Detay
    "",                           # [8] Ek Özellikler
    "8690001234567",              # [9] Barkod
    "13499.90",                   # [10] Fiyat
    "1"                           # [11] Durum
);

my $ok2 = $adb->update_id("catalog_product", @alanlar);

if ($ok || $ok2) {
    print "Ürün ve tüm ilişkili indeksler başarıyla güncellendi.\n";
}
```

> [!WARNING]
> Kayıt dizisinde (`@kayit` / `@alanlar`) 0. indis zaten güncellenecek kaydın ID'sini barındırdığı için, tablo adından sonra fazladan bir ID parametresi **yazılmamalıdır** (yani `$adb->update_id("tablo", 5001, @alanlar)` şeklinde çağrılmamalıdır). Dizi doğrudan geçirilmelidir.

### 3.3 Kayıt Silme - `delete_id`

```perl
# Tekil silme
$adb->delete_id("catalog_product", 5001);
```

> **Soft-Delete Özelliği:** Eğer tablonun `.table` şemasında `keep_deleted => 1` tanımlıysa, silinen kayıt tamamen yok edilmez; `.del` dosyasına taşınır.

### 3.4 Kayıt Okuma - `read_id`

```perl
my @kayit = $adb->read_id("catalog_product", 5001);

if (@kayit) {
    my $id          = $kayit[0];  # Kayıt ID'si (Blok 0)
    my $kategoriler = $kayit[1];  # Blok 1 (Örn: "5,12")
    my $marka_id    = $kayit[2];  # Blok 2 (Örn: "3")
    my $yazarlar    = $kayit[3];  # Blok 3 (Örn: "7,9")
    my $ad          = $kayit[4];  # Blok 4
    my $fiyat       = $kayit[10]; # Blok 10
    print "Ürün: $ad, Fiyat: $fiyat TL, Kategori ID'leri: $kategoriler\n";
}
```

> [!TIP]
> **En İyi Pratik: Neden Şema (`.table`) Tanımlamalısınız?**  
> AmberDB şemasız da çalışabilse bile, özellikle **büyüyen tablolarda şema ve indeks kullanımı performansı korumak için şarttır**:
> 1. **Performans ve Hız:** Kayıt sayısı arttıkça `field_fetch` veya `search_table` gibi sorguların tam disk taraması (full table scan) yapmadan anında sonuç getirmesi için ilgili alanların şema üzerinden indekslenmesi şarttır.
> 2. **Blok Takibi ve Dokümantasyon:** Şema dosyaları (`blocks`), tablonun hangi indeksinde hangi alanın yer aldığını (örneğin 1. blok Kategori, 4. blok Ürün Adı, 10. blok Fiyat vb.) düzenli bir şekilde takip edebilmeniz için çok elverişlidir. Bu sayede kod yazarken hangi blokta ne olduğunu hatırlamak kolaylaşır ve karışıklıklar önlenir.
> 
> *(Detaylı şema parametreleri ve dosya yapısı için bkz: **[Bölüm 9: Şema Yapılandırması](#9-şema-yapılandırması-table-ve-kod-içi--in-memory)**)*

---

## 4. Okuma, Filtreleme ve Sıralama

AmberDB, kayıtları hızlıca listelemek, belirli bloklara göre filtrelemek ve sıralamak için zengin fonksiyonlar sunar.

> [!CRITICAL]
> **DÖNEN SONUÇ İMZASI (RETURN SIGNATURE) VE SAYFALAMA MANTIĞI:**
> `read_all`, `field_fetch` ve `search_table` metotlarında `$limit` parametresinin varlığı veya yokluğu dönen listenin yapısını belirler:
> 
> * **1. Limitsiz Çağrılar (`$limit == 0` veya hiç belirtilmemişse):**  
>   Metot tablodaki veya filtredeki **tüm kayıtları** okur. Dönen `@kayitlar` dizisinin eleman sayısı zaten `scalar @kayitlar` ile toplamı verdiği için liste başına ayrıca bir `$toplam` sayısı eklenmez. Doğrudan kayıt dizi referansları listesi döner:  
>   `my @kayitlar = $adb->read_all("catalog_product");`  
>   *(Burada her eleman bir kayıt dizi referansıdır: `$kayitlar[0]->[1]`)*
> 
> * **2. Sayfalı / Limitli Çağrılar (`$limit > 0` örn: `{ offset => 0, limit => 20 }`):**  
>   Burada amaç tablodaki binlerce kaydı belleğe yüklemek yerine yalnızca istenen sayfadaki (örn. 20 adet) kaydı okumaktır. Ancak web arayüzünde sayfalama menüsü (Örn: *"Toplam 1.250 üründen 1-20 arası gösteriliyor"*) oluşturabilmek için sorguya uyan genel toplam sayısına ihtiyaç duyulur. AmberDB tüm tabloyu diskten okumadan ikili indekslerden hesapladığı bu genel toplamı listenin **ilk elemanı olarak (`$toplam`)** döndürür:  
>   `my ($toplam, @sayfalanmis_kayitlar) = $adb->read_all("catalog_product", { offset => 0, limit => 20 });`
>
> **ÖLÜMCÜL HATA (FATAL CRASH) UYARISI:**  
> Eğer limit verdiğiniz halde sonucu tek bir diziye atarsanız (`my @kayitlar = $adb->read_all("catalog_product", { offset => 0, limit => 20 });`), dizinin ilk elemanı `$kayitlar[0]` kayıt referansı değil **toplam sayı tamsayısı** (örn. `1250`) olur. Bu durumda `$kayitlar[0]->[1]` veya `$kayitlar[0][1]` erişimi yapıldığında Perl **`Can't use string ("1250") as an ARRAY ref while "strict refs" in use`** şeklinde **fatal hata** vererek işlemi sonlandırır!  
> **Kural:** `$limit` değeri `> 0` olan tüm sorgularda dönen değeri mutlaka `my ($toplam, @kayitlar)` şeklinde karşılayınız.

### 4.1 `read_all` - Tablodaki Tüm Kayıtları Okuma ve Sayfalama

```perl
# 1. Tüm kayıtları varsayılan sırada (en son eklenen ilk - Azalan ID) getirme
my @tum_kayitlar = $adb->read_all("catalog_product");

# 2. Limitsiz Ek Seçenekler (Doğrudan @kayitlar / @idlar döner)
# 2.1 Yalnızca Kayıt ID'lerini alma (Bellek tasarruflu hızlı ID listesi - keys_only)
my @tum_idlar        = $adb->read_all("catalog_product", { keys_only => 1 });

# 2.2 Sadece Aktif veya Katmanlı (Junk) kayıtları getirme (jnktype => 'A' | 'B' | 'AB')
my @sadece_aktifler  = $adb->read_all("catalog_product", { jnktype => 'A' });
my @aktif_ve_arsiv   = $adb->read_all("catalog_product", { jnktype => 'AB' });

# 2.3 İndeks atlayarak doğrudan disk taraması (no_index)
my @ham_kayitlar     = $adb->read_all("catalog_product", { no_index => 1 });

# 2.4 Limitsiz sıralı getirme (sort => 10 [azalan] veya sort => -10 [artan])
my @tum_artan_fiyat  = $adb->read_all("catalog_product", { sort => -10 }); # Ucuzdan pahalıya
my @tum_azalan_fiyat = $adb->read_all("catalog_product", { sort => 10 });  # Pahalıdan ucuza
my @tum_alfabetik    = $adb->read_all("catalog_product", { sort => { blk => 4, reverse => 1 } });

# 3. Sayfalama ile Okuma (Limit > 0 olduğu için daima ($toplam, @sayfa) döner)
# 3.1 İlk 20 kayıt
my ($toplam, @sayfa1)     = $adb->read_all("catalog_product", { offset => 0, limit => 20 });
print "Toplam kayıt: $toplam, Bu sayfadaki kayıt: " . scalar(@sayfa1) . "\n";

# 3.2 Sayfalı ID listesi (keys_only)
my ($toplam, @sayfa_idlar)= $adb->read_all("catalog_product", { offset => 0, limit => 50, keys_only => 1 });

# 3.3 Sayfalı ve sıralı okuma
my ($toplam, @alfabetik)  = $adb->read_all("catalog_product", { offset => 0, limit => 20, sort => { blk => 4, reverse => 1 } });
my ($toplam, @pahali_ilk) = $adb->read_all("catalog_product", { offset => 0, limit => 10, sort => 10 });
my ($toplam, @ucuz_ilk)   = $adb->read_all("catalog_product", { offset => 0, limit => 10, sort => -10 });

# 3.4 Sayfalı ve katmanlı (Aktif + Arşiv) okuma
my ($toplam, @katmanli)   = $adb->read_all("catalog_product", { offset => 0, limit => 20, jnktype => 'AB' });
```

### 4.2 `field_fetch` - Blok Eşleştirme İndeksi (.fld) ve Çoklu Değer Araması

Şemada `match_block` olarak belirlenmiş alanlar, tersine eşleştirme indeksleri (`.fld`) üzerinden indeksli anahtar başına ortalama O(1) arama maliyetiyle getirilir (çoklu değer sorgularında maliyet sorgulanan anahtar sayısıyla orantılıdır). Kayıtta birden fazla değer virgülle saklansa dahi (`"5,12"` veya `"7,9"`), her değer bağımsız olarak indekslenir. İndeks dosyası (`.fld`) olmayan tablolarda sistem otomatik olarak `recs_scan` üzerinden tam tarama yaparak aynı sonuçları şeffafça üretir:

```perl
# 1. Kategori ID'si (Blok 1) "5" olan tüm ürünler
my @urunler = $adb->field_fetch("catalog_product", 1, "5");

# 2. Yazar / Katkıda Bulunan ID'si (Blok 3) "9" olan ürünler (Kayıtta "7,9" yazsa bile 9 ile eşleşir)
my @yazar_urunleri = $adb->field_fetch("catalog_product", 3, "9");

# 3. Kategori 5 içindeki ürünleri Fiyata (Blok 10) göre ucuzdan pahalıya sıralı ve sayfalı alma
my ($sayi, @sirali_urunler) = $adb->field_fetch(
    "catalog_product", 
    1, "5",
    { offset => 0, limit => 12, sort => { blk => 10, reverse => 1 } }
);

# 4. Çoklu değer eşleştirme (Dizi referansı, virgüllü string veya noktalı virgüllü)
my @coklu = $adb->field_fetch("catalog_product", 1, ["5", "8"]);
my @coklu = $adb->field_fetch("catalog_product", 1, "5, 8");

# 5. Sadece Kayıt ID'lerini alma (Bellek tasarruflu liste)
my ($toplam, @id_listesi) = $adb->field_fetch("catalog_product", 1, "5", { offset => 0, limit => 50, keys_only => 1 });
my @tum_idlar             = $adb->field_fetch("catalog_product", 1, "5", { keys_only => 1 });
```

> **Tekilleştirme (Deduplication) Garantisi:** Bir kayıt sorgulanan birden çok değerle aynı anda eşleşse dahi (`array_nodup` sayesinde) sonuç listesinde mükerrer olarak yer almaz, sadece bir kez döndürülür.

### 4.3 `field_filter` - Çok Bloklu Birleşik Filtreleme (AND / OR)

Kullanıcının birden fazla kriter seçtiği arama ve filtreleme sayfaları için idealdir:

```perl
my $sonuc = $adb->field_filter("catalog_product", {
    type   => "and",                        # Kriterlerin tümü sağlansın ("and" veya "or")
    filter => {
        1  => "5",                          # Kategori ID = 5
        2  => ["3", "8"],                   # Marka ID = 3 (Sony) veya 8 (Apple)
        3  => "7",                          # Yazar ID = 7
        11 => "1",                          # Satış Statüsü = 1 (Aktif)
    },
    sort   => { blk => 10, reverse => 1 },  # Fiyata göre artan sırala
    start  => 0,
    limit  => 20,
});

print "Filtreye uyan toplam kayıt: $sonuc->{count}\n";
foreach my $id (@{ $sonuc->{ids} }) {
    my @urun = $adb->read_id("catalog_product", $id);
    print "  -> $urun[4] - $urun[10] TL\n";
}
```

### 4.4 `search_table` - Tam Metin (Full-Text) ve Fonetik Kelime Araması

Şemada `search_block` tanımlı alanlarda `AmberDB::Locale` destekli akıllı kelime araması yapar. İndeksli tablolarda `.src` tersine indeks dosyalarından doğrudan token aramasıyla çalışırken, indekssiz tablolarda da aynı gelişmiş kelime normalizasyonuyla tam tarama yapar.

```perl
# 1. "kulaklık bluetooth" geçen ürünleri arama (Varsayılan: AND mantığı)
my @sonuclar = $adb->search_table("catalog_product", "kulaklık bluetooth");

# 2. Sayfalı, OR mantıklı ve fiyata göre sıralı arama
my ($adet, @sonuclar) = $adb->search_table(
    "catalog_product",
    "kablosuz kulaklık",
    {
        type   => "or",
        offset => 0,
        limit  => 20,
        sort   => { blk => 10, reverse => 1 },
    }
);

# 3. Arama sonucu sadece Kayıt ID'lerini alma; ilk 50 kayıt (keys_only)
my ($adet, @id_listesi) = $adb->search_table("catalog_product", "sony", { offset => 0, limit => 50, keys_only => 1 });
my @tum_idlar           = $adb->search_table("catalog_product", "sony", { keys_only => 1 });
```

#### AmberDB Arama Normalizasyonunun Öne Çıkan Güçlü Yönleri:
- **Apostrof / Kesme İşareti Yönetimi:** Kayıtta `"Türkiye'nin"` ifadesi geçtiğinde `"Türkiye"`, `"Türkiye'nin"` ve `"Türkiyenin"` aramalarının tümü doğru sonucu getirir. Kesme işaretinden sonraki ek (`"nin"`, `"da"`, `"in"`) stop word olarak yutulur ve tek başına arandığında hatalı eşleşme üretmez.
- **Fonetik Kelime Sonu Ötümsüzleşme (Sertleşme):** Türkçe ses olayları (`b$ => p`, `d$ => t`, `g$ => k`) gereği `"tevhid"` $\leftrightarrow$ `"tevhit"`, `"gazab"` $\leftrightarrow$ `"gazap"`, `"mehmed"` $\leftrightarrow$ `"mehmet"` aramaları birbirini eksiksiz eşleştirir.
- **İnceltme / Düzeltme İşaretleri:** `"kârın"` $\leftrightarrow$ `"karın"`, `"ÂLÎM"` $\leftrightarrow$ `"âlim"` / `"alim"` sorguları eşleşir.
- **Harf ve ASCII Toleransı:** `"ığdır"` $\leftrightarrow$ `"IĞDIR"` $\leftrightarrow$ `"igdir"`, `"ÇARŞI"` $\leftrightarrow$ `"çarşı"` $\leftrightarrow$ `"carsi"`, `"ÇÖPÇÜ"` $\leftrightarrow$ `"copcu"` tam uyumla aranabilir.

### 4.5 `read_list` - Belirli ID Listesini Toplu ve Sıralı Okuma

`read_list`, AmberDB'nin yüksek verimli toplu kayıt çözümleme çekirdeğidir. Hem motorun dahili sorgu işlemcisinde hem de geliştirici API'sinde kritik bir role sahiptir:

#### 1. AmberDB Dahili Çalışma Mantığı (Internal Pipeline):
AmberDB'deki tüm üst seviye liste ve arama metotları (`read_all`, `field_fetch`, `search_table`, `field_filter` vb.) iki aşamalı bir mimariyle çalışır:
1. **İndeks Filtreleme Aşaması:** İlgili fonksiyon önce ikili (`.inx`), eşleştirme (`.fld`), arama (`.src`) veya sıralama (`.srt`) ters indekslerinden yalnızca kayıt anahtarlarını (`@ids`) çeker; bu anahtarlar üzerinde kesişim (AND/OR), sıralama ve sayfalama dilimlemesi (`recs_cutting`) uygular.
2. **Toplu Veri Çözümleme Aşaması:** Filtrelenen ve nihai hale gelen kayıt ID listesi tek seferde **`read_list`** metoduna iletilir. `read_list`, veritabanı dosyasını tek oturumda açıp (veya RAM önbellekten) tüm kayıtları topluca çözer ve parametrede verilen ID sırasını **birebir koruyarak** kayıt referansları listesi (`@kayitlar`) olarak döner.

#### 2. Geliştirici API'sinde Kullanım ve İlişkisel Veri Birleştirme (JOIN Alternatifi):
Geliştiriciler, ilişkili tablolardan belirli ID kümelerine ait dökümanları tek seferde ve yüksek hızda çekmek için `read_list`'i doğrudan kullanabilir.

**Örnek Senaryo: Aktif Siparişi Olan Müşterilerin Bilgilerini Topluca Getirme**
```perl
# 1. Tüm aktif siparişleri oku
my @siparisler = $adb->read_all("order_active");

# 2. Her bir sipariş kaydının 2. indisi ($siparis[N]->[2]) müşteri ID'si olsun.
# map kullanarak tekil (unique) müşteri ID'lerini belirle:
my %musteri_idler = map { $_->[2] => 1 } @siparisler;

# 3. İlgili müşterilerin tam profil kayıtlarını tek adımda topluca oku:
my @musteri_bilgileri = $adb->read_list("customers", [ keys %musteri_idler ]);

foreach my $musteri (@musteri_bilgileri) {
    my $m_id     = $musteri->[0]; # Müşteri ID
    my $m_isim   = $musteri->[1]; # Ad Soyad
    my $m_eposta = $musteri->[2]; # E-Posta
    my $m_adres  = $musteri->[3]; # Teslimat Adresi (Kargo etiketi ve döküm için)
    print "Kargo Etiketi -> ID: $m_id | İsim: $m_isim | E-Posta: $m_eposta | Adres: $m_adres\n";
}
```

> [!TIP]
> `read_list` metoduna verilen ID listesi dizisi referans (`\@idler`) veya düz dizi olarak geçirilebilir. Metot, dönen kayıtların sırasını girdi dizisindeki ID dizilimiyle **tam olarak aynı sırada** tutmayı garanti eder.

### 4.6 Varlık Kontrol Fonksiyonları

Tüm kaydı belleğe çekmeden önce kaydın veya tablonun varlığını hızlıca doğrulamak için kullanılır:

```perl
# 1. Tekil Kayıt Varlık Kontrolü (O(1) doğrudan anahtar kontrolü)
if ($adb->exist_id("catalog_product", 5001)) {
    print "5001 ID'li ürün veritabanında mevcut.\n";
}

# 2. Çoklu Kayıt Varlık Kontrolü (Toplu doğrulama)
my $varlik_haritasi = $adb->exist_list("catalog_product", 5001, 5002, 9999);
# $varlik_haritasi döner: { 5001 => 1, 5002 => 1, 9999 => 0 }

# 3. Fiziksel Tablo / Dosya Varlık Kontrolü
if ($adb->exist_table("catalog_product")) {
    print "catalog_product.db dosyası diskte mevcut.\n";
}

# Belirli bir uzantının varlığını kontrol etme (örn: .slg slug dosyası)
if ($adb->exist_table("catalog_product", "slg")) {
    print "Slug indeks dosyası mevcut.\n";
}
```

### 4.7 Özel ve Konumsal Okumalar - `read_firstid`, `read_lastid`, `read_randid` ve `read_count`

```perl
# 1. Tablodaki İlk Kaydı Okuma (Sayısal en küçük ID)
my @ilk_urun = $adb->read_firstid("catalog_product");

# 2. Tablodaki En Son Eklenen Kaydı Okuma (Sayısal en büyük ID)
my @son_urun = $adb->read_lastid("catalog_product");

# 3. Rastgele Tekil Kayıt Okuma (Günün fırsatı / Rastgele vitrin önerisi)
my @rastgele_urun = $adb->read_randid("catalog_product");
print "Günün Fırsatı: $rastgele_urun[4] ($rastgele_urun[10] TL)\n";

# 4. Kaydın Görüntülenme / Tıklanma Sayısını Okuma (.cnt dosyası)
my $okunma_sayisi = $adb->read_count("catalog_product", 5001);
print "Ürün 5001 toplam $okunma_sayisi kez görüntülendi.\n";
```

---

## 5. Basit Mod ve İndekssiz Doğrudan Erişim (Simple Mode)

AmberDB'de **Basit Mod (`simple => 1`)**, tabloya ait hiçbir şema dosyasının (`.table` / `.dbase`) ve ikincil indeks dosyalarının (`.inx`, `.src`, `.fld`, `.fac`, `.srt`, `.slg`, `.aut`, `.del`) kullanılmadığı; veritabanının tamamen **şemasız (schemaless), hafif ve doğrudan düz dosya NoSQL anahtar-değer deposu** olarak çalıştığı işletim biçimidir.

Basit modda kayıtlar iç içe dizi ve sözlük referansları (`ARRAY`/`HASH`) dahil zengin veri yapılarını doğrudan saklayabilir. İkincil indeks bakım maliyeti ortadan kalkar; tekil anahtar okuma ve yazma işlemleri (`read_id`, `insert_id`) maksimum disk/bellek hızında $O(1)$ olarak gerçekleşir.

---

### 5.1 Basit Modu Başlatma ve Aktif Etme

Basit mod 4 farklı şekilde etkinleştirilebilir:

1. **`new()` Başlatıcısında Yapılandırma:**
   ```perl
   my $adb = AmberDB->new(
       path => { dbase_dir => "/var/data/sessions" },
       cfg  => { simple    => 1 },
   );
   ```

2. **`AmberDB::Tools` Üzerinden Kısayol Başlatıcı (`db_simple`):**
   ```perl
   use AmberDB::Tools;
   my $tools = AmberDB::Tools->new();
   my $adb   = $tools->db_simple("/var/data/sessions");
   ```

3. **Çalışma Zamanında Dinamik Geçiş (`config`):**
   ```perl
   $adb->config( simple => 1 );
   ```

4. **Özel Dosya Uzantısı ile Otomatik Basit Mod:**  
   AmberDB'de `db_ext` ayarına `"db"` dışında herhangi bir uzantı verildiğinde (örneğin `"dat"`, `"cache"`, `"session"`) motor **otomatik olarak basit moda** geçer:
   ```perl
   my $adb = AmberDB->new(
       path => { dbase_dir => "/var/data/cache" },
       cfg  => { db_ext    => "dat" },  # Farklı uzantı tanımlamak, otomatik simple => 1 tetikler
   );
   ```

> **Dizin Yapısı Notu:** Standart modda tablolar `$dbase_dir/table/` altında yer alırken, Basit Modda hiçbir alt dizin hiyerarşisi aranmaz; tablolar doğrudan kök `$dbase_dir/<tablo>.<uzanti>` olarak oluşturulur ve açılır. Standart moddaki bir tabloyu basit modda açmak için `dbase_dir` yolu olarak doğrudan `dbstore/table` dizini verilmelidir.

---

### 5.2 Esnek ve Kısıtlamasız ID Yapısı (Arbitrary Keys)

Standart moddaki **8-baytlık sabit uzunluk** ve **katı ASCII/sayısal şema kısıtlamaları** basit modda esnetilmiştir (`id_check` serbest skalar anahtarları kabul eder ve güvenli anahtar sanitizasyonu uygular):

- **E-Posta ve Özel Karakterler:** `user@example.com`, `api:v1:user:1005`
- **Uzun Belirteçler ve UUID'ler:** `sess_99999_abcdef_1234567890_extra_long_token` (en fazla 255 bayt)
- **Tireli Kodlar ve Özel Formatlar:** `TR-2026-08-31-INVOICE-001`
- **Türkçe / Çok Dilli Karakterli Anahtarlar:** `prod_özellik_kırmızı_xl`
- **Güvenli Anahtar Sanitizasyonu:** Baş ve sondaki boşluklar otomatik kırpılır (`trim_space`); C katmanı veya CSV yedekleme bütünlüğünü bozan Null Byte (`\0`) ve kontrol karakterleri (`\r`, `\n`, `\t`) ile referanslar (dizi/hash ref) kesinlikle reddedilir.
- **Otomatik ID Esnekliği:** Özel ID'lerin son ID'den (`lastid`) büyük olma zorunluluğu yoktur.

```perl
$adb->insert_id( 'sessions', 'user@example.com', 'Aktif', 'Chrome', time() );
my @sess = $adb->read_id( 'sessions', 'user@example.com' );
```

---

### 5.3 Veri İşlemleri (CRUD ve Toplu İşlemler)

Tüm standart CRUD ve toplu metotlar basit modda eksiksiz çalışır:

```perl
# Tekil Ekleme, Okuma, Güncelleme, Silme
$adb->insert_id( 'orders', 'order_101', 'Beklemede', '150.00' );
my @order = $adb->read_id( 'orders', 'order_101' );
$adb->update_id( 'orders', 'order_101', 'Tamamlandı', '175.50' );
$adb->delete_id( 'orders', 'order_101' );
my $var_mi = $adb->exist_id( 'orders', 'order_101' );

# Toplu İşlemler (Bulk CRUD)
my $ins_status = $adb->insert_list( 'orders', [ 'o_1', 'A', 50 ], [ 'o_2', 'B', 75 ] );
my $mod_status = $adb->update_list( 'orders', [ 'o_1', 'A+', 55 ] );
my $del_status = $adb->delete_list( 'orders', 'o_1', 'o_2' );
```

---

### 5.4 İndekssiz Doğrudan Sorgulama ve Filtreleme

İkincil indeks dosyaları üretilmediği için sorgular doğrudan `.db` veri akışı üzerinden sıralı tarama (`recs_scan`) ile yürütülür:

1. **Tüm Tabloyu Okuma ve Sayfalama (`read_all`):**
   ```perl
   # Tüm kayıtlar veya sayfalama (offset => 0, limit => 10)
   my ( $toplam, @kayitlar ) = $adb->read_all( 'items', { offset => 0, limit => 10 } );
   
   # Sadece anahtar listesi alma
   my @anahtarlar = $adb->read_all( 'items', { keys_only => 1 } );
   
   # Bellek içi sıralama (Blok 3'e göre artan: -3, azalan: 3)
   my @sirali = $adb->read_all( 'items', { sort => -3, keys_only => 1 } );
   ```

2. **Alana Göre Eşleştirme (`field_fetch`):**
   ```perl
   # Blok 2: Kategori = 'Giyim' olanları getir
   my @giyimler = $adb->field_fetch( 'catalog', 2, 'Giyim' );
   
   # Çoklu değer eşleme (Blok 3: Renk in ['Mavi', 'Siyah'])
   my ( $adet, @sonuclar ) = $adb->field_fetch( 'catalog', 3, [ 'Mavi', 'Siyah' ], { offset => 0, limit => 20, sort => -4 } );
   ```

3. **Tam Metin Arama (`search_table`):**
   ```perl
   # Türkçe normalizasyonlu kelime araması (AND mantığı)
   my @haberler = $adb->search_table( 'articles', 'türkiye ekonomi' );
   
   # Alan filtresiyle birlikte arama (Blok 2: Kategori = 'Finans')
   my ( $sayi, @filtrelenmis ) = $adb->search_table( 'articles', 'faiz', { offset => 0, limit => 10, filter => [ 2, 'Finans' ] } );
   ```

---

### 5.5 İşlemler (Transactions - ACID Desteği)

Basit modda `transact_start`, `transact_error` ve `transact_end` ACID desteği tam olarak çalışır. Hata bildirildiğinde (`transact_error`) veya bir işlem başarısız olduğunda `transact_end` otomatik olarak geri alma (`rollback`) tetikler ve ham `.db` dosyasındaki ekleme, düzenleme ve silmeler anında eski haline döndürülür:

```perl
$adb->transact_start();
eval {
    $adb->insert_id( 'sessions', 'token_123', 'GeciciVeri', time() );
    if ($hata_var) {
        $adb->transact_error( 'sessions', 'Kritik islem hatasi' );
    }
};
if ($@) {
    $adb->transact_error( 'sessions', $@ );
}
my $txn = $adb->transact_end(); # Hata varsa otomatik rollback, yoksa commit
```

---

### 5.6 Günlük Sürekli Yedekleme Günlükleri (Daily Backup Logs - `recs_back`)

Basit mod şemadan bağımsız olduğundan, **metin tabanlı sürekli denetim ve kurtarma akışı (`recs_back`)** basit modda da varsayılan olarak devrededir.

Basit modun düz dizin yapısı gereği ayrı bir `backup/` veya `YYYY/` alt klasörü oluşturulmaz; yapılan her `insert_id` (`add`), `update_id` (`edit`) ve `delete_id` (`del`) işlemi doğrudan tablolarla aynı dizinde bulunan **`$dbase_dir/YYYY-MM-DD.csv`** günlük dosyasına CSV formatında işlenir:

```text
2026-08-31 14:30:00    admin    add     sessions    sess_token_99999    Aktif\x1f192.168.1.50
2026-08-31 14:31:15    admin    edit    sessions    sess_token_99999    Kapali\x1f192.168.1.50
2026-08-31 14:32:00    admin    del     sessions    sess_token_99999    
```

- İstenirse `cfg => { no_backup => 1 }` veya `$adb->config(no_backup => 1)` ile yedekleme günlükleri devre dışı bırakılabilir.
- Özel bir yedek dizini tanımlanmak istendiğinde `path => { backup_dir => "/harici/yedek/yolu" }` verilebilir.

---

### 5.7 Basit Modda RAM-Disk Mimarisi ve Önbellekleme

AmberDB standart modda RAM-disk hızlandırmasını şemadaki `use_ramdisk => 2` kuralı ile yönetir.

**Basit modda ise RAM-disk kullanımı çok daha doğrudan ve esnektir:**  
Basit mod şemaya ihtiyaç duymadığından, yüksek performanslı bir bellek önbelleği / geçici oturum deposu oluşturmak için ikinci bir AmberDB basit nesnesi doğrudan RAM-disk yoluna bağlanır:

```perl
# 1. Kalıcı disk nesnesi (Kalıcı veriler için)
my $db_kalici = AmberDB->new(
    path => { dbase_dir => "/var/data/eticaret/dbstore/table" },
    cfg  => { simple => 1 },
);

# 2. RAM-Disk nesnesi (Sıfır gecikmeli hızlı oturum/önbellek tabloları için)
# (Linux: /dev/shm veya tmpfs, Windows: ImDisk, macOS: APFS RAM-Disk /Volumes/AmberDB_RAM)
my $db_ramdisk = AmberDB->new(
    path => { dbase_dir => "/dev/shm/amber_cache" },
    cfg  => { simple => 1, no_backup => 1 }, # Önbellek için yedekleme kapatılabilir
);

# RAM üzerinde nanosaniye hızında oturum okuma/yazma:
$db_ramdisk->insert_id( "oturumlar", $session_token, $user_id, time() );
my @oturum = $db_ramdisk->read_id( "oturumlar", $session_token );
```

Bu çift nesneli mimari sayesinde:
- RAM-disk üzerindeki tablolar disk I/O darboğazına takılmadan bellek hızında çalışır.
- Kalıcı tablolar ana depolama alanında güvenle tutulmaya devam eder.
- Şema dosyası hazırlama zorunluluğu olmadan saniyeler içinde dinamik önbellek tabloları açılabilir.

---

### 5.8 Basit Mod: Yetenekler ve Kısıtlamalar Karşılaştırması

| Özellik / Mekanizma | Standart Mod (`simple => 0`) | Basit Mod (`simple => 1`) |
| :--- | :---: | :---: |
| **Şema Dosyaları (`.table`, `.dbase`)** | Zorunlu / Kullanılır | Yok / Şemasız |
| **Özel ve Uzun ID'ler (UUID, E-posta, vb.)** | 8 Bayt / ASCII Kısıtlı | **Tamamen Serbest** |
| **Tekil CRUD (`insert_id`, `read_id`, vb.)** | $O(1)$ | **$O(1)$ (Maksimum Hız)** |
| **Toplu İşlemler (`insert_list`, vb.)** | Desteklenir | Desteklenir |
| **Tüm Tablo Okuma (`read_all`)** | `.inx` veya doğrudan | Doğrudan Dosya Taraması |
| **Sayfalama (`start`/`limit`) ve `keys_only`** | Desteklenir | Desteklenir |
| **Bellek İçi Sıralama (`sort => 2`)** | Desteklenir | Desteklenir |
| **Alana Göre Filtre (`field_fetch`)** | `.fld` İndeksli $O(1)$ | Sıralı Dosya Taraması |
| **Tam Metin Arama (`search_table`)** | `.src` Ters İndeksli | Sıralı Dosya Taraması (Türkçe Normalizasyonlu) |
| **ACID İşlemler (`transact_*`)** | Desteklenir (İndeks Geri Alma Dahil) | **Desteklenir (Ham Veri Geri Alma)** |
| **Sürekli Yedekleme Akışı (`recs_back`)** | Desteklenir (`backup/YYYY/`) | **Desteklenir (Aynı Dizinde `YYYY-MM-DD.csv`)** |
| **İkincil İndeksler (`.inx, .fld, .src, .srt, .fac`)** | Oluşturulur ve Güncellenir | **Oluşturulmaz (Sıfır İndeks Maliyeti)** |
| **URL Slug Rewrite (`.slg`)** | Otomatik Üretilir | Devre Dışı |
| **Denetim İzi (`.aut`) ve Arşiv (`.del`)** | Şema Kuralına Göre Tutulur | Devre Dışı |
| **Dizin Yapısı** | `tables/`, `schema/`, `backup/` vb. | **Düz Kök Dizin (`$dbase_dir/<tablo>.db`)** |
| **İkincil İndeksler (`.inx, .fld, .src, .srt, .fac`)** | Oluşturulur ve Güncellenir | **Oluşturulmaz (Sıfır İndeks Maliyeti)** |
| **URL Slug Rewrite (`.slg`)** | Otomatik Üretilir | Devre Dışı |
| **Denetim İzi (`.aut`) ve Arşiv (`.del`)** | Şema Kuralına Göre Tutulur | Devre Dışı |
| **Dizin Yapısı** | `tables/`, `schema/`, `backup/` vb. | **Düz Kök Dizin (`$dbase_dir/<tablo>.db`)** |

---

## 6. İndeksleme ve Arama Mekanizması

AmberDB, tablolara hızlı erişim sağlamak için veriyi şemada tanımlanan kurallara göre ikili (binary) indeks dosyalarına yazar.

### 6.1 İndeks Türleri

| Dosya Uzantısı | İndeks Türü | Açıklama |
|---|---|---|
| `.inx` | Kayıt İndeksi | Tablodaki tüm aktif ID'lerin sıralı ikili dizisi, toplam kayıt ve son ID bilgisi. |
| `.fld` | Eşleştirme (Match) | Blok bazlı değer eşleştirmesi (`field_fetch`). Değer → ID ikili dizisi. |
| `.str` | Alan Sözlüğü (Dictionary) | `.fld` eşlikçisi; serbest metinleri sayısal ID'lere bağlayan çift yönlü sözlük (`_${blk}.str`). |
| `.src` | Tam Metin (Search) | Kelime bazlı ters indeks (`search_table`). Kelime → ID ikili dizisi. |
| `.srt` | Sıralama (Sort) | Belirlenen bloklara göre önceden sıralanmış ikili RID dizisi (`sort_block`). |
| `.fac` | Facet İndeksi | E-ticaret filtreleme panelleri için kayıt başına aktiflik ve özellik haritası. |
| `.slg` | Slug Haritası | `_0.slg` (ID → Slug) ve `_1.slg` (Slug → ID) çift yönlü URL eşleştiricisi. |

### 6.2 8-Bayt İkili (Binary) Paketleme Standardı

AmberDB, indeks dosyalarında maksimum performans ve minimum disk boyutu elde etmek için **8-baytlık homojen ikili paketleme** kullanır:
- **Sayısal ID'ler:** İkili indeksler (`.inx`, `.srt`, `.fld`) kayıt kimliklerini saf 64-bit Big-Endian işaretsiz tam sayı (`(Q>)*`) olarak 8 baytlık sabit genişlikli bloklar halinde paketler.
- **Metin Anahtarlar (`use_simple => 1`):** UUID, e-posta, slug veya serbest metin anahtarlar gerektiğinde ilgili tablo `use_simple => 1` bayrağı ile yapılandırılır. Bu modda ikili indeks (`.inx`) yükü ortadan kalkar ve 255 bayta kadar serbest anahtarlar doğrudan Berkeley DB anahtar-değer katmanında saklanır.

Bu sayede milyonlarca kayıt içeren indeks dosyalarında sayfalama (`LIMIT/OFFSET`), belleğe tüm listeyi yüklemeden doğrudan `substr` ile $O(1)$ zero-copy ikili ofset dilimleme yöntemiyle gerçekleştirilir.

### 6.3 Eşleştirme İndeksi (`.fld`) ve Çift Yönlü Alan Sözlüğü (`.str`)

AmberDB'de `match_block` içinde tanımlanan alanlar için indeksleme iki tamamlayıcı katmanda gerçekleşir:

1. **İkili Eşleştirme İndeksi (`.fld`):**  
   AmberDB'de her blok için ayrı dosya açılmaz; tüm alan eşleşmeleri tek bir `<tablo>.fld` dosyasında toplanır. Bu dosya, `"$blok:$deger"` anahtarları karşılığında ilgili kayıt ID'lerini 8-baytlık ikili paketlenmiş diziler (`(Q>)*`) olarak saklar. `field_fetch` sorguları bu dosyadan doğrudan $O(1)$ tekil anahtar okuması yapar.

2. **Çift Yönlü Alan Sözlüğü (`.str`):**  
   Eğer indekslenen alan serbest metin (kategori adı, marka adı, yazar, etiket vb.) içeriyorsa, motor otomatik olarak `<tablo>_<blok>.str` sözlük dosyasını yönetir:
   * **İleri Yön (`s:<metin>` $\rightarrow$ `$nid`):** Metin ifadelerine benzersiz artan sayısal bir kimlik (`$nid`) atar.
   * **Geri Yön (`n:$nid` $\rightarrow$ `<metin>`):** Sayısal kimlikten orijinal metin etiketine anında dönüş sağlar.
   * **Otomatik Çözümleme:** `field_fetch` veya `field_filter` çağrıldığında geliştirici ister sayısal ID (`12`) ister metin dizesi (`"Sony"`) versin, motor `.str` sözlüğünden değeri otomatik çözümler ve `.fld` üzerinden anında eşleşen kayıtları getirir.

### 6.4 Sıralama Mekanizması ve Kullanım Rehberi

AmberDB, tablolardaki belirli bloklara göre yüksek performanslı ve önceden indekslenmiş sıralama yeteneği sunar.

#### 6.4.1 Şema Yapılandırması (`sort_block`)
Sıralama yapılacak alanlar tablo şema dosyasında (`.table`) tanımlanır. Sadece blok numarası verilebileceği gibi (`4`), sayısal veya tarihsel alanlar için tip (`type`) belirtilebilir:

```perl
# dbstore/schema/catalog_product.table
{
    sort_block => [
        4,                             # Blok 4: Başlık (Metin sıralaması)
        { blk => 10, type => 'num' },  # Blok 10: Fiyat (Sayısal sıralama)
        { blk => 12, type => 'date' }, # Blok 12: Tarih sıralaması (YYYYMMDDHHMMSS)
    ],
}
```

#### 6.4.2 Sorgularda Sıralama Kullanımı
`read_all`, `field_fetch` ve `search_table` fonksiyonlarında `sort` parametresi kullanılarak sorgular anında sıralı şekilde alınır:

```perl
# 1. Varsayılan Yön: Azalan / Büyükten Küçüğe (DESC: 99->0, Z->A)
my @urunler = $adb->read_all("catalog_product", { sort => 10 });
my @urunler = $adb->read_all("catalog_product", { sort => { blk => 10 } });

# 2. Ters Yön: Artan / Küçükten Büyüğe (ASC: 0->99, A->Z)
my @urunler = $adb->read_all("catalog_product", { sort => -10 });
my @urunler = $adb->read_all("catalog_product", { sort => { blk => 10, reverse => 1 } });

# 3. Birincil Anahtar (ID) Artan Sıralama:
my @urunler = $adb->read_all("catalog_product", { sort => { reverse => 1 } }); # 1..N en eski ilk

# 4. field_fetch ve search_table ile Sıralı Filtreleme:
my @kat_urunleri = $adb->field_fetch("catalog_product", 1, "elektronik", { sort => { blk => 10, reverse => 1 } });
my ($adet, @arama) = $adb->search_table("catalog_product", "kulaklık", { offset => 0, limit => 20, sort => -10 });
```

---

## 7. İşlem Güvenliği, ACID Garantileri ve Kurtarma (Transactions)

`AmberDB::Transact`, çoklu tablo güncellemelerinde ve döngüsel iş kurallarında (örn. sipariş oluşturma + stok düşme + bakiye tahsilatı) **tam ACID uyumlu (ACID-Compliant)** işlem bütünlüğü ve **Strict Two-Phase Locking (Strict 2PL)** yalıtımı sağlar.

### 7.1 İşlemsel Bütünlük ve Tek Transaction Omurgası (Transactional Integrity)

Modern bir e-ticaret veya kurumsal iş akışında tek bir kullanıcı eylemi (örneğin "Siparişi Tamamla"), arka planda birden çok bağımsız tabloyu ve sistemi ilgilendiren semantik bir işlem zincirini tetikler:

```text
Sipariş İşlem Zinciri:
 ├─ Sipariş Onayı (orders tablosuna kayıt atılması)
 ├─ Sepetin Boşaltılması (cart tablosundan ürünlerin silinmesi)
 ├─ Müşteri Hesabı (bakiye düşümü veya kart çekim kaydı)
 ├─ Şirket Hesabı (muhasebe/kasa defterine gelir kaydı)
 ├─ Stok Yönetimi (catalog_product tablosunda adet düşümü)
 └─ Tedarikçi Bildirimi (supplier_queue tablosuna iş emri yazılması)
```

Bu adımlar birbirini **semantik olarak doğrudan etkileyen ve tamamlayan işlemlerdir**. Birinin başarısız olması durumunda diğerlerinin veritabanında başarılı kalması sistem açısından büyük bir tutarsızlığa yol açar. Örneğin:
- Müşteri kartından para çekilip sipariş kaydı oluşturulduktan sonra stok düşme aşamasında bir hata meydana gelirse;
- Ya da stok düşülüp müşteri sepeti boşaltıldığı halde şirket kasasına gelir kaydı yazılamazsa;

veritabanı parçalı ve bozuk bir duruma düşer. Bu nedenle birbiriyle ilişkili tüm bu adımların **tek bir transaction omurgası (`transact_start` $\rightarrow$ `transact_end`)** altında yürütülmesi gerekir. Adımlardan herhangi biri başarısız olduğunda veya sistem çöktüğünde AmberDB, o ana kadar yapılan tüm disk ve indeks değişikliklerini geriye doğru (LIFO sırasıyla) geri alarak (`rollback`) veritabanını işlemin hiç başlamadığı ilk temiz ve kararlı haline döndürür.

### 7.2 AmberDB'de ACID Şartlarının Karşılanması

AmberDB, gömülü (embedded) ve şema güdümlü mimarisine uygun olarak 4 temel ACID ilkesini şu mekanizmalarla garanti eder:

| İlke | Kısaltma | AmberDB'deki Teknik Karşılığı ve Güvencesi |
| :--- | :--- | :--- |
| **Atomicity** | **A** (Atomiklik) | **Disk Destekli Geri Alma Günlüğü (Undo-Journal):** `transact_start` ile mikrosaniye hassasiyetinde `.txn` kütüğü açılır. Yapılan her `insert_id`, `update_id`, `delete_id` çağrısının tersi (undo verisi) günlüğe kaydedilir. Hata veya `transact_rollback` durumunda, yapılan tüm değişiklikler ana `.db` dosyasında, `.del` arşivinde, `.aut` denetim izinde ve ilişkili ikincil indekslerde (`.inx`, `.src`, `.fld`, `.fac`, `.srt`, `.slg`, `.jinx`, `.jsrc`, `.jfld`) **LIFO (son yapılan ilk)** sırasıyla tamamen geri alınır. |
| **Consistency** | **C** (Tutarlılık) | **Şema, İndeks ve Durum Bütünlüğü:** Her kayıt tanımlı şema alanlarına (`schema`), veri tiplerine ve boyut sınırlarına göre doğrulanır. Otomatik artan sayaç (`autoid`), ikincil arama/faset indeksleri ve URL slug eşleşmeleri işlem anında eşzamanlı güncellenir. Bir işlem geri alındığında bellek önbelleği (`set_cache`) ve tüm indeks türevleri eski temiz haline getirilerek veritabanı asla tutarsız ara durumda bırakılmaz. |
| **Isolation** | **I** (Yalıtım) | **Strict Two-Phase Locking (Strict 2PL):** Bir transaction sırasında değiştirilen tüm kayıtlar işletim sistemi seviyesinde `flock(LOCK_EX)` ile kilitlenir. Kilitler işlem devam ederken açık tutulur; başka hiçbir sürecin bu kayıtları eşzamanlı değiştirmesine izin verilmez. Kilitler yalnızca `transact_end` veya `transact_rollback` anında topluca serbest bırakılır. Bu sayede serileştirilebilir (Serializable) seviyede yalıtım sağlanır. |
| **Durability** | **D** (Dayanıklılık) | **Senkronize Günlükleme & Çökme Kurtarma (`transact_recover`):** Her günlük yazımında `$fh->flush` işletilir; `cfg => { txn_sync => 1 }` yapılandırıldığında çekirdek seviyesinde `fsync` (`$fh->sync`) ve Berkeley DB tampon senkronizasyonu (`DB_File->sync`) uygulanır. Süreç aniden çökse bile yetim (orphan) `.txn` dosyaları kilit durumuna göre tespit edilir ve otomatik olarak geri alınır. |

> **Not: Toplu İşlemler (Batch / ETL) ve Transaction Ayrımı**  
> `insert_list`, `update_list` ve `delete_list` metotları, harici XML/JSON/CSV dosyalarından yüksek verimli toplu veri aktarımları (ETL) için tasarlanmıştır. Liste kayıtları birbiriyle bağlantılı ve birbirini etkileyen kayıtlar olmadığı gibi bu tür yüklemelerde bozuk birkaç kayıt için binlerce geçerli kaydın geri alınması istenmez. Karşılıklı bağımlılık ve atomik bütünlük gerektiren iş mantığı süreçlerinde (sipariş, stok, fatura) tekil CRUD metotları (`insert_id`, `update_id`, `delete_id`) transaction bloğu içinde çalıştırılır. Eğer bir liste yüklemesi transact edilmesi gerekiyorsa listeyi döngü içine yerleştirerek tekil işlemleri (`insert_id`, `update_id`, `delete_id`) kullanınız. Bu şekilde tüm liste tam transact edilir.

### 7.3 Transaction Yaşam Döngüsü

Dış API ve uygulama kodlarında transaction süreçleri şu metotlar üzerinden yürütülür:

1. **`transact_start()`**: Yeni bir işlem başlatır, `$dbase_dir/journal/` altında mikrosaniye hassasiyetinde bir `txn_*` undo günlüğü açar ve yetim işlemleri onarır (`transact_recover`).
2. **`transact_rollback()`**: İş mantığı veya operasyonel iptallerde (stok yetersizliği, bakiye yetersizliği, kullanıcı iptali vb.) işlemi doğrudan geri sarar; LIFO sırasıyla değişiklikleri geri alır, kilitleri serbest bırakır ve günlüğü temizler.
3. **`transact_end()`**: Normal akış sonunda çağrılır; duruma bakar, herhangi bir hata veya geri alma durumu yoksa `transact_commit()` çalıştırarak işlemi kalıcı olarak onaylar (`status => "commit"`).
4. **`transact_commit()`**: Herhangi bir durum kontrolü yapmadan işlemi doğrudan ve olumlu olarak kesinleştirir.

> [!NOTE]
> `transact_error($file_path, $message)` motorun iç dosya ve yazma güvenliği mekanizmasıdır. Yazılan dosya bir ana veri tablosu (`.$db_ext`) ise ve tabloda `no_transact` tanımlı değilse arka planda anında `transact_rollback()` çalıştırır. İkincil indeks dosyalarındaki yazma aksaklıkları ise işlemi geri almaz.

### 7.4 Örnek: Sipariş ve Stok Yönetimi Transaction'ı

```perl
# 1. Transaction başlat
$adb->transact_start();

my $urun_id = 42;
my $adet    = 2;
my $user_id = 1001;

# Ürünü oku ve stok kontrolü yap
my @urun = $adb->read_id("catalog_product", $urun_id);
my $mevcut_stok = $urun[8]; # Blok 8 = Stok miktarı

if ($mevcut_stok < $adet) {
    # Stok yetersizse hata bildir (transact_end otomatik rollback yapacaktır)
    $adb->transact_error("catalog_product", "Yetersiz stok ($mevcut_stok < $adet)");
} else {
    # Stoğu düş ve güncelle (@urun[0] zaten $urun_id değerini içerir)
    $urun[8] -= $adet;
    $adb->update_id("catalog_product", @urun);

    # Sipariş kaydı oluştur
    my @siparis = ( $user_id, $urun_id, $adet, time(), "onaylandi" );
    my $siparis_id = $adb->insert_id("orders", undef, @siparis);
}

# Transaction'ı tamamla (hata yoksa commit, hata varsa otomatik rollback)
my $sonuc = $adb->transact_end();

if ($sonuc->{status} eq "commit") {
    print "Sipariş başarıyla oluşturuldu ve stok düşüldü!\n";
} else {
    warn "İşlem başarısız oldu, tüm değişiklikler otomatik geri alındı!\n";
}
```

### 7.5 Journal Dayanıklılığı ve Kurtarma (Durability & Crash Recovery)

- **IO::Handle Tampon Temizliği (Flush/Sync):** Her işlem anında `$fh->flush` ile tampondan diske iletilir. İsteğe bağlı olarak `cfg => { txn_sync => 1 }` yapılandırıldığında işletim sistemi ve disk seviyesinde fiziksel senkronizasyon (`$fh->sync` / `fsync`) gerçekleştirilir.
- **`flock` Tabanlı Sahiplik:** Transaction başlatıldığında `.txn` dosyası üzerinde non-blocking exclusive kilit (`LOCK_EX | LOCK_NB`) alınır. Süreç çalıştığı müddetçe kilit korunur; sürecin çökmesi halinde kilit işletim sistemi tarafından otomatik serbest bırakılır.
- **Yetim İşlem Kurtarma (`transact_recover`):** Sunucunun aniden kapanması veya Perl sürecinin beklenmedik şekilde sonlanması durumunda `txn/` klasöründe kalan yetim (orphan) `.txn` dosyaları taranır. `flock` ile dosya kilidinin serbest kaldığı ve sürecin ölü olduğu doğrulanırsa kayıtlar ve indeksler otomatik olarak kararlı duruma geri döndürülür. Eşzamanlı canlı süreçlerin dosyalarına yarış durumuna (race condition) mahal vermeden kesinlikle dokunulmaz.

### 7.6 Temel Mimari İlke: Otoriter Veri vs. Yeniden Üretilebilir İndeksler

AmberDB'nin dosya ve işlem mimarisi kesin bir hiyerarşiye dayanır:

1. **Otoriter Temel Dosyalar (Authoritative Data - Başka Yerden Üretilemez):**
   - **`.db` (Ana Veri):** Tablodaki tüm aktif kayıtların birincil ve tekil döküman verisidir (*Source of Truth*).
   - **`.del` (Silinen Kayıtlar Arşivi):** Soft-delete yapılan kayıtların tutulduğu arşivdir. Bir kayıt `.db`'den silindiğinde bu arşive taşınır; `.db` üzerinden geriye dönük tekrar üretilemez.
   - **`.aut` (Kullanıcı Denetim İzi / Audit Trail):** Hangi kullanıcının hangi tarihte hangi işlemi (ekleme, düzenleme, silme) yaptığının zamana bağlı kronolojik tarihçesidir; başka hiçbir veri kaynağından yeniden üretilemez.

2. **Türetilmiş ve Yeniden Üretilebilir İndeksler (Derived & Rebuildable Indexes):**
   - **`.inx` (Kayıt Listesi), `.fld` (Eşleştirme), `.src` (Arama), `.srt` (Sıralama), `.fac` (Facet), `.slg` (Slug Haritası):** Bu dosyaların tamamı `.db` dosyasındaki otoriter veriden türetilir.
   - Herhangi bir indeks dosyası silinir, bozulur veya eksik yazılırsa `AmberDB::Tools->set_index($tablo)` çağrısıyla saniyeler içinde **sıfır veri kaybıyla %100 yeniden üretilebilir**.

> **Transaction Tasarımının Temeli:** `AmberDB::Transact` mekanizması bu ilkeye göre kurgulanmıştır. Ana `.db` yazımında bir hata oluşursa (`is_index == 0`) transaction otomatik olarak geri alınır (`rollback`). Ancak ana veri `.db`'ye başarıyla yazıldıktan sonra bir indeks yazımında hata oluşursa (`is_index == 1`), geçerli ve parası ödenmiş/onaylanmış iş verisi çöpe atılmaz; transaction başarılı kabul edilir ve indeks sonradan `AmberDB::Tools` ile kolayca yeniden indekslenir.

### 7.7 Tali Tabloları Transaction Hata Zincirinden Muaf Tutma (`no_transact`)

Karmaşık iş akışlarında (örneğin sipariş oluşturma + stok düşme + bakiye tahsilatı) bazı tablolar **çekirdek işlem** (sipariş, ödeme, stok), bazı tablolar ise **tali / yardımcı veri** (müşteri sipariş geçmişi özeti, ürün görüntüleme sayaçları, bildirim kuyrukları) niteliğindedir. Tali bir tabloya yazarken oluşabilecek beklenmedik bir hata yüzünden parası ödenmiş asıl siparişin iptal edilmesi (`rollback`) istenmez.

AmberDB, şemada veya çalışma zamanında `no_transact => 1` tanımlanmış tabloları **transaction hata zincirinden muaf tutar**:

1. **Statik Şema Tanımı (`.table` dosyası):**
   ```perl
   # order_customer_summary.table
   {
       name        => "Müşteri Sipariş Özeti",
       no_transact => 1,   # Hata oluşursa ana transaction'ı iptal etme
       schema      => [qw(user_id order_id amount created_at)],
   }
   ```

2. **Dinamik Çalışma Zamanı Tanımı (`table_attr`):**
   ```perl
   # Çalışma anında belirli bir akış için tabloyu muaf tutma:
   $adb->table_attr("order_customer_summary", no_transact => 1);
   ```

> **Nasıl Çalışır?**  
> - `no_transact => 1` olan bir tabloya yazarken hata oluşursa, bu hata `is_index` gibi değerlendirilir ve `transact_end` ana işlemi başarıyla `commit` eder.  
> - Ancak ana işlemde (ödeme/stok) gerçek bir hata olur ve transaction `rollback` edilirse, `no_transact` tablosundaki kayıtlar da **tutarlılık gereği `.txn` kütüğünden otomatik olarak geri alınır**. Böylece veritabanında asla hayalet/tutarsız kayıt kalmaz.

### 7.8 Çoklu Süreç Eşzamanlılığı, Kilit İzolasyonu ve Stres Testi Doğrulaması

AmberDB, web sunucuları (Apache, Plack/PSGI, Starman, FastCGI, Starlet) ve arka plan işçileri (cron, kuyruk yöneticileri) gibi **onlarca eşzamanlı sürecin aynı anda aynı tablolara ve indekslere eriştiği** yoğun üretim ortamları için tasarlanmıştır.

#### İşletim Sistemi Seviyesinde Kilit ve Platform İzolasyonu:
1. **Linux / POSIX Ortamı:** POSIX `fork()` mekanizması ve çekirdek seviyesindeki `flock(LOCK_EX)` / `flock(LOCK_SH)` kilitleri sayesinde her işçi süreç tamamen yalıtılmış bellek alanında çalışır ve dosya kilitleri süreçler arasında tam seri (serializable) izolasyon sağlar.
2. **Windows / MSYS2 Ortamı:** Windows NT çekirdeğinde işletim sistemi seviyesindeki kilit bütünlüğü, bağımsız OS süreçleri üzerinden eksiksiz biçimde korunur.
3. **Kayıt Düzeyinde Kilit (`flock_open` / `flock_close`):** Aynı anda birden fazla sürecin aynı kaydı (örneğin sınırlı stoktaki bir ürünü veya ortak bir sayacı) güncellemeye çalıştığı senaryolarda `flock_open($table, "write", $id)` kullanılarak yarış durumları (race conditions) ve kayıp güncellemeler (lost updates) %100 engellenir.

#### Concurrency & Stres Test Paketi (`xt/amberdb_concurrency_stress.t`):
Motorun aşırı yük ve eşzamanlılık altındaki dayanıklılığı yazar test paketi ile doğrulanmaktadır:
```bash
# Eşzamanlılık stres testlerini çalıştırmak için:
perl -Ilib xt/amberdb_concurrency_stress.t
```
Bu test paketi 5 kritik senaryoyu doğrular:
- **1. Paralel Yazıcılar:** Çoklu süreçlerin aynı anda yüzlerce kaydı ve ilgili tüm ikincil indeksleri (`.inx`, `.fld`, `.src`, `.fac`, `.srt`, `.slg`) hatasız ve çakışmasız yazması.
- **2. Eşzamanlı Okuma & Yazma:** Süreçlerin bir yandan arama ve filtreleme yaparken diğer yandan kayıt eklemesi sırasında kilitlenme (deadlock) veya veri bozulması yaşanmaması.
- **3. Eşzamanlı Bağımsız İşlemler ve Çökme Kurtarma:** İşlem ortasında aniden çöken süreçlerin geride bıraktığı yetim `.txn` kütüklerinin `transact_recover` ile canlı süreçleri etkilemeden temizlenmesi.
- **4. Eşzamanlı Slug Çakışma Yönetimi:** Farklı süreçlerin aynı anda aynı ürün başlığıyla kayıt eklemesi durumunda çift yönlü benzersiz URL slug haritasının (`_0.slg` $\leftrightarrow$ `_1.slg`) deterministik korunması.
- **5. Kayıt Kilidiyle Yüksek Eşzamanlı Stok Güncellemesi:** Birden fazla işçinin aynı kaydın stoğunu eşzamanlı düşürdüğü senaryoda atomik değer tutarlılığı.

---

## 8. Yüksek Başarımlı Toplu (Batch) İşlemler (Batch ETL & Ingestion)

AmberDB, harici veri kaynaklarından (CSV, JSON, XML, REST API) binlerce veya yüzbinlerce kaydın içeri aktarımı (ETL) ve toplu güncellenmesi için özel **2-Fazlı Batch İşlem Boru Hattı (2-Phase Batch Pipeline)** sunar.

### 8.1 Neden Döngü İçinde `insert_id` Yerine `insert_list` Kullanılmalıdır?

Tekil `insert_id`, her çağrıda işletim sistemi seviyesinde dosya açma (`open/tie`), kilit edinme (`flock`), sekans artırma ve ikincil indeksleri (`.inx`, `.src`, `.fld`, `.fac`, `.srt`) tek tek güncelleme adımlarını yürütür. $N$ adet kayıt için bu işlem $O(N \times K)$ dosya I/O ve sistem çağrısına neden olur.

`insert_list` ise süreci 2 faza ayırarak I/O maliyetini $O(K)$ seviyesine indirir:
1. **Faz 1 (Tek I/O ile Toplu DB Yazımı):** `.db` veri tablosu yalnızca **1 kez** açılır (`table_write`). Tüm kayıtların otomatik ID'leri topluca atanır (`table_autoid`), alan tekrarları ve şema doğrulamaları yapılır ve tüm batch tek bir disk yazma penceresinde Berkeley DB'ye eklenir (`recs_put`).
2. **Faz 2 (Tek Seferde Toplu İndeks Derleme):** Her bir ikincil indeks dosyası (`.inx`, `.src`, `.fld`, `.fac`, `.srt` ve junk tier) yalnızca **1 kez** açılarak tüm batch'e ait ikili indeks blokları tek geçişte (`batch merge`) işlenir (`records_add`, `search_add`, `match_add`, `facet_add`, `sort_add`).

> [!TIP]
> 10.000 kayıtlık bir veri setinde `insert_list`, tekil `insert_id` döngüsüne kıyasla **50 ila 100 kat daha hızlı** tamamlanır.

### 8.2 Toplu Kayıt Ekleme (`insert_list`)

```perl
# Kayıt dizisi: Her eleman bir kayıt sütun dizisidir. 
# Otomatik ID için 0 veya undef verilir.
my @yeni_urunler = (
    [ 0, "5",    "3", "Kablosuz Kulaklık", "149.90", "2026-08-28", "1" ],
    [ 0, "5,12", "8", "Mekanik Klavye",    "299.00", "2026-08-28", "1" ],
    [ 0, "12",   "3", "Oyuncu Faresi",     "89.50",  "2026-08-28", "1" ],
    # ... yüzlerce kayıt ...
);

my $statu = $adb->insert_list("catalog_product", @yeni_urunler);
# $statu hashref döner: { 101 => 1, 102 => 1, 103 => 1, ... }
```

### 8.3 Toplu Kayıt Güncelleme (`update_list`)

```perl
my @guncellemeler = (
    [ 101, "5",    "3", "Kablosuz Kulaklık Pro", "179.90", "2026-08-28", "1" ],
    [ 102, "5,12", "8", "Mekanik Klavye RGB",    "329.00", "2026-08-28", "1" ],
);

my $statu = $adb->update_list("catalog_product", @guncellemeler);
```

### 8.4 Toplu Kayıt Silme (`delete_list`)

```perl
# Silinecek ID'ler doğrudan liste veya dizi referansı olarak verilebilir
my $statu = $adb->delete_list("catalog_product", 101, 102, 103);
# veya:
# $adb->delete_list("catalog_product", [101, 102, 103]);
```

### 8.5 Büyük Veri Yüklemelerinde (ETL) Chunk (Dilimleme) Stratejisi

Çok büyük veri setlerinde (örn. 50.000+ kayıt), RAM tüketimini optimize etmek ve disk buffer'ını rahatlatmak için verileri 500-1000'lik parçalara bölerek aktarmak en iyi pratiktir:

```perl
my $chunk_size = 1000;
for (my $i = 0; $i < @buyuk_veri; $i += $chunk_size) {
    my $end = $i + $chunk_size - 1;
    $end = $#buyuk_veri if $end > $#buyuk_veri;
    my @chunk = @buyuk_veri[$i .. $end];
    $adb->insert_list("catalog_product", @chunk);
}
```

---

## 9. Şema Yapılandırması (.table ve Kod İçi / In-Memory)

AmberDB şema güdümlü (schema-driven) bir veritabanı motorudur. Tablo şemaları; birincil anahtar kısıtlamalarını, alan tiplerini, çok boyutlu indeksleri, otomatik slug kaydı üretimini, facet filtrelerini, yaşam döngüsü (junk) kurallarını, veri doğrulama kurallarını ve SQL `JOIN` gerektirmeyen genişleyen dinamik alt kayıtları yönetir.

### 9.1 Veritabanı ve Tablo Dizin Yapısı

AmberDB tabloları, şemaları ve geçici/kalıcı dosyaları, belirlenen `dbstore` ana veri dizini altında fiziksel klasörlere ayrılarak saklanır:

| Dizin | Görevi |
|---|---|
| `dbstore/table/` | Kalıcı `.db` ana veri, `.inx` kayıt indeksi, `.fld` eşleştirme, `.src` arama, `.fac` facet, `.srt` sıralama ve `.slg` slug dosyaları |
| `dbstore/schema/` | Kalıcı `.table` tablo şemaları ve `.dbase` grup yapılandırma dosyaları |
| `dbstore/config/` | Kalıcı `.conf` düz metin ayar ve konfigürasyon dosyaları |
| `dbstore/backup/` | Günlük CSV denetim yedekleri (`dbgun/YYYYMMDD/`) |
| `dbstore/ramdisk/` | **Birleşik RAM-Disk (Linux tmpfs, Windows ImDisk, macOS APFS RAM-Disk) Kök Dizini:** |
| `dbstore/ramdisk/table/` | `use_ramdisk => 1, 2, 3` için RAM'e aynalanmış sıcak `.db` ve `.inx` tabloları |
| `dbstore/ramdisk/config/` | Derlenmiş hızlı yapılandırma önbelleği (`*.pl` hash referansları) |
| `dbstore/ramdisk/schema/` | RAM'de önbelleğe alınmış / derlenmiş tablo şemaları (`*.table`, `*.dbase`) |
| `dbstore/ramdisk/lock/` | Yalnızca RAM'de yaşayan kayıt ve tablo seviyesi `flock` kilitleri (`*.lock`) |
| `dbstore/ramdisk/pids/` | Yalnızca RAM'de yaşayan süreç kilitleri, login attempt hataları (`*.pid`, `*.error`) |

> [!IMPORTANT]
> **Dizin Yapısı Uyumluluk Notu:** Eski projelerden yükseltme yaparken yapmanız gereken tek fiziksel işlem; veritabanı dizininizdeki `dbstore/scheme/` klasörünün adını **`dbstore/schema/`** olarak yeniden adlandırmaktır. Kod ve API tarafındaki tüm çözümlemeleri motor otomatik olarak yönetir.

### 9.2 Şemanın Rolü ve Esnekliği: Zorunlu mu, İsteğe Bağlı mı?

AmberDB'de şema tasarımı **tamamen esnek ve katmanlıdır**:

* **Minimalist / Hafif Kullanım:** Şema dosyasında `blocks` (alan listesi) tanımlamak **zorunlu değildir**. Sadece hangi blokların indeksleneceğini belirten `record_index`, `match_block`, `search_block` ve `sort_block` tanımlanarak ultra hafif ve yüksek hızlı bir konfigürasyon oluşturulabilir.

```perl
# dbstore/schema/catalog_product.table
{
    name         => "Ürün Kataloğu",
    record_index => 1,                      # .inx birincil indeksini ve auto-increment sayacını açar
    match_block  => [ 1, 2, 3, 11 ],        # .fld Birebir eşleşme (Kategori, Marka, Yazar, Statü)
    search_block => [ 4, 5, 7, 9 ],         # .src Tam metin arama (Ad, Alt Başlık, Açıklama, Barkod)
    sort_block   => [ 4, { blk => 10, type => 'num' } ], # .srt Önceden sıralanmış binary ID indeksleri
    keep_deleted => 1,                      # Silinenleri .del dosyasında sakla (Soft-delete)
    log_owner    => 1,                      # Değişiklikleri yapan kullanıcıyı .aut dosyasına yaz
    
}
```

* **Gelişmiş / Form ve Doğrulama Destekli Kullanım:** `blocks` dizisi tanımlandığında; alan veri tipleri (`type`), form arayüz giriş bileşenleri (`input`), zorunlu/geçerli alan doğrulamaları (`valid`) ve ilişkili tablo eşleşmeleri (`rdbm`) otomatik olarak devreye girer.

### 9.3 Şema Tanımlama ve Okuma Yöntemleri (`table_info` & `table_attr`)

AmberDB'de şema iki şekilde tanımlanabilir ve programatik olarak okunabilir:

1. **Fiziksel Dosya Tabanlı Şema (Önerilen):**  
   Tablo şemaları `dbstore/schema/<tablo_adi>.table` dosyasına yerleştirilir. AmberDB ilk erişimde bu dosyayı otomatik olarak okur ve ayrıştırır.

2. **Bellek İçi Dinamik Şema (Programmatic / In-Memory):**  
   Disk dosyasına gerek kalmadan doğrudan `$adb->table_attr("tablo_adi", { ... })` metoduyla çalışma zamanında tanımlanır.

3. **Yüklü Şemayı Okuma (`table_info`):**  
   Tanımlı bir tablonun tüm şema konfigürasyonunu bellekten veya diskten hash referansı olarak almak için `$adb->table_info($tablo_adi)` kullanılır:
   ```perl
   my $schema = $adb->table_info("catalog_product");
   print "Tablo Adı: $schema->{name}\n";
   print "Arama Blokları: " . join(", ", @{ $schema->{search_block} || [] }) . "\n";
   ```

> [!IMPORTANT]
> **Şema Dosyaları (`.table` ve `.dbase`) Doğal Perl Kodudur (Hash Reference)**  
> AmberDB'de `.table` ve `.dbase` dosyaları JSON veya YAML değil, doğrudan Perl sözdizimiyle (`{ ... }`) yazılmış doğal Perl hash referansı yapılarıdır. Motor bu dosyaları çalışma zamanında Perl'in yerel `do` ifadesi ile dinamik olarak derler ve yükler.
>
> * **Sözdizimi Hatası Koruması:** Dosyada eksik virgül (`,`), kapatılmamış parantez (`}` veya `]`), hatalı tırnak işareti veya geçersiz bir Perl karakteri bulunursa `do` işlemi `undef` döner ve motor şemayı **kesinlikle yükleyemez** (şema boş kalır ve indeksleme kuralları devre dışı kalır).
> * **Doğrulama İpucu:** Şema dosyalarınızı kaydettikten sonra terminalden `perl -c dbstore/schema/tablo.table` komutuyla derleme kontrolü yaparak sözdizimi hatalarını anında görebilirsiniz.

### 9.4 Şema Dosyası Eşleşme Kuralları

AmberDB, tablo adını ayrıştırarak hangi şema dosyasını ve veritabanı ayarlarını yükleyeceğini otomatik belirler:

* **Veritabanı Ön Eki:** Tablo adında ilk alt çizgiden (`_`) önceki kısım veritabanı / mantıksal grup adıdır.
* **Şema Dosyası Eşleşmesi:** Örneğin `catalog_product` tablosunun şeması `dbstore/schema/catalog_product.table` dosyasında, grup ayarları ise `dbstore/schema/catalog.dbase` dosyasında saklanır.

### 9.5 Örnek Tablo Şeması (`catalog_product.table`)

Aşağıda e-ticaret ürün kataloğu için kapsamlı bir `.table` şema örneği verilmiştir:

```perl
# dbstore/schema/catalog_product.table
{
    name         => "Ürün Kataloğu",
    record_index => 1,                      
    match_block  => [ 1, 2, 3, 11 ],        
    search_block => [ 4, 5, 7, 9 ],         
    sort_block   => [ 4, { blk => 10, type => 'num' } ], 
    facet_block  => [ 1, 2, 3, 11 ],        
    slug_block   => [ 2, 4 ],               
    
    use_facet    => 1,                      
    facet_rules  => [ [ 11, "eq", 1 ] ],    
    use_junk     => 1,                      
    junk_rules   => [ [ 11, "eq", 0 ] ],    
    use_ramdisk  => 1,                      
    ramdisk_ttl  => 3600,                   
    keep_deleted => 1,                      
    log_owner    => 1,                      
    min_char     => 2,                      
    
    blocks => [
        { id => "id",           name => "Ürün ID",     type => "auto_id", input => "hidden" },
        { id => "category_id",  name => "Kategori",    type => "text",    input => "select",   rdbm => "catalog_category;2" },
        { id => "brand_id",     name => "Marka",       type => "text",    input => "select",   rdbm => "catalog_brand;2" },
        { id => "author_id",    name => "Yazar",       type => "text",    input => "text" },
        { id => "title",        name => "Ürün Adı",    type => "text",    input => "text",     valid => "not_null" },
        { id => "subtitle",     name => "Alt Başlık",  type => "text",    input => "text" },
        { id => "supplier",     name => "Tedarikçi",   type => "text",    input => "text" },
        { id => "description",  name => "Açıklama",    type => "html",    input => "textarea" },
        { id => "stock",        name => "Stok Adedi",  type => "num",     input => "text" },
        { id => "barcode",      name => "Barkod",      type => "text",    input => "text" },
        { id => "price",        name => "Fiyat",       type => "num",     input => "text" },
        { id => "status",       name => "Satış Durumu",type => "option",  input => "select",   option => "1:Satışta,0:Pasif" },
    ],
}
```

### 9.6 Şema Parametreleri ve Konfigürasyon Referansı (Tablo Düzeyi)

Aşağıdaki tablo, bir `.table` dosyasında kullanılabilecek tüm üst düzey parametreleri, veri tiplerini, varsayılan değerlerini ve geriye dönük uyumluluk (eski sistem) karşılıklarını listeler:

| Parametre | Tip | Varsayılan | Eski / Alternatif Adı | Açıklama |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `string` | `"Tablo"` | - | Tablonun insan tarafından okunabilir adı/başlığı. |
| `use_simple` | `0 / 1` | `0` | `simple` | `1` ise 255 bayta kadar serbest metin anahtarlarla (UUID, slug vb.) çalışan basit anahtar-değer modunu açar; `.inx` ikili indeksi üretilmez. |
| `record_index` | `0 / 1` | `0` | `readall` | `1` ise `.inx` birincil indeksini, `table_count`, `table_lastid` ve otomatik sayaç desteğini aktif eder. |
| `search_block` | `ARRAY` | `[]` | - | `.src` tam metin arama (inverted keyword) indeksine dahil edilecek blok numaraları. |
| `match_block` | `ARRAY` | `[]` | `fields` | `.fld` birebir eşleşme / filtrelenmiş okuma indeksine dahil edilecek blok numaraları. |
| `sort_block` | `ARRAY` | `[]` | - | `.srt` önceden sıralanmış binary ID indeksleri oluşturulacak bloklar (`[ 4, { blk => 10, type => 'num' } ]`). |
| `facet_block` | `ARRAY` | `[]` | `filter_block` | `.fac` çok boyutlu dinamik kategori/ürün filtreleme indeksine dahil edilecek bloklar. |
| `slug_block` | `ARRAY` | `[]` | `rwlink` | `.slg` otomatik iki yönlü URL slug üretimi için birleştirilecek bloklar. |
| `use_facet` | `0 / 1` | `0` | - | Tabloda facet sayım motorunu ve `field_fltkeys` / `facet_menu` altyapısını aktif eder. |
| `facet_rules` | `ARRAY` | `[]` | - | Facet menüsünde sadece belirli şarta uyan (örn: stokta olan) kayıtları saymak için filtre kuralları. |
| `use_junk` | `0 / 1` | `0` | - | Pasif/arşiv kayıtları ana tablodan ayırarak iki katmanlı (Hot/Cold) indeksleme sağlar. |
| `junk_rules` | `ARRAY` | `[]` | - | Hangi kayıtların otomatik olarak Junk katmanına (`.jinx`, `.jsrc`, `.jfld`) taşınacağını belirleyen kurallar. |
| `use_ramdisk` | `0 / 1 / 2 / 3` | `0` | - | `0`: Kapalı, `1`: RAM'de sadece indeksler, `2`: Tam RAM-Disk aynası (Dual-write), `3`: Uçucu RAM-disk (salt .db, indexesiz basit mod). |
| `ramdisk_ttl` | `integer` | `300` | - | Yalnızca `use_ramdisk => 3` modunda geçerli olan zaman aşımı süresi (saniye). |
| `table_dir` | `string` | `""` | - | Tablonun saklanacağı özel alt dizin (örn: `table_dir => 'siparis'`, `table_dir => ''` ile doğrudan kök dizin). |
| `keep_deleted` | `0 / 1` | `0` | `nodelete` | Silinen kayıtları yok etmek yerine `.del` arşiv dosyasında saklar (Soft-delete). |
| `log_owner` | `0 / 1` | `0` | `authority` | Kaydı ekleyen, düzenleyen ve silen kullanıcıları `.aut` denetim izinde saklar. |
| `use_alias` | `0 / 1` | `0` | `uselnk` | Mükerrer kayıtların silinip birleştirildiği tablolarda `.lnk` alias yönlendirme tablosunu aktif eder. |
| `use_counter` | `0 / 1` | `0` | `usecnt` | `.cnt` dosyasında kayıt okuma/görüntülenme sayaçlarını otomatik artırır. |
| `parent_table` | `string` | `""` | - | Dikey bölümlemede üst tablo adı. Bağlı tablo aynı ID'yi paylaşarak ana tabloyu hafif tutar. |
| `force` | `0 / 1` | `0` | - | `1` ise `insert_id` çağrısında kayıt zaten varsa hata vermek yerine üstüne yazar (Replace modu). |
| `min_char` | `integer` | `2` | `minchar` | Arama indeksine (`.src`) alınacak kelimeler için asgari karakter uzunluğu (1, 2 veya 3). |
| `stop_word` | `string` | `""` | `nextkey` | Arama indeksine dahil edilmeyecek durak kelimeler (örn: `"bu ve ile için de da"`). |
| `repeat_ids` | `integer` | `undef` | - | Tekrarlayan alt blokların ID listesinin otomatik toplanacağı hedef blok indeksi. |
| `repeat_start` | `integer` | `undef` | - | Dinamik değişken alt elemanların (sipariş kalemleri vb.) başladığı blok indeksi. |
| `view_block` | `ARRAY` | `[]` | - | Arayüz (Dbapp / CMS) listeleme ekranında gösterilecek öncelikli blok numaraları. |
| `use_menu` | `0 / 1` | `1` | - | Arayüz yönetim panelinde tablo için menü sekmesi gösterilip gösterilmeyeceği. |
| `no_transact` | `0 / 1` | `0` | - | `1` ise tablo transaction hata zincirinden ve otomatik rollback işleminden muaf tutulur. |

### 9.7 Blok (Alan) Nitelikleri, 8 Çekirdek Veri Tipi, Giriş Bileşenleri ve Doğrulama Referansı

Şema içindeki `blocks` dizisinde tanımlanan her bir alan bloğu şu nitelikleri alabilir:

#### 9.7.1 Temel Blok Nitelikleri

| Nitelik | Tip | Açıklama | Örnek |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Alanın programatik anahtar adı | `id => "email"` |
| `name` | `string` | Formlarda ve tablolarda gösterilecek etiket adı | `name => "E-Posta Adresi"` |
| `type` | `string` | Veri depolama, tip doğrulama ve indeksleme veri tipi | `type => "text"` |
| `input` | `string` | Form giriş bileşeni (UI) tipi | `input => "select"` |
| `valid` | `string` | Otomatik doğrulama kuralı | `valid => "not_null;email"` |
| `option` | `string` | Seçenek listesi (`değer:etiket` çiftleri) | `option => "1:Aktif,0:Pasif"` |
| `rdbm` | `string / HASH`| Başka tablodan veri çekme (`hedef_tablo;gösterilecek_blok`) | `rdbm => "catalog_category;2"` |
| `extend` | `HASH` | 1:1 dikey genişletme tablosu | `extend => { table => "catalog_price", join => "id" }` |

#### 9.7.2 Desteklenen 8 Çekirdek Veri Tipi (`type`)

AmberDB motoru, serileştirme (`db_encode`/`db_decode`), indeksleme ve sıralama katmanlarında **8 temel çekirdek veri tipi** kullanır:

| Veri Tipi (`type`) | Tanım | `enc_validate` (Yazma Anı) | `dec_validate` (Okuma Anı) | İndeks ve Sıralama Davranışı |
| :--- | :--- | :--- | :--- | :--- |
| **`auto_id`** | Otomatik artan ID (Blok 0) | ID format kontrolü ve sıralama | ID skaler dönüş | Birincil anahtar dizini (`.inx`) |
| **`text`** | Standart UTF-8 Metin | UTF-8 kaçış / metin doğrulaması | Dize (`$val // ''`) | `.src` ters indeksinde aranır, `.str` sözlüğü |
| **`num`** / **`number`** | Sayısal (Tamsayı / Ondalık / Boolean) | Sayısal doğrulama (`^[+-]?[0-9]+(?:\.[0-9]+)?$`), boşsa `0` | Sayı dönüşümü (`0 + $val`) | `.srt` sayısal (`<=>`) sıralama, `.fld` filtre |
| **`ascii`** | Salt ASCII karakterli metin | `to_ascii` ile ASCII normalizasyonu | ASCII metin | `.slg` slug haritası, `.srt` ASCII sıralama |
| **`date`** | Tarih ve Zaman | `auto_date` ise sistem tarihi atama | Tarih dizesi | `str2dateid` ile tarihsel kronolojik sıralama |
| **`array`** / **`repeat`** | Dizi / Tekrarlayan Satırlar | ARRAY ref veya `[split /,/]` | Perl `ARRAY` ref (`[]`) | Çoklu değer eşleşmesi (`field_fetch` multi-value) |
| **`hash`** | Sözlük / Nesne (HASH ref) | HASH ref kontrolü | Perl `HASH` ref (`{}`) | İç içe şemasız nesne saklama |
| **`binary`** | İkili Veri / Base64 | Ham binary bayt veya Base64 | Ham / Base64 skaler | Doğrudan dosya depolaması |

> [!NOTE]
> **Sayı ve Boolean Yönetimi:** `num` (veya `number`) tipi hem pozitif (`150`, `+25`), negatif (`-50`, `-12.75`), ondalıklı sayıları hem de `0 / 1` boolean bayraklarını yönetir. HTML formlarında işaretlenmeyen (`checkbox`) alanlar veya boş bırakılan sayısal girdiler `enc_validate` ve `dec_validate` tarafından otomatik olarak **`0`** olarak güvenle işlenir.

#### 9.7.3 Form Giriş Bileşenleri (`input`)

UI ve yönetim paneli katmanında form elemanının nasıl görüntüleneceğini belirler:

| Bileşen (`input`) | UI Elemanı | Açıklama |
| :--- | :--- | :--- |
| `text` | Metin Kutusu | Standart tek satırlık metin alanı `<input type="text">`. |
| `textarea` | Metin Alanı | Çok satırlı düz metin kutusu `<textarea>`. |
| `summernote` | Summernote | Zengin WYSIWYG görsel HTML editörü. |
| `select` | Açılır Menü | Tekli seçim kutusu `<select>`. |
| `checkbox` | Onay Kutusu | Çoklu seçim onay kutuları `<input type="checkbox">` (Boolean için `type => "num"`). |
| `radio` | Radyo Butonu | Tekli seçim radyo butonları `<input type="radio">`. |
| `file` | Dosya Yükleme | Dosya veya görsel yükleme bileşeni `<input type="file">`. |
| `hidden` | Gizli Alan | Gizli form elemanı `<input type="hidden">` (birincil ID için). |
| `email` | E-Posta Kutusu | HTML5 e-posta giriş alanı `<input type="email">`. |
| `ascii` | ASCII Alanı | Yalnızca ASCII karakterlere izin veren metin kutusu. |
| `number` | Sayı Kutusu | Sayısal giriş kutusu `<input type="number">`. |
| `date` | Tarih Seçici | Etkileşimli takvim tarih seçici `<input type="date">`. |
| `password` | Şifre Kutusu | Maskeli şifre giriş alanı `<input type="password">`. |
| `repeat` / `repeats` | Tekrarlayan Tablo | Dinamik alt satır ekleme/çıkarma formu (Sipariş kalemleri, fatura satırları). |
| `search_block` | Arama Kutusu | Arama destekli dinamik filtre giriş alanı. |
| `selectbyfind` | Arayarak Seç | İlişkili tablodan dinamik arama ile seçim bileşeni. |
| `selectbylist` | Listeden Seç | Listeden çoklu seçim bileşeni. |

#### 9.7.4 Tekrarlayan Alt Satır Blokları (`repeat_start` ve `repeat_ids`)

AmberDB, ilişkisel alt tablolara (child table) ve `JOIN` sorgularına ihtiyaç duymadan, ana kayıt içerisine gömülü tekrarlayan dinamik alt satırları (örn. sipariş kalemleri, fatura ürün satırları) yatay düzende doğrudan destekler:

- **Yatay Dizi Yapısı (`@record[15..$#record]`):** Tekrarlayan alt satırlar, sabit bloklardan sonra gelen her bir indeks (`$record[15]`, `$record[16]`, `$record[17]`, ...), bağımsız birer alt satır kaydıdır (örn: `[ 101, 'Kitap', 2, 150.00 ]`).
- **`repeat_start`**: Tekrarlayan dinamik blokların başladığı blok indeksini belirtir (örn. `repeat_start => 15`). Şemada 15. blok şablon olarak tanımlanır ve 15 ve sonraki tüm alanlar bu şablonun tip kurallarıyla doğrulanır.
- **`repeat_ids`**: Motor (`repeat_fields`), `@record[15..$#record]` dilimindeki tüm alt satırların birinci elemanını (sayısal ürün ID'si) otomatik olarak toplayıp virgülle birleştirir (`"101,102,103"`) ve `repeat_ids` (örn. 12) bloğuna yazar. Bu blok numarası `match_block` içine eklenerek alt kalem ID'leri üzerinden anında hızlı eşleşme ve arama sağlanır.

```perl
# Şema Tanımı Örneği (Sipariş Tablosu):
repeat_ids   => 12,    # Alt ürün ID'lerinin toplanacağı indeks bloğu (Örn: "101,102,103")
repeat_start => 15,    # 15. bloktan itibaren başlayan tekrarlayan satırlar
blocks => [
    { id => "id",         name => "Sipariş No",    type => "auto_id", input => "hidden" },  # 0
    # ... sabit sipariş üst bilgileri (tarih, müşteri, adres vb.) ...
    { id => "prod_ids",   name => "Ürün Listesi",  type => "text",    input => "hidden" },  # 12 (repeat_ids hedefi)
    # ...
    { id => "products",   name => "Ürün Kalemleri",type => "repeat",  input => "repeats" }, # 15 (repeat_start şablonu)
];

# Veri Satırı Yapısı (Kayıt Örneği):
# $record[0]  = 1001;               # Sipariş ID (Sayısal anahtar)
# $record[12] = "101,102,103";      # Motor tarafından repeat_fields ile otomatik üretilir
# $record[15] = [ 101, 'Kitap', 2, '150.00' ]; # 1. Ürün
# $record[16] = [ 102, 'Defter', 1, '85.00' ];  # 2. Ürün
# $record[17] = [ 103, 'Kalem', 5, '20.00' ];   # 3. Ürün
```

#### 9.7.5 Otomatik Doğrulama Kuralları (`valid`)

Birden fazla doğrulama kuralı noktalı virgül (`;`) ile zincirlenebilir (örn: `valid => "not_null;email"`):

| Doğrulama Kuralı (`valid`) | Tanım | Kontrol ve Davranış |
| :--- | :--- | :--- |
| `none` | Doğrulama Yok | Herhangi bir kural uygulanmaz (varsayılan). |
| `not_null` | Boş Olamaz | Alanın boş (`undef` veya `""`) geçilmesini engeller. |
| `unique` | Benzersiz | Değerin tabloda başka hiçbir kayıtta bulunmadığını doğrular. |
| `email` | E-posta | Geçerli bir RFC e-posta deseni kontrolü yapar. |
| `telefon` | Telefon | Geçerli sabit/GSM telefon numarası formatı kontrolü yapar. |
| `ascii` | ASCII | Değerin yalnızca ASCII karakterler içermesini zorunlu kılar. |
| `numeric` | Sayısal | Değerin geçerli bir sayı olmasını zorunlu kılar. |
| `regex` | Regex | Özel tanımlı düzenli ifade desenine uyumu denetler. |
| `auto_num` | Otomatik Sayı | Değeri otomatik artan sayı olarak üretir. |
| `auto_pass` | Otomatik Şifre | Rastgele güvenli şifre üretir ve tuzlu hash olarak kaydeder. |
| `auto_date` | Otomatik Tarih | Değer boşsa o anki sistem tarih/zaman damgasını otomatik atar. |
| `auto_str` | Hazır Metin | Önceden tanımlı şablon metnini otomatik uygular. |

#### 9.7.6 Benzersizlik ve Dize/ID Sözlük İndeksi (`.unq`)

AmberDB'de `.unq` (Unique) dizini, hem **tekillik güvencesini** hem de **ilişkisel metin $\leftrightarrow$ sayısal ID dönüşümünü** $O(1)$ disk arama hızında yöneten çift yönlü bir sözlük dosyasıdır (`${tablo}_${blok}.unq`):

1. **İsimlendirme Netliği:** `.srt` (Sort / Sıralama) ile eski `.str` (String) karışıklığını önlemek için tekillik ve sözlük dosyaları `.unq` uzantısıyla tutulur.
2. **$O(1)$ Tekillik Denetimi (`valid => "unique"`):**
   - Bir alanda `valid => "unique"` tanımlandığında (örn. `username`, `email`, `barkod`), motor `insert_id` veya `update_id` anında `.unq` dosyasından `s:$değer` anahtarını kontrol eder.
   - Değer başka bir kayda aitse işlem anında durdurulur ve hata fırlatılır.
   - Başarılı ekleme ve güncellemelerde çift yönlü anahtarlar (`s:$değer => $rid` ve `n:$rid => $değer`) kaydedilir. Kayıt silindiğinde bu anahtarlar `.unq` dosyasından temizlenir.
3. **RDBM ve `match_block` Metin $\leftrightarrow$ Sayısal ID Dönüşümü:**
   - İlişkisel bir alana (`rdbm => "catalog_brand;1"`) veya metin filtre bloğuna string geldiğinde (örn. `"Can Yayınları"`), motor hedef tablonun `catalog_brand_1.unq` dosyasından `s:Can Yayınları` anahtarını sorgular.
   - Kayıtlıysa mevcut sayısal ID'yi alır; kayıtlı değilse yeni otomatik ID üreterek `.unq` sözlüğüne ve hedef tabloya ekler.
   - Ters indeks dosyası (`.fld`) içerisine **daima saf sayısal ID** yazılarak indekslerin hafif ve hızlı taranması sağlanır.

---

### 9.8 CRUD İşlemlerinde Tip Doğrulama ve Dönüşümü (`enc_validate` & `dec_validate`)

AmberDB, veri tutarlılığını sağlamak için iki yönlü şema doğrulama ve dönüşüm mekanizması uygular:

1. **Yazma Anında Doğrulama (`enc_validate`):**
   - `insert_id`, `update_id`, `insert_list` ve `update_list` metotlarında veri diske ve ikincil indekslere yazılmadan **hemen önce** çalışır.
   - `num` alanları için sayısal temizlik yapılır, boşluklar ayıklanır ve boş değerlere `0` atanır.
   - `ascii` alanlarında Türkçe ve özel karakterler `to_ascii` ile normalize edilir.
   - `valid => "auto_date"` kuralı olan boş tarih alanlarına otomatik güncel sistem tarihi atanır.
   - `array` alanlarında virgüllü dizeler otomatik `ARRAY` referansına (`[ ... ]`), `hash` alanları `HASH` referansına (`{ ... }`) dönüştürülür.

2. **Okuma Anında Dönüşüm (`dec_validate`):**
   - `read_id`, `read_list` ve `read_all` metotlarında diskten `db_decode` ile çözülen alanlar kullanıcıya dönmeden **hemen önce** çalışır.
   - `num` alanları Perl'de `0 + $val` yapılarak sayısal skaler olarak döndürülür (`undef` uyarıları önlenir).
   - `array` alanları boşsa `[]`, `hash` alanları `{}` olarak garanti edilir.

3. **Simple Mod Uyumu:**
   - Şemasız (`simple => 1`) modda veya `blocks` tanımlanmamış tablolarda `enc_validate` ve `dec_validate` hiçbir ek döngü çalıştırmadan veriyi doğrudan döndürür (sıfır ek maliyet).

### 9.9 Çalışma Zamanında Dinamik Şema Manipülasyonu (`table_attr`)

AmberDB şemaları statik değildir. Şema dosyalarını diskte değiştirmeye veya migration çalıştırmaya gerek kalmadan, uygulama çalışma zamanında (runtime) tablo ayarlarını bellek üzerinde anlık olarak güncelleyebilir:

```perl
# Senaryo 1: Barkod POS cihazı veya hızlı kasa ekranı için arama kapsamını daraltma
# Tabloda normalde 2 (firma), 3 (yazar), 4 (başlık), 9 (barkod) aranırken,
# anlık olarak sadece Başlık (4) ve Barkod (9) bloklarında arama yaptırma:
$adb->table_attr("catalog_product", { search_block => [ 4, 9 ] });

# Senaryo 2: Silinecek kayıtların arşivlenmesi için şemadaki keep_deleted alanını aktif yapma
$adb->table_attr("catalog_product", { keep_deleted => 1 });

# Senaryo 3: Toplu raporlama sırasında önbelleği geçici olarak devre dışı bırakma
$adb->table_attr("catalog_product", { use_ramdisk => 0 });
```

### 9.10 Dinamik Genişleyen Tablolar ve Tekrarlayan Bloklar (`repeat_ids` & `repeat_start`)

AmberDB, sabit sütun sınırlarını aşarak tek bir ana döküman kaydının sonuna değişken sayıda alt eleman (sipariş kalemleri vb.) eklenmesine olanak tanır.

#### 9.10.1 Şema Yapılandırması (`order_active.table` Örneği)
```perl
# dbstore/schema/order_active.table
{
    name         => "Aktif Siparişler",
    record_index => 1,
    match_block  => [ 1, 2, 12, 14 ],
    keep_deleted => 1,
    log_owner    => 1,
    repeat_ids   => 12,
    repeat_start => 15,

    blocks => [
        { id => "id",                name => "ID",                   type => "auto_id" }, # 0
        { id => "member_id",         name => "Üye ID",               type => "text" },    # 1
        { id => "invoice_no",        name => "Fatura No",            type => "text" },    # 2
        { id => "amounts",           name => "Tutarlar",             type => "array" },   # 3
        { id => "timestamps",        name => "Tarihler",             type => "array" },   # 4
        { id => "status",            name => "Statü",                type => "option" },  # 5
        { id => "session_id",        name => "Session ID",           type => "text" },    # 6
        { id => "delivery_address",  name => "Teslim Adresi",        type => "array" },   # 7
        { id => "invoice_address",   name => "Fatura Adresi",        type => "array" },   # 8
        { id => "cargo",             name => "Kargo Bilgileri",      type => "array" },   # 9
        { id => "payment_info",      name => "Ödeme Tipi",           type => "array" },   # 10
        { id => "credit_card_info",  name => "Kredi Kartı Bilgileri",type => "array" },   # 11
        { id => "product_ids",       name => "Ürün Döngüsü",         type => "text" },    # 12 (repeat_ids)
        { id => "member_notes",      name => "Üye Notları",          type => "array" },   # 13
        { id => "gift_products",     name => "Hediye Ürünler",       type => "text" },    # 14
        { id => "products",          name => "Ürün Kalemleri",       type => "repeat" },  # 15 (repeat_start)
    ]
}
```

#### 9.10.2 Çalışma Mantığı ve Otomatik İndeksleme (`repeat_fields`)
Her `insert_id`, `update_id`, `insert_list` veya `update_list` çağrısında motor, `repeat_start` (15) ve sonrasındaki tüm değişken blokları otomatik olarak işler:
1. Her ürün/kalem bloğunun (dizi ise ilk elemanını `$_->[0]`, metin ise kendisini) çeker.
2. Bu ID'leri virgülle birleştirip (`"101,102,103"`) otomatik olarak `repeat_ids` (12) bloğuna yazar (geliştiricinin bu alanı manuel doldurmasına gerek yoktur).
3. Blok 12 şemada `match_block` içinde tanımlandığı için, motor `set_fieldlist` ile bu ID'lerin her birini `order_active.fld` eşleştirme indeksine (`"12:$id"` anahtarıyla) kaydeder.

> [!NOTE]
> **Basit Modda (Şemasız) Tekrarlayan Bloklar:**  
> Tekrarlayan blokların otomatik olarak derlenip `repeat_ids` özet alanına virgülle yazılması (`repeat_fields`), şema dosyasındaki `repeat_start` ve `repeat_ids` tanımlarına bağlıdır. Şemasız basit modda (`simple => 1`) şema yüklenmediği için bu otomatik derleme yapılmaz; kayıtlar ham Perl listesi olarak diske kaydedilir. Eğer basit modda çalışan bir tabloda bu tür bir özet alanına ihtiyaç varsa, bu alanın geliştirici tarafından manuel olarak doldurulması gerekir.

#### 9.10.3 Kodlama ve Sorgulama Örneği
```perl
# 1. Sipariş Ekleme (15. bloktan itibaren istenen sayıda ürün kalemi verilir)
my @siparis = (
    "1001",              # [1] Üye ID
    "FAT-2026-001",      # [2] Fatura No
    "69699.00",          # [3] Tutar
    "2026-08-24",        # [4] Tarih
    "1",                 # [5] Statü (Sipariş Alındı)
    "SESS12345",         # [6] Session
    "Teslimat Adresi",   # [7] Teslimat
    "Fatura Adresi",     # [8] Fatura
    "Kargo ID",          # [9] Kargo ID
    "Kredi Kartı",       # [10] Ödeme
    "**** 1234",         # [11] Kart
    "",                  # [12] product_ids (Boş bırakılır; motor "101,102,103" olarak doldurur)
    "Zil bozuk",         # [13] Notlar
    "Hediye Paketi",     # [14] Hediye
    [ "101", "MacBook Pro M3", 1, 64999.00 ], # [15] 1. Ürün (repeat_start)
    [ "102", "Magic Mouse",    2,  3500.00 ], # [16] 2. Ürün
    [ "103", "USB-C Adaptör",  1,  1200.00 ], # [17] 3. Ürün
);

my $siparis_id = $adb->insert_id("order_active", undef, @siparis);

# 2. 101 ürününü içeren TÜM aktif siparişleri doğrudan tekil anahtar aramasıyla getirme:
my ($toplam, @siparisler) = $adb->field_fetch("order_active", 12, "101", { offset => 0, limit => 20 });
print "101 ürününü içeren $toplam adet aktif sipariş bulundu.\n";
```

### 9.11 Dikey Bölümleme (Vertical Partitioning) ve Bağlı Tablolar (`parent_table`)

Çok büyük metin alanları (örneğin uzun HTML ürün açıklamaları, zengin döküman gövdeleri veya detaylı teknik özellikler) içeren senaryolarda, ana tablonun kayıt boyutunu küçük tutmak okuma ve arama hızını maksimize eder. AmberDB'de bu durum **Dikey Bölümleme (Vertical Partitioning)** ile çözülür:

* **Ana Tablo (`catalog_product`):** Sadece listeleme, arama ve filtreleme için gerekli hafif alanları (Başlık, Fiyat, Kategori, Marka, Statü) saklar.
* **Detay Tablosu (`catalog_descript`):** Şemasında `parent_table => "catalog_product"` tanımlanır ve ana tablodaki kayıtla birebir aynı ID'yi (`rid`) paylaşır.

```perl
# dbstore/schema/catalog_descript.table
{
    name         => "Ürün Açıklamaları",
    parent_table => "catalog_product",
    blocks => [
        { id => "id",          name => "ID",          type => "auto_id" }, # 0 (Ürün ID ile aynı)
        { id => "description", name => "HTML İçerik", type => "text" },    # 1
    ]
}
```

Bu sayede:
1. Kategori listeleri ve arama sonuçları yüklenirken megabaytlarca HTML metin belleğe yüklenmez.
2. Yalnızca kullanıcı ilgili ürünün detay sayfasına girdiğinde `$adb->read_id("catalog_descript", $product_id)` çağrılarak içerik diskten tekil anahtar okumasıyla anında getirilir.

---

## 10. Veritabanı Grup Yapısı (.dbase)

Birden fazla ilişkili tabloyu mantıksal gruplar altında toplamak ve yıl/şube bazlı otomatik bölümleme (partitioning) uygulamak için `dbstore/schema/<grup>.dbase` dosyası kullanılır:

```perl
# dbstore/schema/catalog.dbase
{
    name    => "Katalog Veritabanı",
    type    => 0,                           # 0: Sistem tablosu, 1: Dinamik tablo
    year    => 0,                           # 1: Tablolar yıllık klasörlere ayrılır (2026/fatura.db gibi)
    section => 0,                           # 1: Tablolar şube bazlı klasörlere ayrılır
};
```

---

## 11. Akıllı Sıcak / Soğuk İndeksleme (Junk Sistemi)

E-ticaret sitelerinde zamanla yüz binlerce ürünün satışı biter, stoğu tükenir veya bazı tedarikçi firmalarla çalışma durdurulur. Eski ve pasif ürünler silinemez (çünkü geçmiş siparişlerde, faturalarda ve müşteri panellerinde görünmelidir), fakat vitrin aramalarını ve kategori sayfalarını yavaşlatmamalıdır. Bütün bunlar veritabanı motoru seviyesinde ve otomatik yürütülür.

**Junk Sistemi**, verilerinizi hiçbir kayıp olmadan **Aktif (Vitrin)** ve **Junk (Arşiv)** olarak ikiye ayıran, tamamen otomatik çalışan bir performans kalkanıdır.

### 11.1 Sağladığı Faydalar ve Özellikler

* **Vitrin ve Arama Her Zaman Hızlı Kalır:** Müşterileriniz arama yaptığında veya kategorileri gezerken yüz binlerce eski/tükenmiş ürün taranmaz; yalnızca aktif satıştaki ürünler ışık hızında listelenir.
* **Akıllı Sıralama (Önce Aktifler, Arkada Eski Ürünler):** Mağaza içi aramada bir müşteri eski bir kitabın/ürünün adını ararsa ürün bulunur; fakat aktif ürünler en başta, satışı bitmiş ürünler ise en arkada görünür.
* **Sıfır Manuel İş Yükü (Tam Otomasyon):** Bir ürünün stoğu bittiğinde ya da tedarikçi firma pasife alındığında hiçbir taşıma kodu yazmanıza gerek yoktur; sistem şema kurallarına göre kaydı kendiliğinden vitrinden arşive (veya tekrar satışa açıldığında vitrine) taşır.
* **Yönetim ve Fatura Panellerinde Tam Erişim:** Sipariş, fatura veya yönetim ekranlarında arama yaparken tek bir parametreyle (`jnktype => "AB"` veya `"B"`) geçmiş tüm arşiv kayıtlarına anında ulaşabilirsiniz.

### 11.2 Şemada Tanımlama (`.table`)

Tablonuzda `use_junk => 1` ve hangi durumların arşiv/junk sayılacağını belirten `junk_rules` kurallarını tanımlayın:

```perl
# dbstore/schema/catalog_product.table
{
    name         => "Ürünler",
    record_index => 1,
    search_block => [ 4, 5 ],
    match_block  => [ 1, 2, 3 ],

    # Akıllı arşiv/junk indekslemeyi açar
    use_junk     => 1,
    
    # Hangi kayıtların "Junk / Arşiv" kabul edileceğini belirleyin:
    junk_rules   => [
        # 1. Ürünün kendi satış durumu (Blok 20) 1 (Satışta) değilse -> ARŞİV
        [ 20, "ne", 1 ],

        # 2. İlişkili Tedarikçi Kuralı: Ürünün üretici firması (Blok 2) pasife alınmışsa -> ARŞİV  (catalog_producer tablosundaki firmanın 14. blokunun durumuna bakar)
        [ "2->14", "ne", 1 ],
    ],
}
```

### 11.3 Kullanım Senaryoları ve Kod Örnekleri

Sorgularınızda `jnktype` parametresini kullanarak hedefinize en uygun modu seçebilirsiniz:

#### A. Vitrin ve Kategori Sayfaları (Sadece Aktif Ürünler - Mod `A`)
Vitrin listelemelerinde ve filtrelerde pasif ürünlerin hiç görünmemesi için `jnktype => "A"` kullanılır:

```perl
# Kategori sayfasında sadece satıştaki ürünleri listeleme:
my @vitrin_urunleri = $adb->read_all("catalog_product", { jnktype => "A" });

# Müşteri araması:
my ($adet, @sonuclar) = $adb->search_table("catalog_product", "roman", { offset => $start, limit => $limit, jnktype => "A" });
```

#### B. Genel Mağaza Araması (Önce Aktifler, Sonra Eski Ürünler - Mod `AB`)
Müşteri eski bir ürünü arasa bile bulabilsin, ancak öncelik her zaman satıştaki ürünlerde olsun istendiğinde:

```perl
# Aktif ürünler en başta, satışı bitmişler arkada listelenir:
my ($adet, @sonuclar) = $adb->search_table("catalog_product", "nutuk", { offset => $start, limit => $limit, jnktype => "AB" });
```

#### C. Yönetim Paneli ve Raporlama (Sadece Arşiv / Pasifler - Mod `B`)
Junk kayıtları ana tablodan ayırmaz. Sadece indexleri ayırır. Stok dışı, satışı durdurulmuş ve junk olarak işaretlenmiş olan ürünleri incelemek için:

```perl
# Satışı kapatılmış ürünleri listeleme:
my @just_junk = $adb->read_all("catalog_product", { jnktype => "B" });
```

#### D. Sipariş ve Fatura Konsolu (Tüm Kayıtlar)
Satış faturası konsolunda sadece aktif ürünler istendiği için jnktype => "A" parametresi gönderilebilir. Varsayılan olarak "AB" çalışır ve aktif+junk sıralamasına göre çalışması için parametresiz gönderilmesi yeterlidir:

```perl
# ID ile ürün okuma (junkta veya aktifte olması fark etmeksizin doğrudan okunur):
my @urun = $adb->read_id("catalog_product", $eski_urun_id);
```

### 11.4 Otomatik Durum Değişimi
Ürünü güncellediğinizde sistem kuralları anında değerlendirir:
* Ürünün `sales_status` değerini `0` yaptığınızda veya üretici firmasını pasife aldığınızda ürün **kendiliğinden aktif indexinden junk indexine geçer**.
* Ürün stoğa girip tekrar `1` yapıldığında **kendiliğinden junk indexinden aktif indexine geçer**.
* Geliştirici olarak ekstra hiçbir senkronizasyon kodu yazmanız gerekmez. Sadece şemadaki junk kurallarını doğru giriniz.

---

## 12. Otomatik Slug Kaydı (URL Slug) Yönetimi

Şemada örneğin marka (2) ve ürün adı (4) blocklarını kullanmak için `slug_block => [2, 4]` tanımlandığında, kayıt eklendiğinde veya güncellendiğinde slug otomatik oluşturulur ve çakışmalar yönetilir:

```perl
# ID'den Slug alma
my $slug_harita = $adb->get_slug("catalog_product", 0, 5001);
my $slug = $slug_harita->{5001};
print "Ürün Linki: /urun/$slug\n"; # Çıktı: /urun/acme-kablosuz-kulaklik

# Slug Değerinden Kayıt ID'sini bulma (Yönlendirici / Router için)
my $id_harita = $adb->get_slug("catalog_product", 1, "acme-kablosuz-kulaklik");
my $id = $id_harita->{"acme-kablosuz-kulaklik"};
print "Gelen istek Ürün ID'si: $id\n";
```

### 12.1 Otomatik Çakışma Çözümleme (Collision Suffixes)
Aynı başlığa sahip birden fazla kayıt eklendiğinde (örneğin "Kablosuz Kulaklık"), AmberDB otomatik olarak benzersiz artan sayısal sonekler (`_2`, `_3`) ekleyerek URL çakışmalarını şeffaf biçimde çözer:
* 1. Kayıt: `kablosuz-kulaklik`
* 2. Kayıt: `kablosuz-kulaklik_2`
* 3. Kayıt: `kablosuz-kulaklik_3`

> **İlişkisel Slug Çözümleme (`rdbm`):** Eğer slug bloğunda ilişkisel bir alan varsa (örn. Kategori ID'si), motor bağlı tablodan kategori adını otomatik okuyarak `/elektronik/acme-kulaklik` şeklinde anlamlı slug üretir.

---

## 13. Şeffaf Fiziksel RAM-Disk Hızlandırması ve Bellek İçi Depolama

AmberDB, yerel ve şeffaf bir fiziksel RAM-Disk hızlandırma motoruna sahiptir (Linux `tmpfs`, macOS `APFS RAM-Disk` / `hdiutil` veya Windows `ImDisk`). Veritabanı tablolarını ve indeks dosyalarını doğrudan bellek tabanlı bir dosya sistemine aynalayarak, harici bir önbellek sunucusuna veya ağ soketine ihtiyaç duymadan mikrosaniye düzeyinde okuma başarımı sunar; aynı zamanda kalıcı disk güvenliğini korur.

```text
                               ┌─────────────────────────────────────────────────────────────┐
                               │ dbstore/ramdisk/ (Linux tmpfs, macOS APFS, Windows ImDisk)  │
                               ├──────────────────────────┬──────────────────────────────────┤
                               │ ramdisk/${tablo}.db      │ ramdisk/${tablo}.inx             │
                               │ (Yerel Berkeley DB)      │ (Yerel 8-Byte Binary İndeksler)  │
                               └──────────────────────────┴──────────────────────────────────┘
```

### 13.1 RAM-Disk Hızlandırması Nedir?

Ağ tabanlı önbellek sistemlerinin (Redis veya Memcached gibi) aksine, AmberDB'nin RAM-disk motoru doğrudan işletim sistemi dosya sistemi blok seviyesinde çalışır. Tabloları ve indeksleri RAM üzerinde ayrılmış bir bağlama noktasına (`dbstore/ramdisk/` veya Windows `R:\amberdb`, macOS `/Volumes/AmberDB_RAM`) yönlendirir.

**Temel Mimari Farklar:**
* **Harici Sunucu ve Süreç Yok:** Ayrı bir Redis/Memcached sunucusu kurma, konfigüre etme, izleme ve ağ portu açma gereksinimi yoktur.
* **Sıfır Ağ Gecikmesi:** Erişimler TCP soketleri veya IPC yerine doğrudan yerel dosya sistemi çağrılarıyla (`pread`, `pwrite`, `mmap`) gerçekleşir.
* **Birebir Yerel Veri Formatı:** Kalıcı diskteki `.db` ve `.inx` dosyalarıyla aynı ikili (binary) formatta tutulur; ek serileştirme/deserileştirme dönüşüm maliyeti oluşmaz.
* **Süreçler Arası Paylaşımlı Bellek:** Tüm eşzamanlı Perl süreçleri, Apache/FastCGI iş parçacıkları ve arka plan komutları (cron) tarafından doğrudan ortak kullanılır.

### 13.2 Nasıl Çalışır?

* **Yerel Dosya Formatı Aynalama:** AmberDB tüm tablo dosyalarını kendi özgün uzantılarıyla (`.db`, `.inx`, `.fld`, `.src`, `.fac`, `.unq`, `.slg`) RAM-disk üzerinde saklar. Tescilli veya farklı bir `.cache` dosya formatı kullanılmaz.
* **Eşzamanlı Çift Yazma (Dual-Write):** Bir kayıt eklendiğinde veya güncellendiğinde, motor hem kalıcı diske hem de RAM-diske eşzamanlı olarak yazar. Okumalar doğrudan bellek hızında RAM-diskten karşılanırken, veri dayanıklılığı ve sürekliliği kalıcı diskte korunur.
* **ACID İşlem Güvenliği:** RAM-disk katmanındaki tüm yazma işlemleri AmberDB'nin disk tabanlı WAL geri alma günlükleri (`.txn`) ve Strict 2PL kilitleri ile korunur. Bir işlem iptal edilirse (rollback), her iki katmandaki değişiklikler LIFO sırasıyla geri alınır.
* **Otomatik Bağlantı Denetimi ve Kesintisiz Fallback:** Motor, RAM-disk dosyalarına erişmeden önce dosya sisteminin bağlı (`mounted`) olup olmadığını denetler. RAM-disk bağlı değilse, AmberDB hata üretmeden kesintisiz olarak standart kalıcı disk üzerinden çalışmaya devam eder.

### 13.3 RAM-Disk ile L1 Süreç İçi Önbellek Karşılaştırması

AmberDB bünyesinde iki farklı bellek katmanı bulunur ve amaçları birbirinden ayrılmıştır:

| Özellik | Fiziksel RAM-Disk Katmanı (`use_ramdisk`) | L1 Süreç İçi Önbellek (`get_cache` / `set_cache`) |
| :--- | :--- | :--- |
| **Kapsam** | Süreçler arası ortak, sistem çapında paylaşımlı | Tek bir Perl süreci / iş parçacığı belleği |
| **Depolama Motoru** | Yerel `DB_File` ve ikili indeks dosyaları | Süreç içi Perl hash referansları |
| **Kalıcılık** | Kalıcı disk ile senkronize (Seviye 1 & 2) | Yalnızca süreç çalışma süresi boyunca |
| **Metotlar** | `insert_id`, `read_id`, `search_table`, `update_id` | `$adb->get_cache()`, `$adb->set_cache()` |

```perl
# L1 Süreç İçi Önbellek Kullanımı
$adb->set_cache("panel", "aktif_kullanicilar", @kullanici_idleri);
my @kullanicilar = $adb->get_cache("panel", "aktif_kullanicilar");
$adb->set_cache("panel", "aktif_kullanicilar", undef); # Önbelleği temizle
```

### 13.4 RAM-Disk Hızlandırma Seviyeleri (`use_ramdisk`)

Tablolar şema dosyasında veya dinamik olarak `table_attr()` ile hızlandırma seviyesine bağlanır:

* **`0` (Kapalı):** Standart kalıcı disk erişimi.
* **`1` (Hibrit İndeks Hızlandırması):** Yalnızca ikincil indeks dosyaları (`.inx`, `.src`, `.fld`, `.fac`, `.unq`, `.slg`) RAM-diske alınır. Ana veri (`.db`) kalıcı diskte saklanır. Arama, filtreleme ve sıralama bellek hızında çalışırken RAM tüketimi minimum düzeyde tutulur.
* **`2` (Tam Tablo RAM Aynası - Dual-Write):** Tablo verileri (`.db`) ve tüm indeks dosyaları RAM-diske aynalanır. Okumalar doğrudan RAM'den döner; yazma anında kalıcı diske ve RAM-diske eşzamanlı çift yazma yapılır.
* **`3` (Uçucu RAM-Disk - Pure Volatile Key-Value):** Veri **yalnızca RAM-disk üzerinde** `.db` dosyasında tutulur. Fiziksel diskte hiçbir dosya ve indeks oluşturulmaz (`use_simple => 1`). Oturumlar (session), sepetler ve geçici tokenlar için tasarlanmıştır. Kayan zaman aşımını (`ramdisk_ttl`) destekler.

### 13.5 Şeffaf Yönetim: `use_ramdisk` Kullanımı

RAM-Disk katmanını yönetmek için özel okuma/yazma fonksiyonları çağırmanıza gerek yoktur; her şey arka planda otomatik yürütülür. Yönetim bütünüyle `use_ramdisk` seçeneği üzerinden sağlanır:

#### 1. Global Yapılandırma (Tüm Tablolar İçin Varsayılan)
Tüm veritabanı genelinde indeks veya tam tablo hızlandırmasını tek seferde etkinleştirebilirsiniz:

```perl
# Kurulum anında tüm tablolara Seviye 1 (Hibrit İndeks) uygulama
my $adb = AmberDB->new(
    cfg => { use_ramdisk => 1 },
    path => { dbase_dir => "/var/data/amberdb" }
);

# Çalışma anında global seviyeyi değiştirme
$adb->config(use_ramdisk => 2); # Tüm tabloları Seviye 2 (Tam Ayna) yap
```

#### 2. Tablo Bazında Esnek Yapılandırma ve İstisnalar
Her tablo için `.table` şema dosyasından veya çalışma anında `table_attr()` ile bağımsız hızlandırma seviyesi belirlenebilir:

```perl
# Yüksek trafikli kategoriler tablosunu Tam RAM Aynasına al
$adb->table_attr("catalog_category", use_ramdisk => 2);

# Seyrek erişilen bir tabloyu global RAM-disk kapsamı dışına çıkar (diskte tut)
$adb->table_attr("audit_archive", use_ramdisk => 0);
```

#### 3. Standart CRUD Çağrılarıyla Doğrudan Kullanım
Geliştirici yalnızca standart AmberDB metotlarını kullanır. Motor, arka planda RAM-disk kopyalamasını, bellekten okumayı ve diske çift yazmayı şeffaf olarak yürütür:

```perl
# Okuma: use_ramdisk 1 veya 2 tanımlıysa sorgular doğrudan RAM üzerinden mikrosaniyede döner
my @urun = $adb->read_id("catalog_product", 101);
my ($adet, @sonuclar) = $adb->search_table("catalog_product", "kablosuz kulaklik");

# Yazma: Motor otomatik olarak hem kalıcı diske hem RAM-diske yazar (Dual-Write)
$adb->insert_id("catalog_product", 0, @yeni_urun);
$adb->update_id("catalog_product", 101, @guncel_veri);
```

### 13.6 RAM-Disk Yönetimi (`amberdb_setup.pl`)

AmberDB, tüm işletim sistemlerinde (Linux, macOS, Windows) RAM-disk yapılandırmasını ve bakımını `amberdb_setup.pl` üzerinden tek merkezden yürütür:

- **RAM-Disk Başlatma (Mount):** `perl bin/amberdb_setup.pl --action=ramdisk --start --size 512M`
- **Durum Denetimi (Status):** `perl bin/amberdb_setup.pl --action=ramdisk --status`
- **RAM-Disk Sonlandırma (Stop):** `perl bin/amberdb_setup.pl --action=ramdisk --stop`
- **Tam Altyapı Kurulumu (Install):** `perl bin/amberdb_setup.pl --action=install --user=eticaretim --size 256M --cron`

### 13.7 Uçucu Tablolar ve Kayan TTL Zaman Aşımı (`ramdisk_ttl`)

`ramdisk_ttl` parametresi **yalnızca `use_ramdisk => 3` (uçucu RAM-disk)** modunda çalışan tablolar için geçerlidir (varsayılan: 300 saniye). Süresi dolan kayıtlar erişim anında otomatik olarak temizlenir:

```perl
# Session tablosunu uçucu RAM-disk ve 30 dakika TTL ile ayarlama
$adb->table_attr("session", {
    use_ramdisk => 3,
    ramdisk_ttl => 1800,      # 30 dakika kayan TTL (yalnızca Tier 3 için geçerli)
    table_dir   => 'session'  # ramdisk/session/ altında saklar
});
```

### 13.8 Özel Tablo Dizini (`table_dir`)

Tablolar varsayılan olarak `tables/` dizininde saklanır. `table_dir` parametresi ile istenilen alt klasöre yönlendirilebilir:

```perl
# Sipariş tablosunu 'siparis' dizinine yerleştirme:
# Fiziksel: dbstore/siparis/siparis_tablosu.db
# RAM-Disk: ramdisk/siparis/siparis_tablosu.db
$adb->table_attr("siparis_tablosu", table_dir => 'siparis');

# Kök dizine yerleştirme (tables/ önekini ezme):
$adb->table_attr("kok_tablosu", table_dir => '');
```

### 13.9 Disk Tabanlı Geçici Buffer

Büyük veri aktarımlarında veya raporlama işlemlerinde RAM dışı geçici disk buffer'ı kullanılır:

```perl
$adb->buffer_write("rapor_gecici", @buyuk_veri);
my @veri = $adb->buffer_read("rapor_gecici");
$adb->buffer_delete("rapor_gecici");
```

---

## 14. Yapılandırma ve Deterministik Bayrak Yönetimi (`config`)

AmberDB'nin çalışma modunu değiştirmek ve yapılandırma bayraklarını güvenli bir şekilde yönetmek için `$adb->config()` metodu kullanılır:

```perl
# Toplu veya tekli yapılandırma ataması (Önerilen)
$adb->config(
    no_write     => 1,            # Bakım modu: Tüm yazma işlemlerini engelle
    no_backup    => 1,            # Tüm tablolar için günlük CSV denetim yedeklerini kapat
    simple       => 1,            # İndekssiz doğrudan yazım modu (İkincil indeksler devre dışı bırakılır)
    keys_only    => 1,            # read_all çağrılarında sadece ID'leri döndür
    ramdisk_size => '1024M',      # RAM-Disk (tmpfs/APFS/ImDisk) boyutu (Varsayılan: 512M)
);

# Tekil okuma:
my $no_write = $adb->config('no_write');

# Toplu okuma (Güvenli kopya döner):
my $cfg = $adb->config();
```

---

## 15. Veri Yapıları, Düşük Seviyeli Tablo ve Akış İşlemleri

AmberDB, standart CRUD katmanının altında doğrudan `DB_File` C seviyesi optimizasyonlarına ve ham akış işlemlerine erişim sunar:

### 15.1 Veri Yapıları ve Serialization (`db_encode`, `db_decode`)

AmberDB, karmaşık Perl yapılarını özel ayıraçlarla yüksek hızda dizgeleştirir (serialize eder):

```perl
# Encode: Perl Verisi → String
my $str = $adb->db_encode("Metin", [ 1, 2, 3 ], { key => "val" });

# Decode: String → Perl Verisi
my ($metin, $dizi_ref, $hash_ref) = $adb->db_decode($str);
```

### 15.2 Düşük Seviyeli Tablo ve Akış Yönetimi (`table_read`, `table_write`, `table_close`)

Büyük veri aktarımlarında veya özel toplu işlerde dosya oturumu açıp kapatmak için kullanılır:

```perl
my $tablo_yolu = $adb->table_path("catalog_product") . ".db";

# 1. Yazma/Okuma Modunda Tablo Açma ve Kilit Uygulama (flock LOCK_EX)
my $db_obj = $adb->table_write($tablo_yolu);

# 2. Salt-Okunur Modda Tablo Açma (O_RDONLY)
my $db_ro  = $adb->table_read($tablo_yolu);

# 3. Tabloyu Senkronize Etme (sync), Kilidi Çözme ve Kapatma
$adb->table_close($tablo_yolu);
```

### 15.3 Ham Kayıt İşleme Metodları (`recs_get`, `recs_put`, `recs_del`, `recs_exist`, `recs_keys`, `recs_scan`, `table_readid`)

Açık veya otomatik açılan dosya oturumu üzerinde doğrudan `$db->get()`, `$db->put()`, `$db->del()` çağrıları yaparak maksimum performans sağlar:

```perl
# 1. Ham Değerleri Toplu Okuma (recs_get)
my $ham_veriler = $adb->recs_get($tablo_yolu, 5001, 5002);
# $ham_veriler döner: { 5001 => "ham_veri_stringi", 5002 => "..." }

# 2. Otomatik Dosya Oturumu ile Tek Kayıt Okuma (table_readid)
my ($rid, @kayit) = $adb->table_readid($tablo_yolu, 5001);

# 3. Ham Kayıtları Toplu Yazma (recs_put)
$adb->recs_put($tablo_yolu, 
    [ 5001, "5,12", "3", "7", "Ürün A", "", "", "", "", "2999.00", "1" ],
    [ 5002, "5",    "8", "9", "Ürün B", "", "", "", "", "4500.00", "1" ]
);

# 4. Anahtar Varlık Kontrolü (recs_exist)
my $var_mi = $adb->recs_exist($tablo_yolu, 5001);

# 5. Açık Dosyadaki Tüm Ham Anahtarları Listeleme (recs_keys)
my @tum_anahtarlar = $adb->recs_keys($tablo_yolu);

# 6. Belleği Şişirmeden Akış Halinde Kayıt Taraması (recs_scan)
$adb->recs_scan($tablo_yolu, sub {
    my ($anahtar, $ham_deger) = @_;
    # Kayıtları akış halinde işle
});

# 7. Ham Kayıtları Toplu Silme (recs_del)
$adb->recs_del($tablo_yolu, 5001, 5002);
```

### 15.4 Tablo Metadata ve ID Yardımcıları (`table_keys`, `table_count`, `table_lastid`, `table_autoid`, `table_create`)

```perl
# Tablodaki tüm aktif ID'leri alma
my @tum_idlar = $adb->table_keys("catalog_product");

# Tablodaki toplam kayıt sayısı
my $toplam_kayit = $adb->table_count("catalog_product");

# Tablodaki en son (en büyük) ID
my $son_id = $adb->table_lastid("catalog_product");

# Yeni artan ID üretme veya formatlama
my $yeni_autoid = $adb->table_autoid("catalog_product");

# Tablo için boş bir .db veri dosyası oluşturma
$adb->table_create("catalog_product");
```

### 15.5 Metin ve Dize İşleme Yardımcıları (`Amber::Util::String`)

`AmberDB` doğrudan `Amber::Util::String` modülünden türediği için metin temizleme, HTML dönüştürme ve veri türü tespiti gibi araçlar doğrudan `$adb` üzerinden çağrılabilir:

```perl
# 1. Boşluk Temizleme ve Düzleştirme (trim_space)
my $temiz = $adb->trim_space("  merhaba \n\t dunya  ");      # Satır yapısını korur
my $duz   = $adb->trim_space("  merhaba \n\t dunya  ", 1);   # Tüm boşlukları tek boşluğa indirger

# 2. HTML Etiketlerini Temizleme (remove_tags)
my $metin = $adb->remove_tags("<p>Açıklama metni <br/>satır sonu</p>");

# 3. Kelime Bütünlüğünü Koruyarak Kısaltma (truncate_text / sub_str / short_title)
my $ozet  = $adb->truncate_text($uzun_yazi, 120);          # Kelimeyi bölmeden '...' ile kısaltır
my $kisa  = $adb->short_title($urun_basligi, 32);          # ASCII uyumlu kısa başlık

# 4. Veri Türü ve Deseni Tanıyıcı (what_isthis)
my $tur = $adb->what_isthis("kullanici@example.com");      # 'email' döner
# Tanıdığı türler: email, barcode, gsm, phone, tcno, number, ascii, letter, domain, other

# 5. HTML Entity Dönüşümleri (html_ascode / code_ashtml / text2html / html2text)
my $kod_html  = $adb->html_ascode('<a href="test">');      # HTML özel karakterlerini entity'ye çevirir
my $duz_metin = $adb->html2text($html_belgesi);
```

---

## 16. Filtre ve Kategori Menüsü (Facet Sistemi)

Facet motoru, e-ticaret sitelerindeki sol filtreleme panelini (Marka, Kategori, Yazar, Fiyat Aralığı, Renk vb.) büyük ürün katalogları üzerinde **düşük gecikmeli ve yüksek performanslı** olarak oluşturan filtreleme ve kümeleme sistemidir.

### 16.1 Sağladığı Faydalar ve Özellikler

* **Düşük Gecikmeli Kolon Bazlı Kümeleme:** Kullanıcı bir kategoriye girdiğinde veya filtre seçtiğinde, sistem tüm tablo kayıtlarını satır satır taramak yerine yalnızca hedeflenen kolon indeks dosyalarını (`.fac`) okuyarak filtre menüsünü minimum I/O maliyetiyle oluşturur.
* **Sadece Satışta Olan Ürünleri Sayar:** Stoğu bitmiş, pasif veya satışı kapanmış ürünler filtre sayılarını şişirmez; kullanıcılar yalnızca gerçekten satın alabilecekleri ürünlerin filtrelerini ve doğru ürün adetlerini görür.
* **Çoklu Seçim Akıllılığı (Disjunctive Counting):** Kullanıcı aynı anda hem *Apple* hem *Samsung* markalarını seçtiğinde, sistem diğer markaların da adetlerini kaybetmeden doğru şekilde göstermeye devam eder.
* **Arama Sonuçlarına Özel Filtreler (`base_ids`):** Ziyaretçi sitede bir arama yaptığında (örn. "kulaklık"), sol taraftaki filtre menüsü tüm siteyi değil, sadece arama sonucunda çıkan ürünlerin markalarını ve özelliklerini filtre olarak sunar.
* **Otomatik İsim ve Etiket Çözümleme:** Sayısal ID'ler veya renk gibi serbest metinler için ayrı tablolarla uğraşmanıza gerek kalmaz; sistem insan tarafından okunabilir etiketleri menüde otomatik hazırlar.

### 16.2 Şemada Tanımlama (`.table`)

Bir tabloda filtre menüsünü etkinleştirmek için şema dosyanıza `use_facet => 1` ve `facet_block` tanımlarını eklemeniz yeterlidir:

```perl
# dbstore/schema/catalog_attributes.table
{
    name         => "Ürün Nitelikleri",
    use_facet    => 1,                       # Bu tabloda filtreleme motorunu etkinleştirir
    
    # Hangi blokların filtre olarak sunulacağını belirleyin:
    facet_block  => [
        # İlişkisel Tablolardan Çekilen Filtreler (Kategori, Marka, Yazar):
        { blk => 1, id => "kategori", label => "Kategori",  table => "catalog_category",    name_idx => 2 },
        { blk => 2, id => "marka",    label => "Marka",     table => "catalog_producer",    name_idx => 2 },
        { blk => 3, id => "yazar",    label => "Yazar",     table => "catalog_contributor", name_idx => 2 },
        
        # Sayısal veya Aralık Filtreleri:
        { blk => 4, id => "fiyat",    label => "Fiyat Aralığı" },
        
        # Serbest Metin Özellikleri (Renk, Beden vb.):
        { blk => 6, id => "renk",     label => "Renk" },
    ],
}
```

### 16.3 Kullanım Şekli ve Örnekler

#### A. Kategori Sayfasında Sol Filtre Menüsünü Oluşturma
Ziyaretçinin seçtiği filtrelere göre sol menüyü ve ürün adetlerini tek bir çağrıyla hazırlayabilirsiniz:

```perl
# Kullanıcının URL'den gelen seçimleri: Kategori 5, Marka 12 veya 14 seçilmiş
my %secilen_filtreler = ( 1 => "5", 2 => ["12", "14"] );

my $menu = $adb->facet_menu(
    "catalog_attributes",
    \%secilen_filtreler,
    $table_info->{facet_block},
    { limit => 10, sort => "count" } # En çok ürünü olan ilk 10 filtreyi göster
);

# $menu çıktısı doğrudan şablona gönderilmeye hazırdır:
{
    count         => 42,                         # Filtrelere uyan toplam ürün sayısı
    ids           => [ 101, 105, 120, ... ],     # Ekranda listelenecek ürünlerin ID'leri
    active_counts => { 1 => 1, 2 => 2 },         # Blok bazında aktif filtre sayısı
    groups        => [                           # HTML sol menüsü için hazır gruplar:
        {
            blk          => 2,
            name         => "Marka",
            active       => "1",
            active_count => 2,
            records      => [
                { uid => "fc_2_12", param => "f2", val => 12, label => "İthaki", count => 28, checked => "1" },
                { uid => "fc_2_14", param => "f2", val => 14, label => "Can",    count => 14, checked => "1" },
                { uid => "fc_2_19", param => "f2", val => 19, label => "YKY",    count => 6,  checked => ""  },
            ]
        },
        ...
    ]
}
```

#### B. Arama Sonuçları Sayfasında Dinamik Filtre Üretme
Arama yapıldığında, bulunan ürünlerin ID listesini `base_ids` olarak vererek filtrenin sadece arama sonuçlarını kapsamasını sağlarsınız:

```perl
# 1. Ziyaretçinin arama terimiyle ürünleri bul (keys_only ile limitsiz ID listesi)
my @bulunan_idler = $adb->search_table("catalog_product", "bilim kurgu", { keys_only => 1 });

# 2. Sadece bulunan bu ürünler arasından filtre menüsü üret
my $arama_menusu = $adb->facet_menu(
    "catalog_attributes",
    \%secilen_filtreler,
    $table_info->{facet_block},
    { base_ids => \@bulunan_idler }
);
```

---

## 17. Kullanıcı Denetim İzi (Audit) ve Yedekleme

### 17.1 Kullanıcı İşlem Geçmişi (`log_owner`)
Şemada `log_owner => 1` aktif olduğunda, kaydın tüm geçmişi `.aut` dosyasında tutulur:

```perl
# Bir kaydın kimler tarafından ne zaman değiştirildiğini HTML olarak alma
my $gecmis_html = $adb->auth_view("catalog_product", 5001);
print $gecmis_html;
# Çıktı:
#     add     2026-08-14 10:15    admin_maruf
#     edit    2026-08-14 11:30    editor_ali
```

### 17.2 Sürekli Değişiklik Akışı (Continuous Recovery Stream - `YYYY-MM-DD.csv`)
AmberDB yapılan her `insert`, `modify` ve `delete` işlemini kronolojik zaman-serisi olarak `backup/YYYY/YYYY-MM-DD.csv` dosyasına otomatik olarak ekler (append-only).

Her satır tab ayrılmış (`\t`) olarak şu sütun yapısında yazılır:
`[Zaman Damgası] \t [Kullanıcı] \t [İşlem] \t [Tablo] \t [Kayıt ID] \t [Paketlenmiş Değerler]`

Bu akışı devre dışı bırakmak için:
* **Tablo Şemasında (Tablo Bazlı):** Şema dosyasına `no_backup => 1` eklenirse sadece o tablo için yedekleme kapatılır.
* **Genel Düzeyde (Tüm Tablolar):** `$adb->config(no_backup => 1);` tanımlanırsa tüm tablolar için yedekleme kapatılır.

### 17.3 Native Veritabanı Arşivi (`.amberdb` Dump & Restore)
AmberDB, tüm şemaları (`schema/*.table`, `schema/*.dbase`) ve otoriter veri dosyalarını (`tables/*.db`, `tables/*.del`, `tables/*.aut`, `tables/*.cnt`) SHA-256 doğrulama özetleriyle birlikte fiziksel dizin yapısıyla birebir örtüşen sıkıştırılmış tek bir **`.amberdb`** arşiv dosyası olarak yedekler ve geri yükler.

Türetilmiş indeks dosyaları (`.inx`, `.src`, `.fld`, `.fac`, `.srt`) boyuttan tasarruf etmek için arşiv içine konmaz; `restore` esnasında şema kurallarına göre `set_index` ile deterministik olarak sıfırdan üretilir.

```perl
use AmberDB;
use AmberDB::Tools;

my $adb   = AmberDB->new(path => { dbase_dir => "./dbstore" });
my $tools = AmberDB::Tools->new($adb);

# 1. Tüm veritabanının tam yedeğini alma (.amberdb)
my $arsiv = $tools->dump();
# Çıktı: dbstore/backup/2026/amberdb_2026-08-28_180000.amberdb

# 2. Belirli tabloların snapshot yedeğini alma
$tools->dump(
    file   => "backup/2026/katalog_yedek.amberdb",
    tables => ["catalog_product", "catalog_category"]
);

# 3. Yedeği geri yükleme ve tüm indeksleri otomatik inşa etme
$tools->restore(
    file    => "backup/2026/katalog_yedek.amberdb",
    force   => 1, # Var olan tabloların üzerine yazma izni
    reindex => 1  # İndeksleri sıfırdan üret
);
```

#### CLI Komut Satırı Aracı (`bin/amberdb_backup.pl`)
```bash
# Veritabanını yedekleme
perl bin/amberdb_backup.pl --dump --file backup/2026/tam_yedek.amberdb

# Belirli tabloları yedekleme
perl bin/amberdb_backup.pl --dump --tables products,orders

# Yedeği güvenli şekilde geri yükleme
perl bin/amberdb_backup.pl --restore --file backup/2026/tam_yedek.amberdb --force
```

---

## 18. Bakım ve Onarım Araçları (AmberDB::Tools)

Veritabanı indekslerini sıfırdan yeniden oluşturmak, veri doğrulaması yapmak veya tabloları optimize etmek için `AmberDB::Tools` kullanılır:

```perl
use AmberDB;
use AmberDB::Tools;

my $adb   = AmberDB->new(path => { dbase_dir => "./dbstore" });
my $tools = AmberDB::Tools->new($adb);

# 1. Bir tablonun tüm indekslerini sıfırdan oluşturma (Re-Index)
$tools->set_index("catalog_product");

# 2. Tüm veritabanındaki bütün tabloları yeniden indeksleme
$tools->index_alltables();

# 3. İndeks Tutarlılık Kontrolü
my @kayitlar = $adb->read_all("catalog_product", { no_index => 1 });
my $fark = $tools->check_readall("catalog_product", @kayitlar);

# 4. Tablo Vakumlama (Fragmentasyonu temizler ve dosyayı küçültür)
$tools->vacuum("catalog_product", 1); # 1 = işlem sonrası reindex yap

# 5. DB_File tablosunu CSV'ye aktarma veya CSV'den geri yükleme
$tools->tie2csv("catalog_product");
$tools->csv2tie("catalog_product");

# 6. Tüm Veritabanı Tablolarını Toplu Yeniden İndeksleme / Dönüştürme
my $donusum_raporu = $tools->convert_tables();

# 7. Tabloyu ve İlişkili Tüm İkincil İndeks Dosyalarını Diskten Silme
$tools->del_table("eski_tablo");

# 8. Bağımsız / Geçici Dizinler için Hafif Ad-Hoc AmberDB Örneği
my $basit_adb = $tools->db_simple("/path/to/data/dir");
```

---

## 19. Dosya Uzantıları Haritası

AmberDB dosya uzantıları rollerine ve yeniden üretilebilirlik durumlarına göre 3 grupta toplanır:

| Uzantı | Rol / Sınıf | Yeniden Üretilebilir mi? | Açıklama |
|---|---|---|---|
| **Temel & Otoriter Veriler** | | | |
| `.db` | Birincil Veri (Source of Truth) | **Hayır** (Otoriter) | Berkeley DB ana döküman tablosu (`DB_File` Hash). |
| `.del` | Silinen Kayıtlar Arşivi | **Hayır** (Otoriter) | Silinen (soft-delete) kayıtların arşivi (`keep_deleted`). |
| `.aut` | Kullanıcı Denetim İzi (Audit) | **Hayır** (Otoriter) | Kimin ne zaman hangi kaydı değiştirdiğinin logu (`log_owner`). |
| `.str` | Metin Sözlük Eşleştirmesi | **Hayır** (Otoriter) | Serbest metinleri sayısal foreign key ID'lerine bağlayan çift yönlü sözlük (`_${blk}.str`). |
| **Türetilmiş İndeks Dosyaları** | | | |
| `.inx` | Birincil Kayıt İndeksi |  **Evet** (`set_index`) | Tüm aktif ID listesi, kayıt sayısı ve son ID ikili indeksi. |
| `.fld` | Eşleştirme İndeksi (Match) |  **Evet** (`set_index`) | Alan bazlı tersine eşleştirme indeksi (`match_block`). |
| `.src` | Tam Metin Arama (Search) |  **Evet** (`set_index`) | Kelime bazlı tersine arama indeksi (`search_block`). |
| `.srt` | Sıralama İndeksi (Sort) |  **Evet** (`set_index`) | Belirlenen bloklara göre sıralı ID ikili indeksi (`sort_block`). |
| `.fac` | Facet Filtreleme İndeksi |  **Evet** (`set_index`) | E-ticaret filtre sayaç ve durum haritası (`facet_block`). |
| `.slg` | Slug Haritası |  **Evet** (`set_index`) | `_0.slg` (ID→Slug) ve `_1.slg` (Slug→ID) çift yönlü eşleştirici. |
| `.jinx`| Junk Birincil Kayıt İndeksi |  **Evet** (`set_index`) | Pasif/arşiv kayıtların ID ikili indeksi (`use_junk`). |
| `.jfld`| Junk Eşleştirme İndeksi |  **Evet** (`set_index`) | Pasif kayıtların alan eşleştirme indeksi (`jnktype => 'B'/'AB'`). |
| `.jsrc`| Junk Tam Metin Arama |  **Evet** (`set_index`) | Pasif kayıtların arama ters indeksi (`jnktype => 'B'/'AB'`). |
| **Çalışma Zamanı ve Geçici Dosyalar** | | | |
| `.cnt` | Sayaç Dosyası | Sayaç verisi | Kayıt görüntülenme/tıklanma sayaçları (`use_counter`). |
| `.txn` | İşlem Günlüğü (Undo Log) | Geçici (Runtime) | Aktif işlem undo-journal geri alma dosyası (`txn/`). |
| `.tmp` | Disk Buffer Dosyası | Geçici (Staging) | `dbstore/buffer/` altında geçici aktarım/ETL dosyası (`buffer_write`). |
| `.lock` | Süreç Kilit Dosyası | Geçici (Mutex) | İşletim sistemi `flock` process senkronizasyon dosyası. |

---

## 20. Dizin Yapısı

```text
dbstore/
├── schema/                      ← Şema ve Grup Tanımları
│   ├── catalog.dbase            ← Grup tanımı
│   ├── catalog_product.table    ← Ürün tablosu şeması
│   └── catalog_category.table   ← Kategori tablosu şeması
├── tables/                      ← Ana Veri ve İndeks Dosyaları
│   ├── catalog_product.db       ← Ana veri
│   ├── catalog_product.inx      ← İkili kayıt ve sıralama indeksi
│   ├── catalog_product.fld      ← Birebir eşleştirme indeksi (tüm bloklar "$blk:$val")
│   ├── catalog_product.src      ← Tam metin arama indeksi
│   ├── catalog_product.fac      ← Facet filtreleme indeksi
│   ├── catalog_product.unq      ← Alan metin sözlüğü
│   ├── catalog_product.slg      ← Çift yönlü URL slug haritası ("0:$id", "1:$slug")
│   ├── catalog_product.aut      ← Denetim logu
│   └── catalog_product.del      ← Silinen kayıtlar
├── ramdisk/                     ← RAM-Disk Paylaşımlı Bellek ve Hızlı Depolama (Linux tmpfs, macOS APFS, Windows ImDisk)
├── buffer/                      ← Geçici Disk Buffer / Staging Dosyaları
├── txn/                         ← Aktif Transaction Günlükleri
├── pids/                        ← Dosya ve Kayıt Kilitleri
└── backup/                      ← Günlük CSV Yedekleri
```

---

## 21. Geliştirici Tavsiyeleri ve En İyi Pratikler

1. **Toplu Veri Girişinde `insert_list` Kullanın:** Yüzlerce kaydı tek tek döngüde `insert_id` ile eklemek yerine tek seferde `insert_list` ile ekleyin; disk I/O ve indeksleme süresi 10 kat hızlanacaktır.
2. **Kritik İş Mantıklarında `transact_start` Kullanın:** Stok düşme, bakiye güncelleme ve sipariş onaylama gibi adımları mutlaka transaction bloğu içine alın.
3. **Şemalarda Gereksiz Blokları İndekslemeyin:** Yalnızca filtrelenecek alanları `match_block`, aranacak alanları `search_block` olarak tanımlayın.
4. **Sayfalama Dönen Değer İmzasını Doğru Karşılayın:** `read_all`, `field_fetch` ve `search_table` metotlarında `$limit > 0` verildiğinde dönen listenin ilk elemanının `$toplam` tamsayısı olduğunu unutmayın. Asla `my @kayitlar = $adb->read_all("tablo", { offset => 0, limit => 20 })` şeklinde tek diziye almayın (fatal crash verir); mutlaka `my ($toplam, @kayitlar)` şeklinde ilk elemanı toplam sayı olarak karşılayın.
5. **Kayıt ID Tipi ve Basit Mod Seçimi:** Standart ilişkisel tablolar 64-bit tam sayı ID'ler ile çalışarak ikili sabit boyutlu ofsetler (`(Q>)*`) üzerinde en yüksek dilimleme hızını sunar. UUID, slug veya oturum belirteçleri gibi serbest metin anahtarları gerektiğinde ise tablo şemasına `use_simple => 1` vererek sıfır indeks ek yüküyle doğrudan anahtar-değer modunu kullanın.
6. **Kayıt Dizisinde ID Standartı:** Kayıt dizilerinde (`@record`) her zaman 0. indisi Kayıt ID'si (`$record[0]`) olarak konumlandırın. Yeni kayıtta `0` verip `my $id = $record[0] = $adb->insert_id("tablo", @record);` şeklinde atayın. Okuma (`read_id`), güncelleme (`update_id("tablo", @record)`) ve silme (`delete_id("tablo", $record[0])`) işlemlerini bu bütüncül dizi üzerinden yürütmek parametre kaymalarını ve hataları tamamen önler.

---

## 22. Kapsamlı Uygulama Örneği (Sipariş & Stok Senaryosu)

Aşağıdaki örnek; ana tabloların oluşturulması, ürünün ilişkisel ID'ler ve çoklu kategorilerle eklenmesi, URL slug ile okuma, filtreli arama, sıralama ve güvenli bir sipariş transaction'ını baştan sona gösterir:

```perl
use strict;
use warnings;
use AmberDB;

# 1. Motoru başlat
my $adb = AmberDB->new(
    cfg  => { language => "tr", user => "kasiyer_1" },
    path => { dbase_dir => "./dbstore" }
);

# 2. Ana Tanım Tablolarına Kayıt Ekleme (Master Tables)
my $kat_bilgisayar = $adb->insert_id("catalog_category", undef, "Bilgisayar & Bilişim", 1); # ID: 5
my $kat_tasinabilir = $adb->insert_id("catalog_category", undef, "Taşınabilir Cihazlar", 1);# ID: 12

my $marka_apple    = $adb->insert_id("catalog_brand", undef, "Apple", "ABD");                # ID: 8
my $yazar_tasarim  = $adb->insert_id("catalog_author", undef, "Donanım Ekibi", "Ar-Ge");   # ID: 7

# 3. Yeni Ürün Ekle (İlişkisel alanlara ID verilir; kategori "5,12" olarak çoklu tutulur)
my @urun = (
    "5,12",                         # [1] Kategori ID'leri (5: Bilgisayar, 12: Taşınabilir)
    "8",                            # [2] Marka ID: Apple (8)
    "7",                            # [3] Yazar / Katkıda Bulunan ID: 7
    "MacBook Pro M3",               # [4] Ürün Adı
    "16GB RAM 512GB SSD Uzay Grisi",# [5] Açıklama
    "", "", "",
    10,                             # [8] Stok: 10 adet
    "195949123456",                 # [9] Barkod
    "64999.00",                     # [10] Fiyat
    "1"                             # [11] Satışta: 1
);

my $urun_id = $adb->insert_id("catalog_product", undef, @urun);
print "1. Ürün Eklendi -> ID: $urun_id\n";

# 4. Otomatik Üretilen URL Slug'ı Oku
my $slug_harita = $adb->get_slug("catalog_product", 0, $urun_id);
print "2. Oluşan URL -> /urun/$slug_harita->{$urun_id}\n";

# 5. Çoklu Kategoriden (Örn: 12 nolu Taşınabilir) Fiyat Sıralı Listeleme, ilk 20 kayıt
my ($toplam, @urunler) = $adb->field_fetch(
    "catalog_product", 1, "12", {
        offset => 0,
        limit  => 20,
        sort   => { blk => 10, reverse => 1 } # Ucuzdan pahalıya
    }
);
print "3. Kategori 12'de $toplam ürün listelendi.\n";

# 6. Güvenli Sipariş Transaction'ı (Stok Düşme ve Sipariş Kaydı)
$adb->transact_start();

my @mevcut = $adb->read_id("catalog_product", $urun_id);
if ($mevcut[8] >= 1) { # Stok kontrolü
    # Stoğu 1 azalt (@mevcut[0] zaten $urun_id değerini içerir)
    $mevcut[8] -= 1;
    $adb->update_id("catalog_product", @mevcut);
    
    # Sipariş oluştur (Kalemler Blok 3'te ARRAY olarak iç içe döküman şeklinde tutulur)
    my @siparis_kalemleri = ( [ $urun_id, "MacBook Pro M3", 1, 64999.00 ] );
    my $siparis_id = $adb->insert_id("orders", undef, "Müşteri Ahmet", time(), \@siparis_kalemleri, { status => "onaylandi" });
    
} else {
    # Operasyonel durum (stok yetersiz): Değişiklikleri doğrudan geri sar
    $adb->transact_rollback();
}

my $txn = $adb->transact_end();
if ($txn->{status} eq "commit") {
    print "4. Sipariş başarıyla tamamlandı! Kalan Stok: $mevcut[8]\n";
} else {
    print "4. Hata: Stok kalmadı veya işlem başarısız oldu, değişiklikler geri alındı!\n";
}
```

---

## 23. Metod Hızlı Referans Tablosu

| Metod | Parametreler | Dönüş Değeri | Açıklama |
|---|---|---|---|
| **Temel CRUD** | | | |
| `insert_id` | `$tablo, $id, @alanlar` | `$yeni_id` | Tekil kayıt ekler, tüm indeksleri günceller. |
| `insert_list` | `$tablo, @kayitlar` | `\%statu` | Toplu kayıt ekler (Yüksek hızlı bulk write). |
| `update_id` | `$tablo, $id, @alanlar` | `1/undef` | Kaydı günceller ve indeksleri senkronize eder. |
| `update_list` | `$tablo, @kayitlar` | `\%statu` | Toplu kayıt günceller. |
| `delete_id` | `$tablo, $id` | `1/undef` | Kaydı siler (veya `.del` soft-delete yapar). |
| `delete_list` | `$tablo, @idlar` | `\%statu` | Toplu kayıt siler. |
| **Okuma ve Arama** | | | |
| `read_id` | `$tablo, $id` | `@alanlar` | Birincil anahtara göre kaydı okur. |
| `read_all` | `$tablo, [\%ayarlar]` | `($toplam, @kayitlar)` | Tablodaki kayıtları sıralı ve sayfalı okur. |
| `read_list` | `$tablo, \@id_listesi` | `@kayitlar` | ID listesindeki kayıtları verilen sırada getirir. |
| `field_fetch` | `$tablo, $blok, $deger, [\%ayarlar]` | `($toplam, @kayitlar)` (sayfalı) / `@kayitlar` | Blok eşleştirme indeksinden (`.fld`) doğrudan tekil anahtar araması yapar. |
| `search_table` | `$tablo, $metin, [\%ayarlar]` | `($toplam, @kayitlar)` (sayfalı) / `@kayitlar` | Tam metin arama indeksinden arama yapar. |
| `field_filter` | `$tablo, \%filtre_ayarlari` | `{ count, ids }` | Çok kriterli birleşik filtreleme ve sıralama. |
| `field_fltkeys` | `$tablo, \%facet_ayarlari` | `\%sayilar` | Facet filtre sayaçlarını hesaplar. |
| **Varlık ve Konumsal Okumalar** | | | |
| `exist_id` | `$tablo, $id` | `1/0` | Kaydın tabloda var olup olmadığını kontrol eder. |
| `exist_list` | `$tablo, @idlar` | `\%statu` | Çoklu ID'lerin varlığını `{ id => 1/0 }` olarak döner. |
| `exist_table` | `$tablo, [$uzanti]` | `1/0` | Tablo dosyasının fiziksel varlığını kontrol eder. |
| `read_firstid` | `$tablo` | `@alanlar` | Tablodaki ilk kaydı sayısal artan ID sırasına göre okur. |
| `read_lastid` | `$tablo` | `@alanlar` | Tablodaki en son eklenen kaydı (en büyük ID) okur. |
| `read_randid` | `$tablo` | `@alanlar` | Tablodan rastgele (random) bir kayıt okur. |
| `read_count` | `$tablo, $id` | `$adet` | Kaydın `.cnt` dosyasındaki sayaç değerini döner. |
| **Düşük Seviyeli Tablo ve Akış (Low-Level / Recs)** | | | |
| `table_read` | `$dosya_yolu` | `$db_obj` | DB_File tablosunu salt-okunur (`O_RDONLY`) açar. |
| `table_write` | `$dosya_yolu` | `$db_obj` | Tabloyu yazma/okuma modunda açar ve `flock LOCK_EX` kilitler. |
| `table_close` | `$dosya_yolu` | `1` | Tabloyu `sync()` eder, kilidi çözer ve kapatır. |
| `table_keys` | `$tablo` | `@idlar` | Tablodaki tüm aktif birincil anahtarların listesini döner. |
| `table_count` | `$tablo` | `$toplam` | Tablodaki toplam kayıt sayısını döner. |
| `table_lastid` | `$tablo` | `$son_id` | Tablodaki en yüksek son ID numarasını döner. |
| `table_autoid` | `$tablo, [$id]` | `$yeni_id` | Yeni artan sayısal veya formatlı ID üretir. |
| `table_create` | `$tablo` | `1` | Tablo için boş bir `.db` veri dosyası oluşturur. |
| `recs_get` | `$dosya_yolu, @idlar` | `\%sonuc` | Açık dosyadan doğrudan `$db->get()` ile `{ id => raw_val }` okur. |
| `recs_put` | `$dosya_yolu, @kayitlar` | `1` | `[$id, @alanlar]` kayıtlarını tek oturumda `$db->put()` ile yazar. |
| `recs_del` | `$dosya_yolu, @idlar` | `1` | Verilen ID'leri doğrudan `$db->del()` ile siler. |
| `recs_cutting` | `$start, $limit, @liste` | `($toplam, @dilim)` | Dizi üzerinde bellek içi sayfalama dilimlemesi yapar. |
| **İşlem Güvenliği (Transaction)** | | | |
| `transact_start`| - | `1/undef` | Yeni bir işlem (transaction) başlatır. |
| `transact_error`| `$kontekst, $mesaj` | `undef` | İşlem hatası bildirir (transact_end'in rollback yapmasını sağlar). |
| `transact_end`  | - | `\%sonuc` | İşlemi tamamlar (hata yoksa commit, varsa otomatik rollback). |
| `transact_rollback` | - | `\%sonuc` | (İç Metot) İşlemi hemen zorla geri alır. |
| `transact_commit`   | - | `\%sonuc` | (İç Metot) Değişiklikleri diske yazar ve onaylar. |
| `transact_recover`  | - | `\%sonuc` | Yetim/çökmüş işlemleri onarır. |
| **Önbellek, Slug, Şema & Denetim** | | | |
| `table_info`   | `$tablo` | `\%schema` | Tablonun tanımlı şema konfigürasyonunu döner. |
| `table_attr`   | `$tablo, \%ozellikler` | `1` | Çalışma zamanında bellek içi şema günceller. |
| `get_cache`    | `$grup, [$anahtar]` | `@veriler / $deger` | L1 süreç içi bellek önbelleğinden veri okur. |
| `set_cache`    | `$grup, [$anahtar], [@veriler]` | `$veri / 1` | L1 önbelleğe veri yazar, günceller veya anahtar/grup siler. |
| `get_slug`     | `$tablo, $tip, @anahtarlar` | `\%harita` | ID ↔ Slug eşleşmesini getirir. |
| `auth_view`    | `$tablo, $id` | `$html` | Kaydın işlem geçmişini HTML olarak döner. |

---

## 24. AmberDB Neden Kullanılmalıdır? (SQL ve SQLite ile Karşılaştırma)

AmberDB, geleneksel ilişkisel SQL motorlarının (MySQL, PostgreSQL) ya da SQLite'ın yerine geçmeye çalışan zayıf bir SQL alternatifi değildir. SQL dünyasının karmaşık tablolar, `JOIN`'ler, trigger'lar ve uygulama katmanı kodlarıyla çözmeye çalıştığı problemleri **doğal, şema tabanlı, birleşik döküman merkezli ve tersine indeksli (inverted index)** yapısıyla tek noktada çözer.

### 24.1 Tek Anahtarda İç İçe (Nested) Veri Yapıları ve SQL JOIN'lerinin Ortadan Kalkması
İlişkisel SQL veritabanlarında sipariş, ürün varyantları veya çoklu etiketler için tabloları normalize etmeniz (`orders`, `order_items`, `attributes`) ve okurken çok tablolu `JOIN` yapmanız gerekir.

AmberDB'de kayıtlar birleşik (denormalized) doğal bir Perl veri yapısı olarak saklanır:

```perl
my @order = (
    "Musteri_A",                  # [1] Müşteri Adı
    "2026-08-14",                 # [2] Sipariş Tarihi
    [                             # [3] İç içe dizi (ARRAY): Sipariş Kalemleri (Ürün ID'leri: 101, 102)
        [ 101, "Laptop", 1, 35000 ],
        [ 102, "Kablosuz Mouse", 2, 750 ]
    ],
    { status => "onaylandi", kargo_kod => "TR12345" } # [4] İç içe sözlük (HASH): Ek bilgiler
);

$adb->insert_id("orders", 1001, @order);
```

Bu kayıt `.db` dosyasına **tek bir key-value** olarak yazılır ve okunduğunda doğrudan kullanıma hazır Perl referansları olarak döner. JSON sütunları ayrıştırma ya da `JOIN` sorguları yazma yükü tamamen ortadan kalkar.

### 24.2 Birleşik Kayıtlarda `match_block` ile Düşük I/O ile İlişki Kurma
SQL'de "101 numaralı ürünü içeren tüm siparişler hangileridir?" sorusunun cevabı için `order_items` tablosu taranır, `orders` tablosuna `JOIN` atılır ve ilişkisel indeksler ile tablolar arasında çoklu disk okumaları yapılır.

**AmberDB'de ise:**
Sipariş kaydında ürün listesi Blok 3'te bir ARRAY olarak tutulur. Şemada `match_block => [3]` tanımlandığında motor, `set_fieldlist` ile dizideki her ürün ID'sini ayrıştırarak `orders.fld` eşleştirme indeksine `"3:$id"` anahtarıyla kaydeder.

```perl
# 101 nolu ürünü içeren tüm sipariş bilgilerini getirme:
my @siparisler = $adb->field_fetch("orders", 3, 101);
```

Bu işlemde motor, `orders.fld` dosyasından `"3:101"` anahtarına **tek bir doğrudan anahtar erişimi (direct key lookup)** yaparak `101` anahtarının karşılığındaki tüm sipariş ID'lerini doğrudan (indeksli anahtar başına ortalama O(1) arama maliyetiyle) alır:
```text
# orders.fld dosyası içinde:
# "3:101" => [ 1001, 1005, 1023 ] (Binary RID dizisi)
```

Anahtarları aldıktan sonra anahtarların değerlerini tek seferde okuyarak ilgili siparişlere ait tüm bilgileri getirir.

SQL motorları birden fazla tablo, B-Tree indeksi ve satır tararken; AmberDB **önceden türetilmiş tersine indeksleri** sayesinde gereksiz disk I/O ve sorgu planlama maliyetlerini (zero query planning overhead) ortadan kaldırarak aynı ilişkiyi doğrudan çözer.

### 24.3 Şema Tanımıyla CRUD'a Bağlı Otomatik Çoklu İndeksleme
SQL'de her indeks için `CREATE INDEX`, Full-Text indeks tanımlamanız ve her güncellemede tutarlılığı takip etmek için trigger/uygulama kodu yazmanız gerekir.

AmberDB'de tablonun `.table` şema dosyasında bir kez tanımlarsınız:
```perl
{
    match_block  => [1, 3],    # Müşteri ID ve Ürün ID eşleştirmesi (.fld)
    search_block => [4],       # Tam metin arama (.src)
    facet_block  => [1, 2],    # Filtreleme yüzeyleri (.fac)
    sort_block   => [10],      # Fiyata göre sıralama indeksi (.srt)
    slug_block   => [1, 4],    # Otomatik URL slug üretimi (.slg)
    log_owner    => 1,         # Kim, ne zaman değiştirdi denetimi (.aut)
    keep_deleted => 1,         # Soft-delete çöp kutusu (.del)
}
```

Siz yalnızca `$adb->insert_id(...)`, `$adb->update_id(...)` veya `$adb->delete_id(...)` çağırırsınız; motor yukarıdaki tüm indeks ve log dosyalarını **tek adımda ve otomatik** günceller.

### 24.4 Doğrudan Tersine İndeks Erişimi (Sorgu Planlayıcı Yükü Yok)
SQL'de `SELECT id FROM orders WHERE customer_id = 'A'` sorgusu çalıştırıldığında SQL parser, query optimizer ve execution engine devreye girer.

AmberDB'de `field_fetch` doğrudan Berkeley DB hash ve packed binary blok okumasıdır. Sorgu yorumlama veya yürütme planı maliyeti sıfırdır.

### 24.5 Dahili Yaşam Döngüsü ve Ek Özellikler
- **Otomatik URL Slug Yönetimi:** Başlık değiştiğinde `/urun/ahmet-umit/istanbul-hatirasi` gibi URL slug'ları ve çakışma kontrolleri motor tarafından yönetilir.
- **Yerleşik Audit Trail (.aut):** Hangi kullanıcının ne zaman kayıt eklediği veya güncellediği otomatik tutulur.
- **Güvenli Soft-Delete (.del):** Silinen kayıtlar şema ayarına göre geri kurtarılabilir şekilde arşivlenir.
- **Sıfır Bağımlılık & Kolay Yedekleme:** Tek bir klasörü kopyalayarak tüm veritabanını, indekslerini ve ayarlarını yedekleyebilir veya başka bir ortama taşıyabilirsiniz.

---

## 25. Sınırlar ve Çekişmeli Konular (Fiziksel Kısıtlar vs. Bilinçli Mimari Tercihler)

Veritabanı tasarımında her mimari tercih belirli bir amaca hizmet eder. Geleneksel SQL dünyasından gelen geliştiricilerin ilk bakışta "kısıtlama" veya "eksiklik" olarak değerlendirebileceği bazı özellikler, AmberDB'nin doğrudan indeks erişimi, öngörülebilir düşük gecikme süresi (predictable low latency) ve yüksek I/O verimi hedefleri doğrultusunda **bilinçli olarak tasarlanmış temel avantajlarıdır**.

### 25.1 Fiziksel ve Çevresel Sınırlar (Kapsam Dışı Senaryolar)

Aşağıdaki durumlar dosya tabanlı ve gömülü (embedded) bir motor olan AmberDB'nin fiziksel kapsamı dışındadır:

#### 25.1.1 Yoğun ve Eşzamanlı Paralel Yazma İşlemleri (High Concurrent Writes)
AmberDB, `DB_File` (Berkeley DB) altyapısını kullanır. Yazma işlemleri sırasında dosya seviyesinde kilit (`flock`) uygulanır.
- **Kapsam Dışı:** Saniyede yüzlerce veya binlerce eşzamanlı kullanıcının aynı tablo dosyasına kesintisiz ve paralel olarak veri yazdığı/güncellediği sistemler (örn. yüksek frekanslı finansal borsa emirleri, anlık dağıtık telemetri sayaçları).
- **Uygun Senaryolar:** Okuma ağırlıklı (read-heavy) sistemler, e-ticaret ürün katalogları, CMS sistemleri, sipariş toplama, müşteri veri tabanları ve orta ölçekli kurumsal veri yönetimi.

#### 25.1.2 Dağıtık ve Çok Sunuculu Eşzamanlı Ağ Yazımı (Distributed Multi-Master Clustering)
AmberDB yerel dosya sistemi üzerinde çalışacak şekilde optimize edilmiştir. Birden fazla fiziksel sunucunun aynı veri dosyalarına eşzamanlı olarak paylaşımlı ağ depolamaları (NFS, SMB vb.) üzerinden doğrudan yazması dosya kilitleme gecikmelerine ve önbellek tutarsızlıklarına yol açabileceğinden önerilmez.

---

### 25.2 Çekişmeli Konular: Eksiklik mi, Yoksa Bilinçli Bir Avantaj mı?

Dışarıdan bir kısıtlama gibi algılanabilecek, ancak AmberDB'yi geleneksel SQL motorlarından çok daha hızlı ve güvenilir kılan bilinçli mimari tercihler:

#### 25.2.1 Şemada İndekslenmemiş Alanlarda Anlık (Ad-Hoc) Full-Scan: Eksiklik mi, Performans Güvencesi mi?
- **Genel Algı:** *"SQL'de istediğim herhangi bir sütuna sorgu atabiliyorum, AmberDB'de şemada indeks tanımlamam gerekiyor."*
- **Gerçek ve Avantaj:** SQL'de indekssiz kolon sorguları arka planda kontrolsüz **tam tablo taraması (full table scan)** yaparak üretim sunucularının CPU ve disk I/O kaynaklarını tüketir. AmberDB, geliştiriciyi sorgulanacak alanları şemada `match_block` veya `search_block` olarak önceden bildirmeye yönlendirir. Bu sayede indekslenmiş alanlar üzerindeki tüm sorgular, karmaşık sorgu optimizasyonu yükü olmadan doğrudan tekil anahtar aramaları (indeksli anahtar başına ortalama O(1)) üzerinden deterministik ve tahmin edilebilir düşük gecikmeyle çalışır.

#### 25.2.2 Toplu (Bulk) Metodlarda Undo Günlüğünün Devre Dışı Olması: Kısıtlama mı, Maksimum I/O Verimi mi?
- **Genel Algı:** *"`insert_list` ve `update_list` çağrıları neden otomatik transaction undo günlüğü tutmuyor?"*
- **Gerçek ve Avantaj:** Yüz binlerce kaydın toplu aktarımında her satır için ayrı disk günlüğü tutmak ciddi bir I/O darboğazı yaratır. AmberDB, toplu aktarımlarda tek dosya oturumu açarak doğrudan belleğe ve diske yazar, böylece maksimum aktarım hızına (high throughput) ulaşır.
> **Geliştirici Özgürlüğü:** Bir listenin atomik ve geri alınabilir (transactional) olarak işlenmesi gerekiyorsa, geliştirici işlemleri bir döngü içerisinde tekil CRUD metodları (`insert_id`, `update_id`, `delete_id`) ile `transact_start()` ve `transact_end()` bloğuna alır. Böylece liste hem atomik hem de tam geri alınabilir olur.

#### 25.2.3 Sabit 8-Bayt İkili Adımlar ve Serbest Metin Anahtarlar: Kısıtlama mı, Mimari Tercih mi?
- **Genel Algı:** *"İlişkisel ve indeksli tablolarda neden sadece 64-bit pozitif tam sayılar destekleniyor?"*
- **Gerçek ve Avantaj:** AmberDB'nin ilişkisel ve indeksli tabloları birincil anahtar olarak saf 64-bit Big-Endian tam sayılar (`(Q>)*`) kullanır. Sabit 8-baytlık kayıt adımı, dizin belleğinde değişken uzunluklu string ayrıştırma ihtiyacını tamamen ortadan kaldırır. Sayfalama (`LIMIT/OFFSET`) işlemlerinde bellekten veri deserialization yapmadan doğrudan sabit bayt ofsetleriyle (`substr` zero-copy) dilimleme yapılmasına olanak tanır. UUID, e-posta veya oturum belirteçleri gibi serbest metin anahtarlarına ihtiyaç duyulan senaryolar için AmberDB, tablo bazında **`use_simple => 1`** modu sunar; bu modda 255 bayta kadar serbest metin anahtarları Berkeley DB üzerinde sıfır indeksleme I/O ek yüküyle doğrudan çalışır.

---

*Bu doküman AmberDB v5 mimarisi ve güncel geliştirici pratikleri doğrultusunda hazırlanmıştır.*
