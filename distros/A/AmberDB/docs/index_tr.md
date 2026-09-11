[Ana Sayfa](index_tr.html) &nbsp;•&nbsp; [Hakkında](TR.AmberDB-Hakkinda.html) &nbsp;•&nbsp; [Hızlı Başlangıç](#hızlı-başlangıç) &nbsp;•&nbsp; [Tutorial](TR.AmberDB_Veritabani_Sistemi.html) &nbsp;•&nbsp; [Benchmark](TR.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](TR.AmberDB-Locale_Kullanim_Rehberi.html) &nbsp;•&nbsp; [SQL Rehberi](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [English](index.html)

---

[![CPAN version](https://badge.fury.io/pl/AmberDB.svg)](https://metacpan.org/pod/AmberDB)
[![Perl Version](https://img.shields.io/badge/perl-5.16%2B-blue.svg)](https://www.perl.org)
[![License](https://img.shields.io/badge/license-Artistic_2.0-brightgreen.svg)](https://github.com/marufcetin/amberdb/blob/main/LICENSE)
[![CI](https://github.com/marufcetin/amberdb/actions/workflows/ci.yml/badge.svg)](https://github.com/marufcetin/amberdb/actions)
[![Documentation](https://img.shields.io/badge/docs-GitHub_Pages-blue.svg)](https://marufcetin.github.io/amberdb/)
[![GitHub Repository](https://img.shields.io/badge/GitHub-marufcetin%2Famberdb-181717?logo=github)](https://github.com/marufcetin/amberdb)

**AmberDB**, Perl için geliştirilmiş yüksek başarımlı, şema odaklı ve gömülü (embedded) bir NoSQL veritabanı motorudur. Berkeley DB (`DB_File`) üzerinde $O(1)$ 64-bit ikili indeksleme dilimleme, ACID işlem (transaction) garantisi (Strict 2PL), SQL JOIN darboğazı olmaksızın JSON benzeri iç içe dizi kayıtları, facet filtreleme ve akıllı sıcak/soğuk junk katman mimarisi sunar.

---

## Dokümantasyon ve Kılavuzlar

| Bölüm | Açıklama | Bağlantı |
| :--- | :--- | :--- |
| **AmberDB Hakkında** | Mimari genel bakış, tasarım felsefesi, neden AmberDB ve temel yetenekler. | [AmberDB Hakkında Oku](TR.AmberDB-Hakkinda.html) |
| **Tutorial & Geliştirici Kılavuzu** | Tüm CRUD işlemleri, Şema mimarisi, ACID işlemler, İndeksleme, Arama motoru, Facet ve En İyi Pratikler. | [Geliştirici Kılavuzunu Aç](TR.AmberDB_Veritabani_Sistemi.html) |
| **SQL Karşılaştırmalı Kullanım Rehberi** | SQL'den gelen geliştiriciler için "SQL'de şu şekilde, AmberDB'de bu şekilde" eşleştirmeleri, pratik kod örnekleri ve kopya kağıdı. | [SQL Rehberini Aç](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) |
| **Büyük Benchmark Raporu (600K Film)** | 600,000 gerçek IMDb kaydıyla AmberDB vs SQLite 3 derin sayfalama, arama, filtreleme ve nokta okuma karşılaştırması. | [Benchmark Raporunu Oku](TR.AmberDB-vs-SQLite_Benchmark.html) |
| **AmberDB::Locale Rehberi** | Çok dilli (Global Base varsayılan 10 dil) metin işleme, yerelleştirme, evrensel aksan açılımları ve büyük/küçük harf dönüşümleri. | [Locale Rehberini Aç](TR.AmberDB-Locale_Kullanim_Rehberi.html) |
| **Sürüm Notları (Changes)** | Sürüm geçmişi, son mimari güncellemeler ve değişiklik günlüğü. | [Değişiklikleri Gör](https://github.com/marufcetin/amberdb/blob/main/Changes) |
| **GitHub Wiki** | Metod bazlı API dokümantasyonu, mimari konseptler, bayraklar ve dosya formatları. | [Proje Wiki Sayfasını Aç](https://github.com/marufcetin/amberdb/wiki) |
| **English Documentation** | English landing page, overview article, complete developer guide, and locale manual. | [Switch to English](index.html) |

---

## Hızlı Başlangıç

### 1. Kurulum

AmberDB'yi CPAN üzerinden kurabilir veya kaynak koddan derleyebilirsiniz:

```bash
# cpanm ile (Önerilen)
cpanm AmberDB

# veya standart CPAN kabuğu ile
cpan AmberDB
```

veya GitHub kaynak kodundan derleyerek:

```bash
git clone https://github.com/marufcetin/amberdb.git
cd amberdb
perl Makefile.PL
make test
make install
```

---

### 2. Temel CRUD Kod Örneği

AmberDB'nin dizi tabanlı kayıt yapısını kullanan doğrulanmış temel CRUD örneği:

```perl
use strict;
use warnings;
use AmberDB;

# 1. Veritabanını Başlat
my $adb = AmberDB->new(
    cfg  => { user => 'admin', language => 'tr' },
    path => { dbase_dir => './dbstore' }
);

# 2. Kayıt Tanımlama (Dizi Tabanlı Belge Mimarisi)
my @product = (
    0,                          # [0] id (0: otomatik artan benzersiz ID)
    "Kablosuz Kulaklık",        # [1] name (ürün adı)
    149.99,                     # [2] price (fiyat)
    "Sony",                     # [3] brand (marka)
    "Elektronik",               # [4] category (kategori)
    { statu => "Satışta" }      # [5] nitelikler / meta veriler (hashref)
);

# 3. Kayıt Ekleme (Insert)
my $id = $product[0] = $adb->insert_id( "products", @product );

# 4. Kayıt Okuma (Read by ID)
my @from_db = $adb->read_id( "products", $id );
print "Ürün: $from_db[1], Fiyat: $from_db[2], Durum: $from_db[5]->{statu}\n";

# 5. Kayıt Güncelleme (Modify)
$product[2] = 129.99; # 2. bloktaki fiyatı güncelle
$adb->modify_id( "products", @product );

# 6. Tam Metin Arama (Full-Text Search)
my @results = $adb->search_table( "products", "sony kulaklık" );
foreach my $p (@results) {
    print "ID: $p->[0] | İsim: $p->[1] | Fiyat: $p->[2]\n";
}

# 7. Kayıt Silme (Delete)
$adb->delete_id( "products", $id );
```

---

## Temel Mimari ve Yetenekler

### 1. JOIN İhtiyacı Olmayan Hiyerarşik Kayıtlar
Veriyi birden fazla ilişkisel tabloya bölüp okuma anında maliyetli SQL `JOIN` işlemleriyle birleştirmek yerine, AmberDB kayıtları doğal iç içe liste (array) ve sözlük (hash) biçiminde saklar. Bu yaklaşım Perl'in veri modeliyle birebir örtüşür ve maksimum okuma hızı sağlar.

### 2. 64-Bit Big-Endian İkili İndeksleme ($O(1)$)
Birincil ve ikincil indeksler sabit 8-byte Big-Endian paketlenmiş tamsayı tamponları (`Q*`) kullanır. Bu sayede milyonlarca kayıtta dahi $O(1)$ ikili dilimleme ve alt milisaniye seviyesinde sayfalama (pagination) elde edilir.

### 3. ACID İşlemler ve Strict 2PL Güvencesi
Disk tabanlı geri alma günlüğü (`.txn`) ve Strict Two-Phase Locking (Strict 2PL) kilit yönetimi ile tam ACID desteği sunulur. Süreç çökmelerinde kurtarma adımı otomatik LIFO geri alma (rollback) uygular.

### 4. Yüksek Başarımlı Toplu (Batch) İşlemler
Toplu veri aktarımı metodları (`insert_list`, `modify_list`, `delete_list`), ana `.db` dosyasını tek seferde açıp indeksleri tek geçişte birleştirerek tek tek kayıt döngülerine kıyasla 50x-100x kat daha yüksek veri işleme hızı sunar.

### 5. Akıllı Sıcak / Soğuk Katmanlama (Junk Sistemi)
Canlı kayıtlar (`.db`) ile geçmiş/arşiv verileri (`.jnk`) birbirinden fiziksel olarak ayrıştırılır; tek sorguda hibrit olarak taranabilir (`jnktype => 'A' | 'B' | 'AB' | 'BA'`).

### 6. Kolonik Facet Filtreleme Motoru
E-ticaret ve zengin ürün katalogları için bit düzeyinde küme kesişimleri ve çift yönlü sözlüklerle (`.str`) harici bir arama sunucusuna ihtiyaç duymadan anlık kategori filtreleri üretir.

---

## Mimari Karşılaştırma Tablosu

| Özellik | AmberDB | SQLite | Geleneksel RDBMS (PostgreSQL/MySQL) |
| :--- | :--- | :--- | :--- |
| **Mimari** | Gömülü (Uygulama İçi Perl Objesi) | Gömülü C Kütüphanesi | Ayrı İstemci-Sunucu Servisi |
| **Harici Bağımlılık** | Standart Perl (`DB_File`) | C Kütüphanesi / DBI Sürücüsü | Ayrı Sunucu, Ağ Protokolü, ORM |
| **Kayıt Modeli** | Esnek Dizi (Array Döküman) | İlişkisel Satır & Sütunlar | İlişkisel Satır & Sütunlar |
| **İlişkisel JOIN** | JOIN'siz İç İçe Kayıtlar | SQL `JOIN` | SQL `JOIN` |
| **İndeks Mimarisi** | 64-bit Paketli İkili (`Q*`) | B-Tree | B-Tree / GiST / GIN |
| **Tam Metin Arama** | Dahili (Aksan & Dil Uyumlu) | SQLite FTS5 Modülü | Dahili Arama / Harici (Elasticsearch) |
| **Facet Filtreleme** | Dahili Kolonik Bitwise (`.fac`) | Manuel Sorgular | Manuel Sorgular / Harici Motor |
| **ACID İşlemler** | Undo Journal + Strict 2PL | WAL / Rollback Journal | WAL / MVCC |

---

## Kaynaklar ve Topluluk

* **GitHub Deposu:** [https://github.com/marufcetin/amberdb](https://github.com/marufcetin/amberdb)
* **Kapsamlı Proje Wiki:** [https://github.com/marufcetin/amberdb/wiki](https://github.com/marufcetin/amberdb/wiki)
* **MetaCPAN Paketi:** [https://metacpan.org/pod/AmberDB](https://metacpan.org/pod/AmberDB)
* **Hata Bildirimi & Sorular:** [https://github.com/marufcetin/amberdb/issues](https://github.com/marufcetin/amberdb/issues)
* **Lisans:** [Artistic License 2.0](https://github.com/marufcetin/amberdb/blob/main/LICENSE)
