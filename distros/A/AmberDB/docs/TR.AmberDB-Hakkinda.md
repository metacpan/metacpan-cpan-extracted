[Ana Sayfa](index_tr.html) &nbsp;•&nbsp; [Hakkında](TR.AmberDB-Hakkinda.html) &nbsp;•&nbsp; [Hızlı Başlangıç](index_tr.html#hızlı-başlangıç) &nbsp;•&nbsp; [Tutorial](TR.AmberDB_Veritabani_Sistemi.html) &nbsp;•&nbsp; [Benchmark](TR.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](TR.AmberDB-Locale_Kullanim_Rehberi.html) &nbsp;•&nbsp; [SQL Rehberi](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [English](EN.About_AmberDB.html)

---

# Hakkında

AmberDB, JSON benzeri iç içe ve karmaşık yapıları destekleyen Array tabanlı kayıtları işleyen, Perl için gömülü bir NoSQL veritabanı motorudur. Şema tanımlarıyla oluşturulan özel indeksleri sayesinde blok eşleştirme, sorgulama, tam metin arama, filtreleme ve sıralama işlemlerini hızlı bir şekilde gerçekleştirirken şemasız ve indexsiz de aynı arama sorgulama kalitesini koruyabilir.

Standart Perl paketinin sağladığı Berkeley DB (DB_File)'nin C kodu üzerine inşa edilmiştir ve başka bir veritabanı motoru kullanmamaktadır. DB_File, Berkeley DB'nin Perl üzerinden anahtar-değer erişimi sağlayan düşük seviyeli arayüzüdür. AmberDB bunun üzerinde bir veri modeli, indeksleme, sorgulama, transaction ve yedekleme katmanı oluşturur.

## Neden AmberDB?

AmberDB, tek bir Perl veritabanı motorunda çeşitli yetenekleri bir araya getirir:

- Hiçbir harici veritabanı sunucusu kullanmaz
- Uygulamanın içine bir obje olarak dahil edilir
- Veritabanı kayıtları iç içe yapıları destekleyen bir Array (liste)dir. 
- Tüm CRUD işlemlerini yapar, 
- Hem indexli hem de indexsiz çalışır
- Index için ayrı bir kurulum gerektirmez
- Tam metin arama (hem indexli hem indexsiz)
- Sıralama ve çok yönlü sorgular
- İlişkisel ve tekrarlanan veri bloklarını otomatik yönetme
- Çok tablolu ilişkisel işlemleri yönetme
- ACID uyumlu transaction
- Alışveriş sitelerindeki gibi facet filtreleme oluşturma
- Ayrı sunucu gerektirmeyen gömülü RAM-Disk hızlandırma katmanı
- Yüksek verimli toplu kayıt işleme
- Kullanıcıların her kayıt için yaptığı işlemleri loglama
- Tablo tanımına özgü yumuşak silme, (silinen kaydı bir yerde saklar)
- Bir tablo için otomatik olarak seo/slug oluşturabilme
- Taşınabilir veritabanı arşivleri ve geri yükleme araçları

AmberDB, basit bir ilke üzerine kurulmuştur:

Veritabanı, yaygın uygulama veri işlemlerini basit, hızlı ve tahmin edilebilir hale getirmelidir.

Kısa bir giriş örneğine bakalım:

```perl
# modülü çağır
use AmberDB;

# nesneyi oluştur
my $adb = AmberDB->new(
	cfg => { user => 'admin', language => 'gb' },
	path => { dbase_dir => './dbstore' }
);

# ürün kaydını tanımla
my @product = (
	0,                       # id
	"Kablosuz Kulaklıklar",  # name
	149.99,                  # price
	"Sony",                  # brand
	"Elektronik",            # category
	{ statu => "Satışta" }   # statu hashref
);

# urun kaydını "products" tablosuna gir.
my $id = $product[0] = $adb->insert_id(
	"products", # tablo
	@product   # kayıt
);

# Kaydı geri okuma:
my @product_fromdb = $adb->read_id("products", $id);

# Veritabanından okuduğumuz kaydı yazdıralım
print "Fiyatı: $product_fromdb[2], Durum: $product_fromdb[5]->{statu}";

# Değiştirme:
$product[2] = 129.99; # 2 nolu bloka yeni değer atadıktan sonra modify_id ile kaydı değiştirelim.
$adb->modify_id(
	"products",
	@product
);

# Arama:
my @search_result = $adb->search_table("products", "sony elektronik kulaklıklar");
foreach my $product (@search_result) {
	print "Urun ID: $product->[0]\n";
	print "Name   : $product->[1]\n";
	print "Price  : $product->[2]\n";
	print "Statu  : $product->[5]->{statu}\n";
}
# AmberDB'nin `search_table` metodu çok güçlüdür ve bir tablodaki her şeyi bulur. Yani kayıtları oluşturan array'ın derinliklerindeki listeler ve hash anahtar ve değerlerin içinde geçen ifadeleri de bulabilir.

# Ve silme:
$adb->delete_id("products", $id);
```

Bu, temel CRUD API'si örneğidir.

Bir SQL sorgusu kullanılmıyor, ORM gerekmiyor ve Perl uygulaması ile veritabanı arasında ayrı bir sorgu dili yok. Bu nedenle, uygulamanızda veritabanı erişimi, sıradan Perl objesinin kullanımına çok benzer görünebilir.

## Gelişmiş uygulamalar için şemaların kullanımı

AmberDB, şema tanımı olmadan çalışır. Küçük tablolarda (örneğin 10K) kullanışlı olabilir ancak milyonlara varan büyük ve ilişkisel tablolar düşünüyorsanız indexi tablo şemalarında bağlamanız gerekir. Şemalar, bir tablonun yapısını ve verilerinin nasıl indekslenmesi ve aranması gerektiğini tanımlayarak motorun yeteneklerini önemli ölçüde artırabilir.

Bir AmberDB nesnesi başlattığınızda dbase_dir olarak girdiğiniz dizinin altında "schema" isimli bir dizin oluşturacak. .table uzantılı şemaları burada oluşturmalısınız.

```perl
my $adb = AmberDB->new(
	path => { dbase_dir => './dbstore' }
);
# "dbstore/schema" oluşacaktır.
```

Her tablonun aynı isimde bir şeması vardır. Yukarıdaki örnekte "products" tablosunun şeması "dbstore/schema/products.table" altında olması gerekir. Yapılandırılacak ayrı bir indeksleme sistemi yoktur. Şema tanımlandıktan sonra, AmberDB gerekli indeksleri otomatik olarak oluşturur.

Örneğin:

```perl
# dbstore/schema/products.table
{
	name         => "Tablo Adı",
	record_index => 1,         # tüm kayıt anahtarları indexlenecek
	search_block => [2,4,5,8], # bu bloklardaki arama kelimeleri indexlenecek
	match_block  => [1,3,8],   # bu bloklarda tam eşleştirme indexleri
	sort_block   => [1,3,5,7], # bu bloklarda sıralama indexleri
}
```

AmberDB, tablo şeması tarafından tanımlanan bloklar için otomatik olarak ters indeksler oluşturur. Bu indeksler, büyük veri kümelerinde bile çok hızlı arama ve filtreleme işlemleri sağlar. Şema konusunu ayrıca derinlemesine inceleyiniz. Çünkü şemalar sayesinde karmaşık veri tabloları oluşturulabilir. 

## Kayıtları taramak yerine indeksli okuma

AmberDB, index sistemi sorgular sırasında tekrar tekrar pahalı işler yapmak yerine, veriler eklendiğinde veya indeksler yeniden oluşturulduğunda işin büyük bir kısmını gerçekleştirmek üzere tasarlanmıştır.

Bu, filtreleme, sıralama, sayfalama ve büyük veri kümelerinde arama gibi işlemleri harici bir arama sunucusuna ihtiyaç duymadan mümkün ve basit kılar.

Örneğin:

```perl
my ($total, @products) = $adb->search_table(
	"products",             # tablo id
	"kablosuz kulaklıklar", # aranan string
	{
		offset => 0,             # sayfalama için nereye atlayacak
		limit  => 20             # her sayfada kaç kayıt okunacak
	}
);
```

Bu örnekte "products" tablosundan "kablosuz kulaklıklar" stringinin geçtiği tüm kayıtlardan ilk 0-20 aralığının tüm bilgilerini @products içinde array of array olarak getirir. Index sayesinde veritabanında milyonlarca kayıt olsa bile sonuç milisaniyeler içinde gerçekleşecektir.

**Önemli Not:** "search_table"ye `limit` parametresi verilirse dönüşün en başına "$total" değerini döndürür. $total ise veri tablosunda bu aramaya uyan kaç sonucun olduğunu bildirir. Sayfalama için gerekli. 

## AmberDB birleştirme yapmaz.

Bir kayıt, diğer tablolardan ilişkisel veriler içerebilir veya bunlara bağlanabilir. Örneğin, bir sipariş kaydı müşteri bilgileri, ödeme bilgileri, kargo ve teslimat bilgileri, çeşitli tarihler ve ürün numarası, adı, satış anındaki fiyatı, uygulanan indirim ve diğer bilgileri içeren bir sipariş kalemleri koleksiyonu içerebilir.

AmberDB bu yapıları kayıt modelinin bir parçası olarak işler ve sorgulamayı kolaylaştırmak için arka planda motor düzeyinde özel indeksler kullanır.

Bu, uygulamanın doğal modeli aşağıdaki gibi olduğunda faydalı olabilir:

Sipariş

```text
├── Sipariş ID
├── Müşteri ID
├── Adres
├── Tarihler [dizi olarak, sipariş tarihi, kargolama tarihi, teslim tarihi]
├── Ödeme
├── Statü
└── Ürünler (tekrar eden satırlar, her satır bir dizi)
   ├── Ürün ID
   ├── Ürün Adı
   ├── Miktar
   ├── Fiyat
   └── İndirim
```

Uygulama, SQL'de olduğu gibi bilgileri birden fazla tabloya dağıtmak ve okuma sırasında birleştirmek yoluyla yeniden oluşturmak yerine, Perl'in kendi veri modeline çok daha yakın bir şekilde, doğrudan tek bir değişken (array) olarak tutar.

## Transaction ve ACID Uyumluluğu

AmberDB, performans odaklı bir NoSQL motoru olmasına rağmen, geri alma günlüğü ve Sıkı İki Aşamalı Kilitleme (Strict 2PL) kullanarak çok tablolu ACID işlemleri sağlar. AmberDB, işletim sistemi düzeyinde dosya kilitleme kullanarak eşzamanlı erişimi de destekler ve bu da onu çoklu işlem Perl uygulamaları için uygun hale getirir. AmberDB Transaction API'si kullanımı kolaydır ve arkasındaki mekanizmalar ilgili işlemler arasında atomiklik, tutarlılık, izolasyon ve kalıcılık sağlar.

```perl
$adb->transact_start();

# sipariş durumunu güncelle
# müşteri hesabını güncelle
# stok güncelle
# ödeme kaydı ekle

$adb->transact_end();
```

Bir hata oluşursa, ilgili indeks değişiklikleri de dahil olmak üzere tüm işlem geri alınır. Geri alma günlüğü ayrıca beklenmedik bir işlem veya sistem hatasından sonra kurtarma sağlar.

## Büyük içe aktarmalar için toplu işlemler

Toplu veri yükleme ve işleme için AmberDB batch işlemlerini kullanır. XML, ETL, CSV gibi içe aktarma yoluyla toplu kayıt yükleme, mevcut kayıtlarda değişiklik yapma (örneğin fiyat listesini güncelleme) veya toplu silme için yöntemler sunar. Batch işlemleri kayıtları yenilerken tüm indexleri de tek seferde günceller.

AmberDB, aşağıdaki gibi toplu yöntemler sunar:

```perl
$adb->insert_list("products", @kayıtlar);  # liste ekleme
$adb->modify_list("products", @kayıtlar);  # liste değiştirme
$adb->delete_list("products", @kimlikler); # liste silme
```

Örneğin, insert_list kullanarak bin kayıttan oluşan bir liste eklediğinizde, AmberDB kayıtları ve indekslerini toplu bir işlem olarak oluşturur. Benzer şekilde, büyük bir fiyat listesi tek bir toplu işlemde değiştirilebilir. Bu, toplu işlem yöntemlerini özellikle içe aktarma, geçiş, senkronizasyon işleri ve diğer yüksek hacimli veri işlemleri için kullanışlı hale getirir.

## Taşınabilir yedeklemeler

AmberDB dosya tabanlı olduğu için tümüyle taşınabilir. Ayrıca yedekleme ve geri yükleme için daha güvenli yerel veritabanı araçları da içerir.

Bir veritabanı, yetkili veritabanı durumunu ve şemasını içeren taşınabilir bir .amberdb arşivine dışa aktarılabilir. Bütünlük SHA-256 kullanılarak doğrulanır ve geri yükleme sırasında türetilmiş indeksler yeniden oluşturulur. Bu, ayrı bir veritabanı sunucusuna ihtiyaç duymadan eksiksiz bir veritabanını taşımayı veya arşivlemeyi mümkün kılar. Bu işlem kronolojik yedekleme ve arşivleme için de oldukça elverişlidir.

## Sonsöz

AmberDB PostgreSQL+ElasticSearch+Redis'e yakın bir deneyim sunar ve bunları çok düşük bir maliyet ile oluşturur. Ayrı bir sunucu kurulumu gerektirmez, uygulamanıza gömülür. Sistem kaynaklarını çok az kullanır. Arama ve sorgulamalarda çok hızlıdır ve milyonlara varan büyük veri dosyalarında da dar boğaz yaratmaz. Çok küçük işlerde de, çok büyük ve karmaşık projelerde de uygundur. 

AmberDB, Artistic License 2.0 altında yayınlanmıştır. Kaynak kod, dokümantasyon ve örnekler CPAN'da ve Github'ta mevcuttur ve sürekli güncellenmektedir. 

Soru, öneri ve hata bildirimlerinizi [GitHub Issues](https://github.com/marufcetin/amberdb/issues) sayfası üzerinden iletebilirsiniz. 

Eğer veritabanı sistemleri ile ilgileniyorsanız veya bir Perl geliştiricisiyseniz, AmberDB'yi inceleyin, deneyin.
