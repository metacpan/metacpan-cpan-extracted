---
layout: default
title: 600,000 Gerçek IMDb Kaydıyla Büyük Veritabanı Benchmarkı - AmberDB vs SQLite 3
description: 600,000 gerçek IMDb filmi üzerinde AmberDB ve SQLite 3 karşılaştırmalı performans, derin sayfalama (read_all), ters dizin arama, çoklu alan filtreleme ve nokta okuma benchmark raporu.
---

[Ana Sayfa](index_tr.html) &nbsp;•&nbsp; [Hakkında](TR.AmberDB-Hakkinda.html) &nbsp;•&nbsp; [Hızlı Başlangıç](index_tr.html#hızlı-başlangıç) &nbsp;•&nbsp; [Tutorial](TR.AmberDB_Veritabani_Sistemi.html) &nbsp;•&nbsp; [Benchmark](TR.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](TR.AmberDB-Locale_Kullanim_Rehberi.html) &nbsp;•&nbsp; [SQL Rehberi](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) &nbsp;•&nbsp; [English](EN.AmberDB-vs-SQLite_Benchmark.html)

---

# 600,000 Gerçek IMDb Kaydıyla Büyük Veritabanı Benchmarkı: AmberDB vs SQLite 3

**Yayın Tarihi:** Eylül 2026 (Sürüm 5.24.0)  
**Yazar / Proje:** Maruf Çetin (AmberDB Projesi)  
**Test Ortamı:** Ubuntu 24.04 LTS (Linux Kernel 6.8.0) | 8 vCPU | 8 GiB RAM | Ext4 Dosya Sistemi  
**Test Edilen Motorlar:** **AmberDB v5.24.0** (Saf Perl + Berkeley DB) vs **SQLite 3** (v3.45.1 / `DBD::SQLite` + FTS5)  
**Veri Kümesi:** %100 Gerçek Dünya IMDb Resmi Dökümleri (**600,000 Uzun Metraj Sinema Filmi**)

---

## 1. Giriş ve Motivasyon

Bir veritabanı motorunun mimarisini ve sınırlarını anlamanın en sağlıklı yolu, onu sentetik oyuncak verilerle değil, **gerçek dünyanın karmaşık ve hacimli verileriyle** sınamaktır.

AmberDB ve SQLite arasındaki bu karşılaştırmalı benchmark çalışması, **resmi IMDb dökümleri (`datasets.imdbws.com`)** üzerinden 600.000 gerçek film verisi ile icra edilmiştir.

Bu raporda;
1. Yazma ve okuma bağlantılarının bellek önbelleği hilesini önlemek için nasıl fiziksel olarak ayrıldığı,
2. AmberDB'nin sabit 8-bayt ikili indeksleme yapısı sayesinde **derin sayfalamada (`read_all`) SQLite'ı nasıl 10 kat geride bıraktığı**,
3. Noktasal rastgele okumada (Point Read) **1.7 mikro-saniye ile SQLite'ı 5.3 kat geçtiği**,
4. Çoklu alan filtrelemesinde (Multi-Field Filter) **10.2 kat daha hızlı yanıt verdiği**,
5. Omnibox çapraz blok aramasında milisaniyenin altında tam satır çözümleme yeteneği

tüm şeffaflığı ve ölçüm tablolarıyla belgelenmiştir.

---

## 2. Metodoloji ve Adil Test İlkeleri

### A. Yazma ve Okuma Oturumlarının Fiziksel Olarak Ayrılması (Severed Lifecycle)
* **SQLite:** Veriler eklendikten sonra `PRAGMA wal_checkpoint(TRUNCATE)` komutuyla WAL günlüğü ana veritabanı dosyasına yazıldı, tüm ifade tanıtıcıları (`$sth`) serbest bırakıldı ve veritabanı bağlantısı (`$dbh->disconnect`) tamamen kapatıldı.
* **AmberDB:** Tüm veri ve indeks tabloları (`table_close`) ile diske yazılıp kapatıldı ve nesne bellekten düşürüldü.
* **İzole Süreçler (Isolated Processes):** Her iki motor tamamen ayrı işletim sistemi süreçlerinde çalıştırıldı ve süreçler arasında 3 saniyelik CPU/RAM soğuma payı bırakıldı.

### B. %100 Gerçek Dünya Verisi (IMDb Dökümleri)
Resmi IMDb CloudFront sunucularından indirilen arşivler birleştirilerek 600.000 gerçek film, 227.000 yönetmen, 540.000 oyuncu ve gerçek IMDb puanları haritalandırılmıştır.

### C. SQLite Transaction ve Senkronizasyon Yapılandırması (ACID Güvencesi)
* **Tek Büyük Transaction:** Toplu ekleme tek bir transaction içinde yapılmıştır.
* **`PRAGMA synchronous = NORMAL;` (`OFF` Değil):** SQLite'ta disk dayanıklılığını feda eden hileli ayarlar kullanılmamış; üretim standardı olan WAL modu ve `NORMAL` senkronizasyon kullanılmıştır.

---

## 3. Karşılaştırmalı Ölçüm Tablosu (600,000 Kayıt)

Aşağıdaki ölçümler, Linux Ext4 dosya sistemi üzerinde önceden diske yazılmış gerçek 600.000 film verisi üzerinden taze süreçlerle alınmıştır:

| Test Senaryosu / Metrik | SQLite 3 (FTS5 İndeksli) | AmberDB v5.24.0 (İndeksli) | Kazanan / Fark |
| :--- | :---: | :---: | :---: |
| **Toplam Kayıt Sayısı** | 600,000 film | 600,000 film | - |
| **Noktasal Okuma (Point Read Latency)** | 9.0 µs | **1.7 µs** | **AmberDB (5.3 Kat Daha Hızlı - 588K ops/s)** |
| **Sayfalamalı Derin Tarama (`offset=430K`, limit=20)** | 32.59 ms | **3.26 ms** | **AmberDB (10 Kat Daha Hızlı!)** |
| **Çoklu Alan Filtreleme (Yönetmen + Tür + Dil)** | 91.84 ms | **8.96 ms** | **AmberDB (10.2 Kat Daha Hızlı!)** |
| **Tek Blok Çekme (Yönetmenin Tüm Filmleri)** | 24.05 ms | **21.99 ms** | **AmberDB (Daha Hızlı)** |
| **Tarih Aralığı Filtresi (1990-2016)** | **0.22 ms** | 2.79 ms | İkisi de son derece hızlı (sub-3ms) |
| **Çapraz Blok Arama (`Canadian Moore`)** | **0.32 ms** | 1.00 ms | İkisi de milisaniye seviyesinde |
| **Omnibox Arama (`beyaz 2012 ölü`)** | **0.23 ms** | 0.46 ms | İkisi de yarım milisaniyenin altında |
| **Omnibox Arama (`venky 2003 nenu`)** | **0.22 ms** | 0.44 ms | İkisi de yarım milisaniyenin altında |
| **Omnibox Arama (`natale 1996 green`)** | **0.38 ms** | 0.99 ms | İkisi de 1 milisaniyenin altında |
| **Disk Ayak İzi (Tüm İndeksler Dahil)** | **488.91 MB** | 522.95 MB | Neredeyse eşit (AmberDB sadece %7 fark) |
| **Toplu Veri Yükleme (Bulk Ingest)** | **12.55 sn** (47,814 k/sn) | 433.64 sn (1,384 k/sn) | SQLite (Derlenmiş C) |

---

## 4. Mimari Analiz ve Bulgular

### A. Noktasal Okumada 1.7 Mikro-Saniye: Doğrudan C-Seviyesi Anahtar Erişimi ve ABR v5
AmberDB, `table_readid` veya `read_id` ile rastgele bir kayıt kimliği sorguladığında:
* SQL ayrıştırma (parsing), execution plan hazırlama veya ifade tanıtıcısı (`$sth`) maliyeti tamamen sıfırdır.
* Berkeley DB (`DB_File`) C kütüphanesi üzerinden doğrudan anahtar erişimi (`$db->get($id, $rec)`) yapılır.
* Alınan ham kayıt verisi, AmberDB v5.24.0'ın yüksek başarımlı ikili serileştiricisi (ABR v5) ile tek hamlede çözülür.
* Bu sayede AmberDB tekil okumalarda **1.7 mikro-saniye** gecikme süresine ve saniyede **588.000 sorgu** hızına ulaşarak SQLite'ı (9.0 µs / 111.000 ops/sn) 5.3 kat geride bırakır.

### B. `read_all` Derin Sayfalamada Neden AmberDB 10 Kat Hızlı?
Modern web uygulamalarında derin sayfalama (örn: 600K kaydın 430.000'inci satırına atlamak) B-Tree motorları için zordur:
* **SQLite:** B-Tree yaprak düğümlerinde 430.000 kaydı tek tek yürümek (traverse etmek) zorundadır. Bu işlem C seviyesinde bile **32.59 ms** sürer.
* **AmberDB:** `.inx` sıralı anahtar dosyasında `430.717 * 8 bayt = 3.445.736` baytlık noktaya anında atlar ve sadece hedef 20 kaydın ID'sini çıkarır. İşlem **3.26 ms** sürer (**10 kat daha hızlı**).

### C. Çoklu Alan Filtrelemesinde 10.2 Kat Hız: Saf İndeks İkili Arama
Yönetmen + Tür + Dil gibi birden fazla koşul kesiştiğinde:
* SQLite FTS5 ve B-Tree birleşiminde 91.84 ms harcarken;
* AmberDB v5.24.0, 8-bayt hizalı ikili indeks üzerinde **Adaptive Binary Search Pruning (`bin_crop`)** uygulayarak dev union hash'leri kurmadan işlemi **8.96 ms**'de bitirir.

---

## 5. Testi Kendi Ortamınızda Çalıştırma (Reproducibility)

Tüm testler ve sürücüler `benchmark/` dizininde açık kaynak olarak yer almaktadır:

```bash
# 1. Depoyu klonlayın
git clone https://github.com/marufcetin/amberdb.git
cd amberdb

# 2. Resmi IMDb dökümlerini indirip 600K+ master veri kümesini oluşturun (~633K gerçek film)
perl benchmark/download_real_imdb.pl

# (Alternatif: İndirmeden anında çevrimdışı test verisi üretmek isterseniz)
# perl benchmark/data/prepare_data.pl --generate --total=100000

# 3. 600K benchmark testini izole süreçlerde başlatın
perl -Ilib benchmark/run_benchmark.pl total=600000 motors=amberdb,sqlite -with-index -random action=read
```

---

## 6. Genel Değerlendirme

SQLite, C dilinde 24 yıldır mikrosaniye düzeyinde optimize edilmiş bir başyapıttır. Derlenmiş C motoru sayesinde toplu veri yüklemede (ingest) tartışmasız bir hıza sahiptir.

Buna karşın, **saf Perl ile yazılmış AmberDB v5.24.0'ın** ortaya koyduğu sonuçlar yazılım mimarisi açısından tarihi bir ders niteliğindedir:

> **"Doğru algoritma ve veri yapısı seçimi, saf C derleme avantajını bile geride bırakabilir."**

AmberDB'nin 600.000 gerçek sinema filmi üzerinde:
* Derin sayfalamada SQLite'ı **10 kat geride bırakarak 3.26 ms'de yanıt vermesi**,
* Noktasal okumalarda **1.7 mikro-saniye ile 5.3 kat daha hızlı olması**,
* Çoklu alan filtrelemesinde **10.2 kat fark atarak 8.96 ms'de tamamlaması**,
* Serbest metin ve Omnibox aramalarında **0.4 - 0.9 ms** bandında tam satır döndürmesi,

AmberDB'nin gömülü veri yönetimi ve NoSQL dizinleme alanında ne kadar yenilikçi ve güçlü bir alternatif olduğunu somut olarak kanıtlamıştır.
