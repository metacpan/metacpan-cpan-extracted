# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** modülü istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Birincil motor, [llm](https://llm.datasette.io/) komutunu çağıran GPT-5.5 (`llm/gpt5.pm`)'tir; DeepL (`deepl.pm`) ve eski **gpty** tabanlı motorlar da dahildir.

Çeviriler dosya başına önbelleğe alınır, bu nedenle bir komutu yeniden çalıştırmak değişmemiş metin için hiçbir maliyet getirmez. Bir belge düzenlendiğinde, yalnızca değiştirilen paragraflar API'ye yeniden gönderilir; bağlamdan haberdar bir motor ayrıca çevredeki çevirileri, değişikliğin etrafındaki ham kaynak metni ve düzenlenen paragrafın önceki sürümünü de alır, böylece yeni çeviri yerleşik ifadeleri korur (bkz. **--xlate-context-window**). Hassas dizgeler iletimden önce gizlenebilir (bkz. ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Perl'in pod tarzında yazılmış bir belgede normal metin bloklarını çevirmek istiyorsanız, `--xlate-engine gpt5` ve `perl` modülüyle birlikte **greple** komutunu şu şekilde kullanın:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, `^([\w\pP].*\n)+` desen dizgesi, alfa-sayısal ve noktalama harfiyle başlayan ardışık satırlar anlamına gelir. Bu komut, çevrilecek alanı vurgulanmış olarak gösterir. **--all** seçeneği, tüm metni üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ardından seçili alanı çevirmek için `--xlate` seçeneğini ekleyin. Böylece, istenen bölümleri bulur ve bunları çeviri motorunun çıktısıyla değiştirir.

Varsayılan olarak, özgün ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "çatışma işaretleyicisi" biçiminde yazdırılır. `ifdef` biçimini kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutuyla istenen kısmı kolayca alabilirsiniz. Çıktı biçimi **--xlate-format** seçeneğiyle belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Tüm metni çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, tüm metni eşleyen `(?s).+` desenini belirtmek için bir kısayoldur.

Çatışma işaretleyicisi biçimindeki veriler, [sdif](https://metacpan.org/pod/App%3A%3Asdif) komutu ve `-V` seçeneğiyle yan yana stilde görüntülenebilir. Dize bazında karşılaştırmanın anlamı olmadığından, `--no-cdif` seçeneği önerilir. Metni renklendirmenize gerek yoksa, `--no-textcolor` (veya `--no-tc`) belirtin.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşleme belirtilen birimler halinde yapılır, ancak birden fazla satırdan oluşan boş olmayan metin dizisi söz konusu olduğunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem şu şekilde gerçekleştirilir:

- Her satırın başındaki ve sonundaki boşluk karakterleri kaldırılır.
- Bir satır tam genişlikte bir noktalama karakteriyle bitiyorsa, sonraki satırla birleştirin.
- Bir satır tam genişlikli bir karakterle bitiyor ve sonraki satır tam genişlikli bir karakterle başlıyorsa, satırları birleştirin.
- Satırın sonu veya başı tam genişlikli bir karakter değilse, araya bir boşluk karakteri ekleyerek birleştirin.

Önbellek verileri normalleştirilmiş metne göre yönetilir, bu nedenle normalleştirme sonuçlarını etkilemeyen değişiklikler yapılsa bile, önbelleğe alınmış çeviri verileri yine de geçerli olacaktır.

Bu normalleştirme işlemi yalnızca birinci (0’ıncı) ve çift numaralı desen için gerçekleştirilir. Dolayısıyla aşağıdaki gibi iki desen belirtildiğinde, ilk desene uyan metin normalleştirmeden sonra işlenecek, ikinci desene uyan metin için ise normalleştirme işlemi yapılmayacaktır.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden çok satırı tek bir satırda birleştirerek işlenecek metin için ilk deseni; önceden biçimlendirilmiş metin için ikinci deseni kullanın. İlk desende eşleşecek metin yoksa, `(?!)` gibi hiçbir şeyle eşleşmeyen bir desen kullanın.

# MASKING

Bazen, çevrilmesini istemediğiniz metin bölümleri vardır. Örneğin, markdown dosyalarındaki etiketler. DeepL, böyle durumlarda hariç tutulacak metin kısmının XML etiketlerine dönüştürülmesini, çevrilmesini ve çeviri tamamlandıktan sonra geri yüklenmesini önerir. Bunu desteklemek için, çeviriden masklanacak kısımları belirtmek mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, dosyanın her bir satırını `MASKPATTERN` olarak yorumlayacak, onunla eşleşen dizeleri çevirecek ve işleme bittikten sonra geri alacaktır. `#` ile başlayan satırlar yok sayılır.

Karmaşık desen, ters eğik çizgi ile kaçışlı satır sonları kullanılarak birden çok satıra yazılabilir.

Metnin maskeleme ile nasıl dönüştürüldüğü **--xlate-mask** seçeneğiyle görülebilir.

Maskeleme, işaretlemenin çevrilmesini önler. Hassas dizeleri çeviri hizmetinin kendisinden gizlemek için bkz. ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); ikisi birlikte kullanılabilir.

