[Ana Sayfa](index_tr.html) &nbsp;•&nbsp; [Hakkında](TR.AmberDB-Hakkinda.html) &nbsp;•&nbsp; [Hızlı Başlangıç](index_tr.html#hızlı-başlangıç) &nbsp;•&nbsp; [Tutorial](TR.AmberDB_Veritabani_Sistemi.html) &nbsp;•&nbsp; [Benchmark](TR.AmberDB-vs-SQLite_Benchmark.html) &nbsp;•&nbsp; [Locale](TR.AmberDB-Locale_Kullanim_Rehberi.html) &nbsp;•&nbsp; [SQL Rehberi](TR.AmberDB-vs-SQL_Kullanim_Rehberi.html) &nbsp;•&nbsp; [Changes](https://github.com/marufcetin/amberdb/blob/main/Changes) &nbsp;•&nbsp; [Wiki](https://github.com/marufcetin/amberdb/wiki) &nbsp;•&nbsp; [English](EN.AmberDB-Locale_User-Guide.html)

---

# AmberDB::Locale - Kapsamlı Rehber

---

## 1. Genel Bakış

`AmberDB::Locale`, çok dilli uygulamalar için tasarlanmış **yerel (locale) duyarlı bir metin işleme motorudur**. Perl dilinde yazılmış olup aşağıdaki temel yetenekleri sunar:

| Yetenek | Açıklama |
|---|---|
| Büyük/küçük harf dönüşümü | Dil kurallarına uygun `uc`, `lc`, `ucfirst` |
| Sıralama | Unicode Collation Algorithm (UCA) tabanlı |
| ASCII dönüşümü | Aksanlı karakterleri düz ASCII'ye çevirme (slug, ID üretimi) |
| Sayı → Metin | Fatura/belge yazımı için sayıların yazıyla ifadesi |
| Tarih/saat biçimlendirme | Locale özgü tarih formatları |
| Sayı/para birimi biçimlendirme | Binlik ayraç, ondalık ayraç, sembol yerleşimi |
| HTML entity çözümleme | Named + numeric entity decode |
| Çoğul kuralları | CLDR tabanlı plural form seçimi |
| UTF-8 güvenli substring | Karakter bazlı kesme (byte değil) |

**Mimari prensip:** Motor mantığı `AmberDB::Locale.pm`'de, dil verileri ise `AmberDB::Locale::Lang::*` paketlerinde **saf data** olarak tutulur. Motor ve veri tamamen ayrılmıştır.

---

## 2. Mimari

```
AmberDB::Locale                 ← Ana motor (tüm mantık burada)
├── AmberDB::Locale::Lang::gb   ← Global Base veri (varsayılan/fallback)
├── AmberDB::Locale::Lang::en   ← İngilizce veri
├── AmberDB::Locale::Lang::tr   ← Türkçe veri
├── AmberDB::Locale::Lang::de   ← Almanca veri
├── AmberDB::Locale::Lang::fr   ← Fransızca veri
├── AmberDB::Locale::Lang::es   ← İspanyolca veri
├── AmberDB::Locale::Lang::ru   ← Rusça veri
├── AmberDB::Locale::Lang::az   ← Azerice veri
├── AmberDB::Locale::Lang::ar   ← Arapça veri
├── AmberDB::Locale::Lang::ja   ← Japonca veri
└── AmberDB::Locale::Currency   ← ISO 4217 evrensel para birimi verisi
```

Her `Lang::*` modülü yalnızca `data()` adlı tek bir subroutine içerir ve bir hash-ref döndürür. **Hiçbir mantık barındırmaz.**

---

## 3. Nesne Oluşturma (Constructor)

```perl
use AmberDB::Locale;

# 1) Named-param API (önerilen)
my $lang = AmberDB::Locale->new(language => "tr");

# 2) Hashref API
my $lang = AmberDB::Locale->new({ language => "de" });

# 3) Pozisyonel string API
my $lang = AmberDB::Locale->new("fr");

# 4) Argümansız → varsayılan "gb" (Global Base)
my $lang = AmberDB::Locale->new();
```

### Dahili davranışlar

- **Önbellekleme:** Aynı dil için ikinci `new()` çağrısı mevcut nesneyi döndürür (singleton benzeri).
- **Alias desteği:** `"global"`, `"gl"`, `"turkish"`, `"tr_tr"`, `"tr-tr"` gibi etiketler otomatik olarak eşlenir.
- **Fallback:** Bilinmeyen bir dil istenirse `cluck` ile uyarı verilir ve `gb`'ye düşülür.
- **Collator:** `Unicode::Collate::Locale` yüklenmeye çalışılır; başarısız olursa `Unicode::Collate` tabanına, o da yoksa özel `sort_map` Schwartzian transform'una düşülür.

### AmberDB entegrasyonu

```perl
# cfg üzerinden dil otomatik çekilir
my $db = AmberDB->new(cfg => { language => "tr" });
$db->uc("ığdır");   # kalıtım yoluyla çalışır
```

---

## 4. Dil Veri Yapısı (`data()` Hash-Ref)

Her dil modülünün döndürdüğü yapının tam şeması:

```perl
{
    uc_map          => { },   # uc() öncesi karakter eşleme
    lc_map          => { },   # lc() öncesi karakter eşleme
    sort_map        => { },   # Özel sıralama ağırlıkları (collator yoksa)
    alphabet_chars  => "...",  # normalize() için güvenli karakter sınıfı
    accent_map      => { },   # normalize() aksan → yerel eşdeğer
    ascii_map       => { },   # to_ascii() NFD öncesi ön eşleme
    numbers         => { },   # num2text sayı kelimeleri
    html_entities   => { },   # Locale'e özgü ek HTML entity'ler
    months          => [ ],   # 12 elemanlı ay adları
    days            => [ ],   # 7 elemanlı gün adları (Pazar → Cumartesi)
    number_format   => { },   # Ondalık/binlik ayraç ayarları
    default_currency    => "",
    currency_position   => "prefix|suffix",
    currency_space      => 0|1,
    date_format     => { },   # short, medium, long, full, time, datetime
    plural_rule     => "...", # CLDR çoğul kural ifadesi
}
```

---

## 5. Public API - Metot Referansı

### 5.1 Büyük/Küçük Harf Dönüşümleri

#### `uc($string)` - Büyük harfe çevir

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->uc("ığdır");       # "IĞDIR"
$tr->uc("istanbul");    # "İSTANBUL"  (i → İ, Türkçe kural)

my $de = AmberDB::Locale->new(language => "de");
$de->uc("straße");      # "STRASSE"   (ß → SS)
```

> **Türkçe detay:** `uc_map` içinde `'i' => "\x{130}"` eşlemesi Perl'in `CORE::uc()` çağrısından **önce** uygulanır. Böylece `i → İ` dönüşümü doğru yapılır.

#### `lc($string)` - Küçük harfe çevir

```perl
$tr->lc("İSTANBUL");    # "istanbul"  (İ → i, I → ı)
$tr->lc("IĞDIR");       # "ığdır"
```

> `lc_map` içinde `'I' => "\x{131}"` ve `"\x{130}" => 'i'` eşlemeleri `CORE::lc()` öncesi uygulanır.

#### `ucfirst($string)` - Kelime başlarını büyüt

```perl
$tr->ucfirst("istanbul büyükşehir belediyesi");
# "İstanbul Büyükşehir Belediyesi"
```

Önce tamamı `lc()` ile küçültülür, ardından boşluk, nokta, ünlem, iki nokta, tırnak, `/`, `(`, `)` sonrası ilk karakter büyütülür.

#### `fold($string)` - Arama için normalizasyon

```perl
my $key = $tr->fold("İSTANBUL");   # "istanbul" (NFKC + lc)
```

Unicode NFKC ayrıştırması + locale `lc()` uygular. Arama indeksleme ve eşleştirme için tasarlanmıştır.

#### `ieq($str1, $str2)` - Büyük/küçük harf duyarsız karşılaştırma

```perl
$tr->ieq("İstanbul", "istanbul");  # 1 (true)
$tr->ieq("Ankara", "ankara");      # 1 (true)
$tr->ieq("Ankara", "İzmir");       # 0 (false)
```

Varsa `Unicode::Collate::Locale` collator'ı ile karşılaştırır, yoksa `fold()` sonuçlarını `eq` ile kıyaslar.

---

### 5.2 Sıralama

#### `sort(\@list [, $field])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");

# Basit dizi sıralama
my @sorted = $tr->sort(["İzmir", "Ankara", "Van", "Şanlıurfa", "Bursa", "Çanakkale"]);
# => ("Ankara", "Bursa", "Çanakkale", "İzmir", "Şanlıurfa", "Van")

# Hashref dizisi - alan adına göre
my @sorted = $tr->sort(\@products, "name");

# Arrayref dizisi - indeks numarasına göre
my @sorted = $tr->sort(\@rows, 2);
```

**Sıralama stratejisi (öncelik sırası):**
1. `Unicode::Collate::Locale` (locale özgü UCA tablosu)
2. `Unicode::Collate` (taban UCA)
3. Özel `sort_map` Schwartzian transform (son çare)

---

### 5.3 Metin Normalizasyonu

#### `normalize($string)` - Temizleme

```perl
my $clean = $tr->normalize('<p>Kâr &amp; zarar &ccedil;izelgesi</p>');
# "Kar zarar cizelgesi"
```

İşlem sırası:
1. HTML entity çözümleme (`decode_entities`)
2. HTML tag kaldırma (`<...>` → boşluk)
3. Kalan entity'leri temizleme
4. `accent_map` uygulama (ör. `â → a`, `ô → ö`)
5. Güvenli karakter sınıfı dışındakileri silme
6. Fazla boşlukları teke indirme, kenar boşluklarını kırpma

#### `to_ascii($string [, $nonspace])` - ASCII dönüşümü

```perl
$tr->to_ascii("çarşı");           # "carsi"
$tr->to_ascii("İstanbul", 1);     # "istanbul"  (slug modu)
$tr->to_ascii("Große Straße");    # "Grosse Strasse" (de locale)

my $de = AmberDB::Locale->new(language => "de");
$de->to_ascii("Müller");          # "Mueller"  (DIN 5007-2: ü → ue)
```

İşlem sırası:
1. İsteğe bağlı `lc()` (`$nonspace` verilirse)
2. `normalize()`
3. `ascii_map` uygulama (NFD ile çözülemeyen karakterler: `ı → i`, `ß → ss`, `ä → ae` vb.)
4. NFD ayrıştırma + `\p{M}` (birleşim işaretleri) silme
5. `[a-z0-9,.\-_ ]` dışındakileri temizleme
6. `$nonspace` modunda: boşluklar → `_`, alt çizgi tekrarı temizliği

---

### 5.4 Sayı → Metin Dönüşümü

#### `num2text($number [, %options])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->num2text(0);           # "Sıfır"
$tr->num2text(1);           # "Bir TL"
$tr->num2text(1000);        # "Bin TL"          (Bir Bin DEĞİL)
$tr->num2text(100);         # "Yüz TL"          (Bir Yüz DEĞİL)
$tr->num2text(1234.56);     # "Bin İki Yüz Otuz Dört TL Elli Altı KR"
$tr->num2text(-42);         # "Eksi Kırk İki TL"

# Özel para birimi ile
$tr->num2text(99.99, currency => { main => "EUR", sub => "cent" });

# Tamamen özel sayı verisi ile
$tr->num2text(5, numbers => { zero => "Yok", ones => [...], ... });
```

**Desteklenen seçenekler:**

| Seçenek | Açıklama |
|---|---|
| `currency => { main => "...", sub => "..." }` | Ana/alt para birimi adları |
| `numbers => \%hash` | Tam veya kısmi sayı kelime verisi override |

**Locale'e özgü kurallar:**

| Kural | Açıklama | Örnek (tr) |
|---|---|---|
| `hundred_one_prefix` | 100 için "Bir" öneki | `0` → "Yüz" |
| `thousand_one_prefix` | 1000 için "Bir" öneki | `0` → "Bin" |
| `decimal_sep` | Ondalık ayraç | `','` → "1.234,56" formatı |

> Doğu Arap rakamları (`٠١٢٣٤٥٦٧٨٩`) ve Fars rakamları (`۰۱۲۳۴۵۶۷۸۹`) otomatik olarak Batı rakamlarına çevrilir.

---

### 5.5 Metin Temizleme ve Güvenli Karakterler

#### `safe_chars($string)`

```perl
$lang->safe_chars("merhaba dünya! @#$ 123");
# "merhaba dünya 123"
```

Dilin `alphabet_chars` tanımına uymayan tüm yabancı/özel karakterleri temizler.

---

### 5.6 Arama ve Fonetik Kelime Normalizasyonu

`AmberDB` tam metin arama motorunun temelini oluşturan dil ve fonetik analiz metotlarıdır:

#### `normalize_word($word [, $mode_write])`

Arama indeksleme ve sorgu eşleştirme için kelimeyi fonetik ve morfolojik olarak normalize eder:

```perl
my $tr = AmberDB::Locale->new(language => "tr");

# 1. Okuma / Sorgu modu (varsayılan, mode_write = 0): Ekleri temizler
$tr->normalize_word("Türkiye'nin"); # "turkiye" (kesme işaretinden sonraki 'nin' stop-word olarak yutulur)
$tr->normalize_word("Türkiye'de");  # "turkiye"

# 2. Yazma / İndeksleme modu (mode_write = 1): Kök ve birleşik hali birlikte indeksler
$tr->normalize_word("Türkiye'de", 1); # "turkiye turkiyede"

# 3. İnceltme / Düzeltme işaretleri
$tr->normalize_word("kârın");       # "karin"
$tr->normalize_word("ÂLÎM");        # "alim"

# 4. Kelime sonu ötümsüzleşme (Sertleşme / Fonetik dönüşüm)
$tr->normalize_word("tevhid");      # "tevhit"  (d$ => t)
$tr->normalize_word("gazab");       # "gazap"   (b$ => p)
$tr->normalize_word("mehmed");      # "mehmet"  (d$ => t)
```

#### `search_pattern($query)`

Arama sorgusu için çok dilli, esnek ve fonetik regex arama kalıpları derler:

```perl
my $pattern = $tr->search_pattern("Türkiye");
# "t[uü]rk[iıİI]y[eE]" gibi Türkçe ve ASCII varyantlarını kapsayan fonetik desen üretir
```

#### `search_regex($string, $pattern)`

Hedef metin (`$string`) içerisinde arama kalıbının (`$pattern`) locale kurallarıyla eşleşip eşleşmediğini kontrol eder. Eşleşirse `1`, eşleşmezse `0` döner:

```perl
my $bulundu = $tr->search_regex("İstanbul Boğazı", "istanbul"); # 1
my $eslesti = $tr->search_regex("İzmir Kordon", $pattern);      # 1
```

---

### 5.7 HTML Entity Çözümleme

#### `decode_entities($string)`

```perl
$lang->decode_entities("&amp; &lt; &gt; &#x20AC; &#8364; &ccedil;");
# "& < > € € ç"
```

Üç aşama:
1. **Hex numerik:** `&#x20AC;` → `€`
2. **Desimal numerik:** `&#8364;` → `€`
3. **Named entity'ler:** Evrensel set (`&amp;`, `&lt;`, `&nbsp;`, `&euro;`, vb.) + locale'e özgü ekler (`&ccedil;`, `&scaron;`, `&gbreve;`, vb.)

---

### 5.8 UTF-8 Güvenli Substring

#### `substring($string, [$offset], $length)`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->substring("Çanakkale", 0, 4);     # "Çana"  (4 karakter, 4 byte değil!)
$tr->substring("İstanbul", 2, 3);      # "tan"

# Raw UTF-8 byte string ile de güvenli:
my $raw = encode('UTF-8', "Şanlıurfa");
$tr->substring($raw, 0, 5);            # "Şanlı" (doğru şekilde re-encode edilir)
```

> `Encode::is_utf8()` ile string'in decode edilip edilmediği kontrol edilir. Raw byte ise `decode → substr → encode` zinciri uygulanır; böylece multibyte karakterler ortadan kesilmez.

---

### 5.9 Tarih/Saat İşlemleri

#### `format_date($time [, $pattern_or_style])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
my $epoch = time();   # örn: 2026-08-09

$tr->format_date($epoch);                    # "09.08.2026"
$tr->format_date($epoch, 'medium');          # "9 Ağu 2026"
$tr->format_date($epoch, 'long');            # "9 Ağustos 2026"
$tr->format_date($epoch, 'full');            # "Pazar, 9 Ağustos 2026"
$tr->format_date($epoch, 'time');            # "14:30"
$tr->format_date($epoch, 'datetime');        # "09.08.2026 14:30"

# Özel pattern
$tr->format_date($epoch, 'YYYY-MM-DD');     # "2026-08-09"
$tr->format_date($epoch, 'DD/MM/YYYY');     # "09/08/2026"

# Tarih string'i de kabul eder
$tr->format_date("2026-08-09", 'full');     # "Pazar, 9 Ağustos 2026"
```

**Desteklenen token'lar:**

| Token | Anlam | Örnek |
|---|---|---|
| `YYYY` / `YY` | 4/2 haneli yıl | 2026 / 26 |
| `MMMM` / `MMM` / `MM` / `M` | Ay adı / kısa / 2 haneli / tek | Ağustos / Ağu / 08 / 8 |
| `DD` / `D` | Gün (2 haneli / tek) | 09 / 9 |
| `dddd` / `ddd` | Gün adı / kısa | Pazar / Paz |
| `HH` / `H` | Saat | 14 / 14 |
| `mm` / `m` | Dakika | 05 / 5 |
| `ss` / `s` | Saniye | 09 / 9 |

**Kabul edilen giriş formatları:**
- Unix timestamp: `1786345200`
- Tarih string'i: `2026-08-09`, `2026/08/09`, `2026.08.09`
- Tarih + saat: `2026-08-09 14:30:00`, `2026-08-09T14:30`

#### `parse_date($string [, %opts])`

```perl
my $epoch = $tr->parse_date("09.08.2026");            # Unix timestamp
my $h     = $tr->parse_date("09.08.2026", hash => 1);
# { year => 2026, month => 8, day => 9, hour => 0, minute => 0, second => 0 }
```

> Kısa tarih formatı locale'in `date_format.short` değerine göre `GG.AA.YYYY` mı yoksa `AA/GG/YYYY` mı olduğu otomatik tespit edilir.

---

### 5.10 Sayı ve Para Birimi Biçimlendirme

#### `format_number($num [, %opts])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->format_number(1234567.89);              # "1.234.567,89"
$tr->format_number(1234567.89, decimals => 0); # "1.234.568"
$tr->format_number(1234567.89, decimals => 3); # "1.234.567,890"

my $en = AmberDB::Locale->new(language => "en");
$en->format_number(1234567.89);              # "1,234,567.89"

my $fr = AmberDB::Locale->new(language => "fr");
$fr->format_number(1234567.89);              # "1 234 567,89"
```

| Locale | Ondalık | Binlik | Örnek |
|---|---|---|---|
| `tr` | `,` | `.` | 1.234.567,89 |
| `en` | `.` | `,` | 1,234,567.89 |
| `de` | `,` | `.` | 1.234.567,89 |
| `fr` | `,` | *(boşluk)* | 1 234 567,89 |
| `ru` | `,` | *(boşluk)* | 1 234 567,89 |
| `ar` | `٫` | `٬` | ١٬٢٣٤٬٥٦٧٫٨٩ |

#### `format_currency($amount [, $code | %opts])`

```perl
my $tr = AmberDB::Locale->new(language => "tr");
$tr->format_currency(1234.50);                    # "₺1.234,50"
$tr->format_currency(1234.50, 'EUR');             # "1.234,50 €"  (suffix + space)
$tr->format_currency(1234.50, currency => 'USD'); # "$1.234,50"

my $de = AmberDB::Locale->new(language => "de");
$de->format_currency(1234.50, 'EUR');             # "1.234,50 €"
```

**Çözümleme önceliği:**
`%opts override` → `locale currencies` → `AmberDB::Locale::Currency` evrensel veri → varsayılan değerler

---

### 5.11 Çoğul Kuralları (Pluralization)

#### `plural($count, \%forms)`

```perl
my $en = AmberDB::Locale->new(language => "en");
$en->plural(1, { one => "{count} item",  other => "{count} items" });
# "1 item"
$en->plural(5, { one => "{count} item",  other => "{count} items" });
# "5 items"

my $tr = AmberDB::Locale->new(language => "tr");
$tr->plural(1, { one => "{count} ürün", other => "{count} ürün" });
# "1 ürün"
$tr->plural(5, { one => "{count} ürün", other => "{count} ürün" });
# "5 ürün"

# Rusça - 4 farklı form
my $ru = AmberDB::Locale->new(language => "ru");
$ru->plural(1,  { one => "{count} яблоко", few => "{count} яблока",
                  many => "{count} яблок",  other => "{count} яблока" });
# "1 яблоко"
$ru->plural(3,  { ... });   # "3 яблока"   (few)
$ru->plural(5,  { ... });   # "5 яблок"    (many)
$ru->plural(11, { ... });   # "11 яблок"   (many)
```

**CLDR kural string formatı:**

```
one{n==1}other
zero{n==0}one{n==1}two{n==2}few{n%100>=3&&n%100<=10}many{n%100>=11&&n%100<=99}other
one{n%10==1&&n%100!=11}few{n%10>=2&&n%10<=4&&(n%100<10||n%100>=20)}many{...}other
```

> `{count}` veya `{n}` yer tutucuları locale'e uygun biçimlendirilmiş sayı ile değiştirilir (`format_number` ile, `decimals => 0`).

---

### 5.12 Diğer Erişimciler

```perl
$lang->language();   # "tr" - aktif dil etiketi
$lang->months();     # ["Ocak", "Şubat", ..., "Aralık"]
$lang->days();       # ["Pazar", "Pazartesi", ..., "Cumartesi"]
```

#### `first_char($string)` - Alfabetik indeks karakteri

```perl
$tr->first_char("  çarşı  ");    # "Ç"
$tr->first_char("123abc");       # "0-9"
$tr->first_char("İzmir");        # "İ"
```

---

## 6. `AmberDB::Locale::Currency` - Evrensel Para Birimi Verisi

ISO 4217 standardında **12 para birimi** tanımlıdır:

| Kod | Ad | Sembol | Ondalık |
|---|---|---|---|
| TRY | Türk Lirası | ₺ | 2 |
| USD | ABD Doları | $ | 2 |
| EUR | Euro | € | 2 |
| GBP | İngiliz Sterlini | £ | 2 |
| RUB | Rus Rublesi | ₽ | 2 |
| AZN | Manat | ₼ | 2 |
| SAR | Suudi Riyali | ر.س | 2 |
| JPY | Japon Yeni | ¥ | **0** |
| CHF | İsviçre Frangı | CHF | 2 |
| CAD | Kanada Doları | CA$ | 2 |
| AUD | Avustralya Doları | A$ | 2 |
| CNY | Çin Yuanı | ¥ | 2 |

```perl
AmberDB::Locale::Currency->by_code('TRY');   # { num=>'949', name=>'Türk Lirası', symbol=>'₺', digits=>2 }
AmberDB::Locale::Currency->symbol('EUR');    # "€"
AmberDB::Locale::Currency->name('USD');      # "ABD Doları"
AmberDB::Locale::Currency->all();            # [ ['TRY','Türk Lirası'], ['USD','ABD Doları'], ... ]
AmberDB::Locale::Currency->active_codes();   # qw(TRY USD EUR GBP RUB AZN SAR JPY CHF CAD AUD CNY)
```

---

## 7. Dil Veri Modülü Yazma Rehberi

Yeni bir dil eklemek için `Amber/Locale/Lang/<kod>.pm` dosyası oluşturun:

```perl
package AmberDB::Locale::Lang::it;   # İtalyanca örneği
use strict;
use warnings;

our $VERSION = '1.0';

sub data {
    return {
        uc_map         => {},
        lc_map         => {},
        sort_map       => {},
        alphabet_chars => "\x{E0}\x{E8}\x{E9}\x{EC}\x{F2}\x{F9}",  # à è é ì ò ù
        accent_map     => {},
        ascii_map      => {},    # NFD tüm aksanları çözer

        numbers => {
            zero     => 'Zero',
            ones     => [qw(Uno Due Tre Quattro Cinque Sei Sette Otto Nove)],
            tens     => [qw(Dieci Venti Trenta Quaranta Cinquanta Sessanta Settanta Ottanta Novanta)],
            hundred  => 'Cento',
            thousand => 'Mille',
            million  => 'Milione',
            billion  => 'Miliardo',
            currency => { main => 'EUR', sub => 'centesimo' },
            decimal_sep => ',',
            hundred_one_prefix  => 0,
            thousand_one_prefix => 0,
        },

        html_entities => {},

        months => [qw(Gennaio Febbraio Marzo Aprile Maggio Giugno
                      Luglio Agosto Settembre Ottobre Novembre Dicembre)],
        days   => [qw(Domenica Lunedì Martedì Mercoledì Giovedì Venerdì Sabato)],

        number_format => {
            decimal_sep => ',',
            group_sep   => '.',
            group_size  => 3,
        },
        default_currency  => 'EUR',
        currency_position => 'suffix',
        currency_space    => 1,
        date_format => {
            short    => 'DD/MM/YYYY',
            medium   => 'D MMM YYYY',
            long     => 'D MMMM YYYY',
            full     => 'dddd D MMMM YYYY',
            time     => 'HH:mm',
            datetime => 'DD/MM/YYYY HH:mm',
        },
        plural_rule => 'one{n==1}other',
    };
}

1;
```

> Dosya adını `AmberDB::Locale`'daki `_load_locale()` otomatik olarak `require` eder. Ek bir kayıt işlemi gerekmez.

---

## 8. Performans Notları

| Konu | Detay |
|---|---|
| **Instance cache** | Aynı dil için yalnızca **1 nesne** oluşturulur; sonraki `new()` çağrıları cache'ten döner |
| **Regex pre-compile** | Tüm desenler (`_uc_re`, `_lc_re`, `_sort_re`, `_accent_re`, `_ascii_re`, `_safe_re`) constructor'da derlenir; her metot çağrısında yeniden derlenmez |
| **Sort key uzunluğu** | `uc_map`/`lc_map` anahtarları **uzunluk sırasına göre** (descending) sıralanır → çok karakterli eşlemeler önce eşleşir |
| **Unicode::Collate** | İlk yüklemede biraz yavaş olabilir (tablo okuma), sonraki çağrılar hızlıdır |

---

## 9. Sık Yapılan Hatalar ve Çözümleri

| Sorun | Neden | Çözüm |
|---|---|---|
| `i` → `I` oluyor (İ olması gerekirken) | `en` locale kullanılıyor | `language => "tr"` verin |
| `to_ascii` çıktısında `ae` yerine `a` var | `en` locale'de NFD `ä → a` yapar | `de` locale kullanın (DIN 5007-2: `ä → ae`) |
| Sayı metni boş dönüyor | Input yalnızca ayraç/noktalama içeriyor | Geçerli rakam kontrolü yapın |
| Doğu Arap rakamları çevrilmiyor | `normalize_num` özel çağrılmamış | `num2text`/`format_number` otomatik yapar; manuel çağrı gerekmez |
| Bilinmeyen dil hatası | Lang modülü dosyası yok | `Amber/Locale/Lang/<kod>.pm` oluşturun veya `en` fallback'i kabul edin |

---

## 10. Hızlı Referans Kartı

```perl
my $L = AmberDB::Locale->new(language => "tr");

# Metin dönüşümleri
$L->uc("ığdır")                    # IĞDIR
$L->lc("İSTANBUL")                 # istanbul
$L->ucfirst("merhaba dünya")       # Merhaba Dünya
$L->fold("İSTANBUL")               # istanbul
$L->ieq("İstanbul", "istanbul")    # 1
$L->normalize("<b>Kâr</b> &amp;")  # Kar &
$L->to_ascii("çarşı")              # carsi
$L->to_ascii("çarşı", 1)           # carsi (slug)
$L->first_char("çarşı")            # Ç
$L->substring("Şanlıurfa", 0, 5)   # Şanlı

# Sıralama
$L->sort(["İzmir","Ankara","Van"]) # Ankara, İzmir, Van

# Sayılar
$L->num2text(1234.56)              # Bin İki Yüz Otuz Dört TL Elli Altı KR
$L->format_number(1234567.89)      # 1.234.567,89
$L->format_currency(99.9, 'TRY')   # ₺99,90

# Tarih
$L->format_date(time, 'full')      # Pazar, 9 Ağustos 2026
$L->parse_date("09.08.2026")       # epoch

# Çoğul
$L->plural(1, {one=>"{count} adet", other=>"{count} adet"})  # 1 adet

# Erişimciler
$L->language()                     # tr
$L->months()                       # [Ocak, Şubat, ...]
$L->days()                         # [Pazar, Pazartesi, ...]
```