Bu arayüz deneyseldir ve gelecekte değişime tabidir.

# ANONYMIZATION AND TEMPLATES

Hassas dizgeler çeviri API'sine gönderilmeden önce gizlenebilir ve çıktıda geri yüklenebilir. Üç anonimleştirme kuralı kaynağı kullanılabilir: sözlük dosyası (**--xlate-anonymize**), belgenin içindeki satır içi işaretler (**--xlate-anonymize-mark**) ve YAML front matter değerleri (**--xlate-frontmatter**). Her dizge iletim sırasında `<person id=1 />` gibi bir kategori etiketiyle değiştirilir. Gizleme hedefi yalnızca API iletimidir: yerel önbellek dosyaları geri yüklenmiş düz metni saklar. Tam olarak neyin iletileceğini incelemek için **--xlate-dryrun** kullanın.

Form belgeleri (üç aylık raporlar ve benzerleri) için, aktörleri baştan tanımlayın ve gövdede onlara başvurun:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Şablonu dil başına bir kez `--xlate-template` ile (`--xlate-frontmatter` değerler dosyada tutulduğunda) çevirin, ardından her durumu **pandoc-embedz** bağımsız moduyla işleyin -- harici bir yapılandırmada `global:` altındaki değerler çeviri API'sine hiçbir zaman ulaşmaz:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Satır içi işaretler için, bir makro tanım yapılandırması sağlamak aynı çevrilmiş şablonun gerçek adları veya sansürlenmiş bir sürümü işlemesini sağlar:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Bir belge embedz blokları içerdiğinde bunları çeviriden hariç tutun:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Eşleşen her alan için çeviri işlemini çağırın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Böylece, gerçek işi başlatmadan önce dosyanın hangi kısmının çeviriye tabi olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıktıya gider; gerekirse dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    Seçenek **--xlate**, **--color=never** seçeneğiyle **--xlate-color** seçeneğini çağırır.

    **--xlate-fold** seçeneğiyle, dönüştürülmüş metin belirtilen genişliğe göre katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneğiyle ayarlanabilir. Gömülü işlem için dört sütun ayrılmıştır, bu nedenle her satır en fazla 74 karakter tutabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir.

    Şu anda aşağıdaki motorlar mevcuttur

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Motor modülleri önce arka uç ad alanlarında aranır (`llm`, ardından `gpty`), sonra doğrudan `App::Greple::xlate` altında aranır. Bu nedenle `gpt5`, `llm` komutunu çağıran `App::Greple::xlate::llm::gpt5`'i yüklerken, `gpt4o` `App::Greple::xlate::gpty::gpt4o`'e geri döner. Belirli bir arka ucu zorlamak için `--xlate-setopt backend=gpty` kullanın.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine, sizin çalışmanız beklenir. Çevrilecek metni hazırladıktan sonra, bunlar panoya kopyalanır. Bunları forma yapıştırmanız, sonucu panoya kopyalamanız ve enter'a basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. LLM motorları, modelin anladığı herhangi bir dil adını veya kodunu kabul eder; çeviri istemine yerleştirilir. **DeepL** motorunu kullanırken, kullanılabilir dilleri `deepl languages` komutuyla alabilirsiniz.

- **--xlate-from** (Default: `ORIGINAL`)

    `conflict`, `colon` ve `ifdef` çıktı biçimlerinde orijinal metin için kullanılan etiket. **DeepL** motoruyla, varsayılan olmayan bir değer de kaynak dil olarak iletilir.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı biçimini belirtin.

    `xtxt` dışındaki aşağıdaki biçimler, çevrilecek kısmın satırların bir koleksiyonu olduğunu varsayar. Aslında bir satırın yalnızca bir kısmını çevirmek mümkündür, ancak `xtxt` dışında bir biçim belirtmek anlamlı sonuçlar üretmez.

    - **conflict**, **cm**

        Orijinal ve dönüştürülmüş metin [git(1)](http://man.he.net/man1/git) çatışma belirteci biçiminde yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Orijinal dosyayı bir sonraki [sed(1)](http://man.he.net/man1/sed) komutuyla geri yükleyebilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Orijinal ve çevrilmiş metin, markdown'un özel konteyner stilinde çıktı alınır.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Yukarıdaki metin HTML'de aşağıdaki gibi çevrilecektir.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Varsayılan olarak iki nokta sayısı 7'dir. `:::::` gibi bir iki nokta dizisi belirtirseniz, 7 iki nokta yerine bu kullanılır.

    - **ifdef**

        Orijinal ve dönüştürülmüş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` biçiminde yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Yalnızca Japonca metni **unifdef** komutuyla alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Özgün ve dönüştürülmüş metin, araya tek bir boş satır konularak yazdırılır. `space+` için, dönüştürülmüş metinden sonra ayrıca bir satır sonu da çıktılanır.

    - **xtxt**

        Biçim `xtxt` (çevirilmiş metin) ya da bilinmeyense, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Bir seferde API’ye gönderilecek metnin azami uzunluğunu belirtin. Öntanımlı değer 0, motorun kendi sınırı anlamına gelir: ücretsiz DeepL hesap hizmeti için bu, API için 128K (**--xlate**) ve pano arayüzü için 5000’dir (**--xlate-labor**). Pro hizmeti kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--xlate-maxline**=_n_ (Default: 0)

    Bir seferde API’ye gönderilecek metnin azami satır sayısını belirtin.

    Her seferinde tek bir satırı çevirmek istiyorsanız bu değeri 1 olarak ayarlayın. Bu seçenek, `--xlate-maxlen` seçeneğine göre önceliklidir.

- **--xlate-prompt**=_text_

    Çeviri motoruna gönderilecek özel bir istem belirtin. Bu seçenek LLM motorları (`gpt3`, `gpt4o`, `gpt5`) için kullanılabilir, ancak DeepL için kullanılamaz. AI modeline belirli talimatlar sağlayarak çeviri davranışını özelleştirebilirsiniz. İstem `%s` içeriyorsa, hedef dil adıyla değiştirilecektir.

- **--xlate-context**=_text_

    Çeviri motoruna gönderilecek ek bağlam bilgisi belirtin. Birden çok bağlam dizesi sağlamak için bu seçenek birden çok kez kullanılabilir. Bağlam bilgisi, çeviri motorunun arka planı anlamasına ve daha doğru çeviriler üretmesine yardımcı olur.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Değişen bloklar yeniden çevrilirken referans bağlam olarak geçirilen çevredeki çevrilmiş blok sayısı (varsayılan 2). Bağlam ayrıca değişen bölgenin etrafındaki ham kaynak metni (başlıklar, liste yapısı, açıklamalar) ve kullanılabilir olduğunda, değişmemiş ifadelerin korunması için önbellekten kurtarılan değişen metnin önceki sürümünü içerir. Bağlama duyarlı çeviriyi tamamen devre dışı bırakmak için 0 olarak ayarlayın. Her değişen bölgenin kendi API çağrısında çevrildiğini ve bağlamın sistem istemine yaklaşık 8000 karaktere kadar ekleyebileceğini unutmayın; bu nedenle bağlama duyarlı çeviri, tutarlılık için bir miktar ek maliyeti göze alır.

- **--xlate-cache-seed**=_file_

    Yeni bir belgenin önbelleğini başka bir belgenin önbellek dosyasından başlatın. Periyodik raporlar için kullanışlıdır: yeni sayının önbelleğini önceki sayınınkiyle tohumlayın; böylece değişmemiş paragraflar yeniden çevrilmez ve düzenlenmiş paragraflar önceki sayının ifade biçimini korur. Tohum yalnızca hedef önbellek boş olduğunda kullanılır; aksi takdirde bir uyarıyla yok sayılır. Varsayılan `--xlate-cache=auto` ile, bir tohum belirtmek yeni belgenin önbellek dosyasının oluşturulacağını da ima eder.

- **--xlate-anonymize**=_file_

    Hassas dizeleri çeviri API'sine gönderilmeden önce anonimleştirin ve çıktıda geri yükleyin. Sözlük dosyası öğe başına bir giriş verir: JSON biçiminde (kanonik, makine tarafından üretilebilir)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    veya basit bir satır biçiminde (`category pattern`, regex için `/.../`). Her öğe `<person id=1 />` gibi bir kategori etiketiyle değiştirilir; aynı dize her zaman aynı etiketi alır, böylece model kimin kim olduğunu takip edebilir. Bilinmeyen JSON alanları yok sayılır; bu nedenle üreteçler (örn. varlıkları çıkaran yerel bir LLM) kendi ek açıklamalarını ekleyebilir. `lit` kategorisi ayrılmıştır. Yerel önbellek dosyaları hâlâ geri yüklenmiş düz metni saklar: gizleme hedefi yalnızca API iletimidir.

    Bir sözlük harici bir araç tarafından üretilebilir -- örneğin hassas varlıkları çıkaran yerel bir model:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Dosyadaki UTF-8 BOM tolere edilir. Front matter satır biçimindeki değerler, yalnızca kendi satırlarında sonda bir yorum taşıyabilir; değerden sonra değil.

- **--xlate-anonymize-mark**\[=_regex_\]

    Anonimleştirme girişlerini belgenin içindeki satır içi işaretlerden toplayın. İlk oluşumu `{{ person("山田太郎") }}` gibi işaretleyin; dizenin belge genelindeki her oluşumu anonimleştirilir. İşaretin kendisi kaynakta ve çeviride kalır; böylece bir belge Jinja2 tarzı bir makro işlemcisiyle de işlenebilir (`person` makrosunu adı yazdıracak veya redakte edecek şekilde tanımlayın). Özel bir _regex_, `(?<category>...)` ve `(?<text>...)` adlı yakalamalarını içermelidir.

    Bunun gibi isteğe bağlı değer alan bir seçenekle, ardından gelen bir dosya argümanının değer olarak alınacağını unutmayın: varsayılan gösterimi kullanırken `--xlate-anonymize-mark=` yazın (sonunda bir `=` ile).

    Alternatif gösterimler yapılandırılabilir; örneğin `@@person:NAME@@` tarzı işaretler için `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` veya işlenmiş Markdown'da görünmez kalan bir HTML yorumu biçimi. İşaret kuralları belge başına toplanır: bir girdi dosyasında işaretlenen bir dize, aynı çalıştırmadaki başka bir dosyada gizlenmez (dosyalar arasında biriken front matter değerlerinin aksine).

- **--xlate-template**\[=_regex_\]

    Şablon ifadelerini (varsayılan: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) opak yer tutucular olarak ele alın: modele bunları değiştirmeden kopyalamasını söyleyin ve yanıtın her blok için tam olarak aynı ifadeleri, her birini aynı sayıda içerdiğini doğrulayın. Sıraları değişebilir, çünkü çeviri onları hedef dilin sözcük sırasını izlemek için meşru şekilde yeniden sıralar. Bozuk bir ifade çalıştırmayı iptal eder; önbellek denetim noktasına alınır ve dondurulur, böylece ödenmiş hiçbir şey kaybolmaz.

    Bunun gibi isteğe bağlı değer alan bir seçenekle, izleyen bir dosya bağımsız değişkeninin değer olarak alınacağını unutmayın: varsayılan gösterimi kullanırken `--xlate-template=` yazın (sonunda bir `=` ile).

- **--xlate-frontmatter**

    Baştaki `---` ... `---` bloğunu YAML front matter olarak ele alın: onu çeviriden ve phase-2 bağlam dilimlerinden hariç tutun ve düz `key: value` değerlerini bir güvenlik ağı olarak anonimleştirme kurallarına (kategori `var`) ekleyin. Birden çok girdi dosyasıyla toplanan değerler birikir (gizleme tarafında hata yaparak).

    Kapanış `---` sonrasında her zaman boş bir satır bırakın. Paragraf tarzı bir eşleşme kalıbıyla, doğrudan gövde metnine bağlanan front matter, dışlamanın bastıramayacağı, iki tarafa yayılan tek bir blok oluşturur (bu durumda bir uyarı yazdırılır); değerler yine de anonimleştirilir, ancak front matter'ın kendisi çeviri için gönderilir.

- **--xlate-glossary**=_glossary_

    Çeviri için kullanılacak bir sözlük (glossary) kimliği belirtin. Bu seçenek yalnızca DeepL motoru kullanılırken kullanılabilir. Sözlük kimliği DeepL hesabınızdan alınmalı ve belirli terimlerin tutarlı çevirisini sağlar.

- **--xlate-dryrun**

    Çeviri API'sini çağırmayın; bunun yerine, ilerleme göstergesi aracılığıyla her payload'u tam olarak iletileceği şekilde (anonimleştirme ve maskelemeden sonra) gösterin. Makineden neyin çıktığını kontrol etmek ve bir çalıştırmanın maliyetini tahmin etmek için kullanışlıdır.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Çeviri sonucunu gerçek zamanlı olarak STDERR çıktısında görün. `From` payload'u, anonimleştirme ve maskelemeden sonra iletildiği gibi gösterilir.

- **--xlate-stripe**

    Eşleşen kısmı zebra şeritleme tarzında göstermek için [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülünü kullanın. Bu, eşleşen bölümler art arda bağlandığında kullanışlıdır.

    Renk paleti, terminalin arka plan rengine göre değiştirilir. Açıkça belirtmek isterseniz **--xlate-stripe-light** veya **--xlate-stripe-dark** kullanabilirsiniz.

- **--xlate-mask**

    Maskeleme işlevini uygulayın ve dönüştürülmüş metni geri yükleme olmadan olduğu gibi görüntüleyin.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

- **--lineify-cm**
- **--lineify-colon**

    `cm` ve `colon` biçimlerinde çıktı satır satır bölünüp biçimlendirilir. Bu nedenle, bir satırın yalnızca bir bölümü çevrilecekse beklenen sonuç elde edilemez. Bu filtreler, bir satırın bir kısmının çevrilmesiyle bozulan çıktıyı normal satır bazlı çıktıya düzeltir.

    Mevcut uygulamada, bir satırın birden fazla bölümü çevrilirse bunlar bağımsız satırlar olarak çıktılanır.

# CACHE OPTIONS

**xlate** modülü, her dosya için çevirinin önbelleğe alınmış metnini depolayabilir ve sunucuya sorma yükünü ortadan kaldırmak için yürütmeden önce bunu okuyabilir. Öntanımlı önbellek stratejisi `auto` ile, hedef dosya için önbellek dosyası mevcut olduğunda yalnızca önbellek verileri tutulur.

Önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için **--xlate-cache=clear** kullanın. Bu seçenekle bir kez çalıştırıldığında, önbellek dosyası yoksa yeni bir önbellek dosyası oluşturulur ve ardından otomatik olarak korunur.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Önbellek dosyası mevcutsa onu koruyun.

    - `create`

        Boş bir önbellek dosyası oluşturun ve çıkın.

    - `always`, `yes`, `1`

        Hedef normal bir dosya olduğu sürece her durumda önbelleği koruyun.

    - `clear`

        Önce önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Var olsa bile asla önbellek dosyasını kullanmayın.

    - `accumulate`

        Varsayılan davranışta, kullanılmayan veriler önbellek dosyasından kaldırılır. Bunları kaldırmak istemiyor ve dosyada tutmak istiyorsanız `accumulate` kullanın.
- **--xlate-update**

    Bu seçenek, gerekli olmasa bile önbellek dosyasını güncellemeye zorlar.

# COMMAND LINE INTERFACE

Dağıtıma dahil edilen `xlate` komutunu kullanarak bu modülü komut satırından kolayca kullanabilirsiniz. Kullanım için `xlate` man sayfasına bakın.

`xlate` komutu, `--to-lang`, `--from-lang`, `--engine` ve `--file` gibi GNU tarzı uzun seçenekleri destekler. Tüm mevcut seçenekleri görmek için `xlate -h` kullanın.

`xlate` komutu Docker ortamıyla birlikte çalışır; bu nedenle elinizde hiçbir şey kurulu olmasa bile Docker mevcut olduğu sürece kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Docker işlemleri, bağımsız bir komut olarak da kullanılabilen [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) tarafından yönetilir. `dozo` komutu, kalıcı konteyner ayarları için `.dozorc` yapılandırma dosyasını destekler.

Ayrıca, çeşitli belge stilleri için makefile’lar sağlandığından, özel bir belirtim olmadan diğer dillere çeviri mümkündür. `-M` seçeneğini kullanın.

Docker ve `make` seçeneklerini birleştirerek `make` komutunu Docker ortamında çalıştırabilirsiniz.

`xlate -C` gibi çalıştırmak, geçerli çalışma git deposu bağlanmış bir kabuğu başlatacaktır.

Ayrıntılar için ["SEE ALSO"](#see-also) bölümündeki Japonca makaleyi okuyun.

# EMACS

Emacs düzenleyicisinden `xlate` komutunu kullanmak için depoda bulunan `xlate.el` dosyasını yükleyin. `xlate-region` işlevi belirtilen bölgeyi çevirir. Varsayılan dil `EN-US`’dür ve önek argümanıyla çağırarak dili belirtebilirsiniz.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

- OPENAI\_API\_KEY

    Eski **gpty** motorları tarafından kullanılan OpenAI kimlik doğrulama anahtarı. `llm` tabanlı **gpt5** motoru da bu değişkeni okur, ancak `llm keys set openai` ile saklanan anahtarlar da çalışır.

- GREPLE\_XLATE\_CACHE

    Varsayılan önbellek stratejisini ayarlayın (bkz. ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Kullandığınız motor için komut satırı aracını kurun: **gpt5** motoru için `llm`, DeepL için `deepl`, eski GPT motorları için `gpty`.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlate tarafından konteyner işlemleri için kullanılan genel amaçlı Docker çalıştırıcısı

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Hedef metin deseni hakkında ayrıntılar için **greple** kılavuzuna bakın. Eşleşme alanını sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple** komutunun sonucuyla dosyaları değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif** kullanarak, **-V** seçeneğiyle yan yana çatışma işaretçisi biçimini gösterin.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** modülü, **--xlate-stripe** seçeneğiyle kullanılır.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker konteyner imajı.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` kütüphanesi, `xlate` betiğinde ve [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) içinde seçenek ayrıştırma için kullanılır.

- [https://llm.datasette.io/](https://llm.datasette.io/)

    LLM modellerine erişmek için **gpt5** motoru tarafından kullanılan `llm` komutu.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python kütüphanesi ve CLI komutu.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Kütüphanesi

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI komut satırı arayüzü

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Sadece gerekli kısımları DeepL API ile çevirip değiştiren Greple modülü (Japonca)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API modülüyle 15 dilde belgeler üretme (Japonca)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile otomatik çeviri Docker ortamı (Japonca)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
