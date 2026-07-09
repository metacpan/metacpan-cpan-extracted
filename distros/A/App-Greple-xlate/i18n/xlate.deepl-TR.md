# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** modülü, istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Ana motor, [llm](https://llm.datasette.io/) komutunu çağıran GPT-5.5'tir (`llm/gpt5.pm`); DeepL (`deepl.pm`) ve eski **gpty** tabanlı motorlar da dahildir.

Çeviriler dosya başına önbelleğe alınır, bu nedenle değişmemiş metinler için komutu yeniden çalıştırmanın maliyeti yoktur. Bir belge düzenlendiğinde, yalnızca değiştirilen paragraflar API’ye yeniden gönderilir; bağlam farkında bir motor, çevredeki çevirileri, değişikliğin etrafındaki ham kaynak metni ve düzenlenmiş paragrafın önceki sürümünü de alır, böylece yeni çeviri yerleşik ifade biçimini korur (bkz. **--xlate-context-window**). Hassas dizeler, aktarımdan önce gizlenebilir (bkz. ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Perl'in pod stilinde yazılmış bir belgedeki normal metin bloklarını çevirmek istiyorsanız, **greple** komutunu `--xlate-engine gpt5` ve `perl` modülleriyle şu şekilde kullanın:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Bu komutta, `^([\w\pP].*\n)+` kalıp dizesi alfa-sayısal ve noktalama harfleriyle başlayan ardışık satırlar anlamına gelir. Bu komut çevrilecek alanı vurgulanmış olarak gösterir. **--all** seçeneği metnin tamamını üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ardından, seçilen alanı çevirmek için `--xlate` seçeneğini ekleyin. Böylece, istenen bölümler bulunur ve çeviri motorunun çıktısıyla değiştirilir.

Varsayılan olarak, orijinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "conflict marker" biçiminde yazdırılır. `ifdef` formatını kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutu ile istediğiniz kısmı kolayca alabilirsiniz. Çıktı biçimi **--xlate-format** seçeneği ile belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Eğer metnin tamamını çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, metnin tamamıyla eşleşen `(?s).+` kalıbını belirtmek için kısa yoldur.

Çakışma işaretleyici biçimi verileri [sdif](https://metacpan.org/pod/App%3A%3Asdif) komutu ve `-V` seçeneği ile yan yana görüntülenebilir. Dize bazında karşılaştırma yapmanın bir anlamı olmadığından, `--no-cdif` seçeneği önerilir. Metni renklendirmeniz gerekmiyorsa, `--no-textcolor` (veya `--no-tc`) belirtin.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

İşlem belirtilen birimler halinde yapılır, ancak birden fazla boş olmayan metin satırı dizisi olması durumunda, bunlar birlikte tek bir satıra dönüştürülür. Bu işlem aşağıdaki gibi gerçekleştirilir:

- Her satırın başındaki ve sonundaki beyaz boşluğu kaldırın.
- Bir satır tam genişlikte bir noktalama karakteriyle bitiyorsa, sonraki satırla birleştirin.
- Bir satır tam genişlikte bir karakterle bitiyorsa ve bir sonraki satır tam genişlikte bir karakterle başlıyorsa, satırları birleştirin.
- Bir satırın sonu veya başı tam genişlikte bir karakter değilse, boşluk karakteri ekleyerek birleştirin.

Önbellek verileri normalleştirilmiş metne göre yönetilir, bu nedenle normalleştirme sonuçlarını etkilemeyen değişiklikler yapılsa bile önbelleğe alınan çeviri verileri etkili olmaya devam edecektir.

Bu normalleştirme işlemi yalnızca ilk (0.) ve çift numaralı kalıp için gerçekleştirilir. Bu nedenle, aşağıdaki gibi iki kalıp belirtilirse, ilk kalıpla eşleşen metin normalleştirmeden sonra işlenecek ve ikinci kalıpla eşleşen metin üzerinde normalleştirme işlemi yapılmayacaktır.

    greple -Mxlate -E normalized -E not-normalized

Bu nedenle, birden fazla satırı tek bir satırda birleştirerek işlenecek metin için ilk kalıbı kullanın ve önceden biçimlendirilmiş metin için ikinci kalıbı kullanın. İlk kalıpta eşleşecek metin yoksa, `(?!)` gibi hiçbir şeyle eşleşmeyen bir kalıp kullanın.

# MASKING

Bazen, çevrilmesini istemediğiniz metin bölümleri olabilir. Örneğin, markdown dosyalarındaki etiketler. DeepL bu gibi durumlarda, metnin hariç tutulacak kısmının XML etiketlerine dönüştürülmesini, çevrilmesini ve çeviri tamamlandıktan sonra geri yüklenmesini önerir. Bunu desteklemek için, çeviriden maskelenecek kısımları belirtmek mümkündür.

    --xlate-setopt maskfile=MASKPATTERN

Bu, `MASKPATTERN` dosyasının her satırını düzenli bir ifade olarak yorumlayacak, eşleşen dizeleri çevirecek ve işleme sonra geri döndürecektir. `#` ile başlayan satırlar yok sayılır.

Karmaşık desenler, ters eğik çizgi ile kaçış işareti eklenmiş satır sonu karakterleri kullanılarak birden fazla satıra yazılabilir.

Maskeleme ile metnin nasıl dönüştürüldüğü **--xlate-mask** seçeneği ile görülebilir.

Maskeleme, işaretlemeyi çeviriden korur. Hassas dizeleri çeviri hizmetinden gizlemek için ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)'e bakın; her ikisi de birlikte kullanılabilir.

Bu arayüz deneyseldir ve gelecekte değiştirilebilir.

# ANONYMIZATION AND TEMPLATES

Hassas dizeler, çeviri API'sına gönderilmeden önce gizlenebilir ve çıktıda geri yüklenebilir. Anonimleştirme kuralları için üç kaynak mevcuttur: bir sözlük dosyası (**--xlate-anonymize**), belgenin içindeki satır içi işaretler (**--xlate-anonymize-mark**) ve YAML ön metin değerleri (**--xlate-frontmatter**). Her dize, aktarım sırasında `<person id=1 />` gibi bir kategori etiketiyle değiştirilir. Gizleme, yalnızca API aktarımını hedefler: yerel önbellek dosyaları, geri yüklenen düz metni saklar. Tam olarak neyin aktarılacağını incelemek için **--xlate-dryrun** kullanın.

Form belgeleri (üç aylık raporlar ve benzeri) için, aktörleri önceden tanımlayın ve metin gövdesinde bunlara atıfta bulunun:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Şablonu her dil için bir kez `--xlate-template` ile çevirin (ve değerler dosyada tutuluyorsa `--xlate-frontmatter` kullanın), ardından her durumu **pandoc-embedz** bağımsız modunda işleyin -- harici bir yapılandırmadaki `global:` altındaki değerler çeviri API'sine hiçbir şekilde ulaşmaz:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Satır içi işaretler için, bir makro tanımı yapılandırması sağlamak, aynı çevrilmiş şablonun ya gerçek adları ya da sansürlenmiş bir sürümü görüntülemesini sağlar:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Bir belge embedz blokları içeriyorsa, bunları çeviriden hariç tutun:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Eşleşen her alan için çeviri işlemini çağırın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Böylece, asıl işi çağırmadan önce dosyanın hangi bölümünün çeviriye tabi olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıkışa gider, bu nedenle gerekirse dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    **--xlate** seçeneği **--color=never** seçeneği ile **--xlate-color** seçeneğini çağırır.

    **--xlate-fold** seçeneği ile, dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneği ile ayarlanabilir. Çalıştırma işlemi için dört sütun ayrılmıştır, bu nedenle her satır en fazla 74 karakter alabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir.

    Şu anda, aşağıdaki motorlar mevcuttur

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Motor modülleri önce arka uç ad alanlarında (`llm`, ardından `gpty`) aranır, ardından doğrudan `App::Greple::xlate` altında aranır. Dolayısıyla `gpt5`, `App::Greple::xlate::llm::gpt5`'yi yükler ve bu da `llm` komutunu çağırırken, `gpt4o` ise `App::Greple::xlate::gpty::gpt4o`'ye geri döner. Belirli bir arka ucu zorlamak için `--xlate-setopt backend=gpty`'yi kullanın.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine sizin çalışmanız beklenmektedir. Çevrilecek metin hazırlandıktan sonra panoya kopyalanır. Bunları forma yapıştırmanız, sonucu panoya kopyalamanız ve return tuşuna basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. LLM motorları, modelin anladığı herhangi bir dil adını veya kodunu kabul eder; bu, çeviri komut satırına eklenir. **DeepL** motorunu kullanırken `deepl languages` komutuyla kullanılabilir dilleri öğrenebilirsiniz.

- **--xlate-from** (Default: `ORIGINAL`)

    `conflict`, `colon` ve `ifdef` çıktı biçimlerinde orijinal metin için kullanılan etiket. **DeepL** motorunda, varsayılan olmayan bir değer de kaynak dil olarak iletilir.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı formatını belirtin.

    `xtxt` dışındaki aşağıdaki biçimler çevrilecek parçanın bir satır koleksiyonu olduğunu varsayar. Aslında, bir satırın yalnızca bir kısmını çevirmek mümkündür, ancak `xtxt` dışında bir biçim belirtmek anlamlı sonuçlar üretmeyecektir.

    - **conflict**, **cm**

        Orijinal ve dönüştürülmüş metin [git(1)](http://man.he.net/man1/git) çakışma işaretleyici biçiminde yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Bir sonraki [sed(1)](http://man.he.net/man1/sed) komutu ile orijinal dosyayı kurtarabilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Orijinal ve çevrilmiş metin, markdown'un özel kapsayıcı stilinde çıktı olarak verilir.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Yukarıdaki metin HTML'de aşağıdakine çevrilecektir.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        İki nokta üst üste sayısı varsayılan olarak 7'dir. `:::::` gibi iki nokta üst üste dizisi belirtirseniz, 7 iki nokta üst üste yerine kullanılır.

    - **ifdef**

        Orijinal ve dönüştürülmüş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` biçiminde yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** komutu ile sadece Japonca metni alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Orijinal ve dönüştürülmüş metin tek bir boş satırla ayrılarak yazdırılır. `space+` için, dönüştürülen metinden sonra bir satırsonu çıktısı da verir.

    - **xtxt**

        Biçim `xtxt` (çevrilmiş metin) veya bilinmiyorsa, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    API'ye tek seferde gönderilecek metnin maksimum uzunluğunu belirtin. Varsayılan değer olan 0, motorun kendi sınırını ifade eder: ücretsiz DeepL hesabı hizmeti için bu sınır, API (**--xlate**) için 128K ve panoya arayüzü (**--xlate-labor**) için 5000'dir. Pro hizmetini kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--xlate-maxline**=_n_ (Default: 0)

    API'ye bir kerede gönderilecek maksimum metin satırını belirtin.

    Her seferinde bir satır çevirmek istiyorsanız bu değeri 1 olarak ayarlayın. Bu seçenek `--xlate-maxlen` seçeneğine göre önceliklidir.

- **--xlate-prompt**=_text_

    Çeviri motoruna gönderilecek özel bir komut belirtin. Bu seçenek LLM motorları (`gpt3`, `gpt4o`, `gpt5`) için kullanılabilir, ancak DeepL için kullanılamaz. AI modeline belirli talimatlar vererek çeviri davranışını özelleştirebilirsiniz. Komut, `%s` içeriyorsa, hedef dil adıyla değiştirilecektir.

- **--xlate-context**=_text_

    Çeviri motoruna gönderilecek ek bağlam bilgilerini belirtin. Bu seçenek, birden fazla bağlam dizesi sağlamak için birden fazla kez kullanılabilir. Bağlam bilgisi, çeviri motorunun arka planı anlamasına ve daha doğru çeviriler üretmesine yardımcı olur.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Değiştirilen bloklar yeniden çevrilirken referans bağlam olarak geçirilen çevrilmiş çevre blokların sayısı (varsayılan 2). Bağlam, değiştirilen bölgenin etrafındaki ham kaynak metni (başlıklar, liste yapısı, alt yazılar) ve varsa önbellekten kurtarılan değiştirilen metnin önceki sürümünü de içerir; böylece değiştirilmemiş ifadeler korunur. Bağlam duyarlı çeviriyi tamamen devre dışı bırakmak için 0 olarak ayarlayın. Her değiştirilen bölgenin kendi API çağrısında çevrildiğini ve bağlamın sistem komut satırına yaklaşık 8000 karakter ekleyebileceğini unutmayın; bu nedenle bağlam duyarlı çeviri, tutarlılık karşılığında biraz ekstra maliyet gerektirir.

- **--xlate-cache-seed**=_file_

    Başka bir belgenin önbellek dosyasından yeni bir belgenin önbelleğini başlatın. Periyodik raporlar için kullanışlıdır: yeni sayının önbelleğini önceki sayının önbelleğiyle başlatın; böylece değiştirilmemiş paragraflar yeniden çevrilmez ve düzenlenmiş paragraflar önceki sayının ifadesini korur. Başlangıç verisi yalnızca hedef önbellek boş olduğunda kullanılır; aksi takdirde bir uyarı ile göz ardı edilir. Varsayılan `--xlate-cache=auto` ile, bir başlangıç verisi belirtmek aynı zamanda yeni belgenin önbellek dosyasının oluşturulmasını da gerektirir.

- **--xlate-anonymize**=_file_

    Hassas dizeleri çeviri API'sine gönderilmeden önce anonimleştirin ve çıktıda geri yükleyin. Sözlük dosyası, her öğe için bir giriş içerir: JSON biçiminde (kanonik, makine tarafından üretilebilir)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    veya basit satır biçiminde (`category pattern`, `/.../` düzenli ifade için). Her öğe, `<person id=1 />` gibi bir kategori etiketiyle değiştirilir; aynı dize her zaman aynı etiketi alır, böylece model kimin kim olduğunu takip edebilir. Bilinmeyen JSON alanları göz ardı edilir, bu sayede oluşturucular (ör. varlıkları çıkaran yerel bir LLM) kendi açıklamalarını ekleyebilir. `lit` kategorisi ayrılmıştır. Yerel önbellek dosyaları, geri yüklenen düz metni hâlâ saklar: gizleme hedefi yalnızca API iletimidir.

    Bir sözlük, harici bir araç tarafından oluşturulabilir — örneğin, hassas varlıklarını ayıklayan yerel bir model:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Dosyadaki bir UTF-8 BOM'u kabul edilir. Ön bilgi satırı biçimindeki değerler, yalnızca kendi satırlarında sonda bir açıklama taşıyabilir; değerin ardından değil.

- **--xlate-anonymize-mark**\[=_regex_\]

    Belgenin kendisindeki satır içi işaretlerden anonimleştirme girdilerini toplayın. İlk geçişi `{{ person("山田太郎") }}` gibi işaretleyin; böylece belge genelinde bu dizenin her geçişi anonimleştirilir. İşaretin kendisi kaynakta ve çeviride kalır; bu sayede bir belge, Jinja2 tarzı bir makro işlemcisi tarafından da işlenebilir (`person` makrosunu, adı yazdırmak veya sansürlemek için tanımlayın). Özel bir _regex_, `(?<category>...)` ve `(?<text>...)` adlı yakalamaları içermelidir.

    Böyle bir isteğe bağlı değer seçeneğinde, takip eden dosya argümanının değer olarak alınacağını unutmayın: varsayılan notasyonu kullanırken `--xlate-anonymize-mark=` (sonunda `=` ile) yazın.

    Alternatif notasyonlar yapılandırılabilir; örneğin, `@@person:NAME@@` tarzı işaretler için `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` veya işlenmiş Markdown'da görünmez kalan bir HTML yorum biçimi. İşaretleme kuralları belge bazında toplanır: bir giriş dosyasında işaretlenmiş bir dize, aynı işleme ait başka bir dosyada gizlenmez (dosyalar arasında biriken ön bilgi değerlerinin aksine).

- **--xlate-template**\[=_regex_\]

    Şablon ifadelerini (varsayılan: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) opak yer tutucular olarak değerlendirin: modele bunları değiştirmeden kopyalamasını söyleyin ve her blok için yanıtın tam olarak aynı ifadeleri, her biri aynı sayıda içerdiğini doğrulayın. Çeviri işlemi, hedef dilin kelime sırasına uymak için bu ifadelerin sırasını meşru bir şekilde yeniden düzenleyebileceğinden, sıraları değişebilir. Hatalı bir ifade, çalıştırmayı sonlandırır; önbellek kontrol noktası alınarak dondurulur, böylece ücret ödenen hiçbir şey kaybolmaz.

    Böyle bir isteğe bağlı değer seçeneğinde, takip eden dosya argümanının değer olarak kabul edileceğine dikkat edin: varsayılan notasyonu kullanırken `--xlate-template=` (sonunda `=` ile) yazın.

- **--xlate-frontmatter**

    Başındaki `---` ... `---` bloğunu YAML ön metni olarak değerlendirin: bunu çeviriden ve 2. aşama bağlam dilimlerinden hariç tutun ve düz `key: value` değerlerini bir güvenlik ağı olarak anonimleştirme kurallarına (kategori `var`) ekleyin. Birden fazla giriş dosyası olduğunda toplanan değerler birikir (gizlilik lehine hareket edilir).

    Kapanış `---` etiketinden sonra daima bir boş satır bırakın. Paragraf tarzı eşleştirme deseninde, ana metne doğrudan uzanan ön metin, hariç tutma işleminin bastıramayacağı tek bir blok oluşturur (bu durumda bir uyarı görüntülenir); değerler yine de anonimleştirilir, ancak ön metin kendisi çeviri için gönderilir.

- **--xlate-glossary**=_glossary_

    Çeviri için kullanılacak bir sözlük kimliği belirtin. Bu seçenek yalnızca DeepL motoru kullanılırken kullanılabilir. Sözlük kimliği DeepL hesabınızdan alınmalıdır ve belirli terimlerin tutarlı bir şekilde çevrilmesini sağlar.

- **--xlate-dryrun**

    Çeviri API’sini çağırmayın; bunun yerine, ilerleme göstergesi aracılığıyla her bir yükü tam olarak iletileceği şekilde (anonimleştirme ve maskeleme işlemlerinden sonra) gösterin. Bu, makineden neyin çıktığını kontrol etmek ve bir çalıştırmanın maliyetini tahmin etmek için yararlıdır.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Çeviri sonucunu STDERR çıktısında gerçek zamanlı olarak görüntüleyin. `From` yükü, anonimleştirme ve maskeleme işlemlerinden sonra iletildiği haliyle gösterilir.

- **--xlate-stripe**

    Eşleşen kısmı zebra şeritleme yöntemiyle göstermek için [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) modülünü kullanın. Bu, eşleşen parçalar arka arkaya bağlandığında kullanışlıdır.

    Renk paleti terminalin arka plan rengine göre değiştirilir. Açıkça belirtmek isterseniz, **--xlate-stripe-light** veya **--xlate-stripe-dark** kullanabilirsiniz.

- **--xlate-mask**

    Maskeleme işlevini gerçekleştirin ve dönüştürülen metni geri yükleme yapmadan olduğu gibi görüntüleyin.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

- **--lineify-cm**
- **--lineify-colon**

    `cm` ve `colon` biçimleri söz konusu olduğunda, çıktı satır satır bölünür ve biçimlendirilir. Bu nedenle, bir satırın yalnızca bir kısmı çevrilecekse, beklenen sonuç elde edilemez. Bu filtreler, bir satırın bir kısmının normal satır satır çıktıya çevrilmesiyle bozulan çıktıyı düzeltir.

    Mevcut uygulamada, bir satırın birden fazla parçası çevrilirse, bunlar bağımsız satırlar olarak çıkarılır.

# CACHE OPTIONS

**xlate** modülü her dosya için önbellekte çeviri metnini saklayabilir ve sunucuya sorma ek yükünü ortadan kaldırmak için yürütmeden önce okuyabilir. Varsayılan önbellek stratejisi `auto` ile, önbellek verilerini yalnızca hedef dosya için önbellek dosyası mevcut olduğunda tutar.

Önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini temizlemek için **--xlate-cache=clear** seçeneğini kullanın. Bu seçenekle çalıştırıldığında, mevcut değilse yeni bir önbellek dosyası oluşturulacak ve daha sonra otomatik olarak korunacaktır.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Eğer varsa önbellek dosyasını koruyun.

    - `create`

        Boş önbellek dosyası oluştur ve çık.

    - `always`, `yes`, `1`

        Hedef normal dosya olduğu sürece önbelleği yine de korur.

    - `clear`

        Önce önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Var olsa bile önbellek dosyasını asla kullanmayın.

    - `accumulate`

        Varsayılan davranışa göre, kullanılmayan veriler önbellek dosyasından kaldırılır. Bunları kaldırmak ve dosyada tutmak istemiyorsanız, `accumulate` kullanın.
- **--xlate-update**

    Bu seçenek, gerekli olmasa bile önbellek dosyasını güncellemeye zorlar.

# COMMAND LINE INTERFACE

Bu modülü, dağıtımda bulunan `xlate` komutunu kullanarak komut satırından kolayca kullanabilirsiniz. Kullanım için `xlate` man sayfasına bakın.

`xlate` komutu, `--to-lang`, `--from-lang`, `--engine` ve `--file` gibi GNU tarzı uzun seçenekleri destekler. Kullanılabilir tüm seçenekleri görmek için `xlate -h` kullanın.

`xlate` komutu Docker ortamı ile uyumlu olarak çalışır, bu nedenle elinizde kurulu bir şey olmasa bile Docker mevcut olduğu sürece kullanabilirsiniz. `-D` veya `-C` seçeneğini kullanın.

Docker işlemleri, bağımsız bir komut olarak da kullanılabilen [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) tarafından gerçekleştirilir. `dozo` komutu, kalıcı konteyner ayarları için `.dozorc` yapılandırma dosyasını destekler.

Ayrıca, çeşitli belge stilleri için makefiles sağlandığından, özel bir belirtim olmadan diğer dillere çeviri mümkündür. `-M` seçeneğini kullanın.

Docker ve `make` seçeneklerini birleştirerek `make` seçeneğini Docker ortamında da çalıştırabilirsiniz.

`xlate -C` gibi çalıştırmak, mevcut çalışan git deposunun bağlı olduğu bir kabuk başlatacaktır.

Ayrıntılar için ["SEE ALSO"](#see-also) bölümündeki Japonca makaleyi okuyun.

# EMACS

Emacs editöründen `xlate` komutunu kullanmak için depoda bulunan `xlate.el` dosyasını yükleyin. `xlate-region` fonksiyonu verilen bölgeyi çevirir. Varsayılan dil `EN-US`'dir ve prefix argümanı ile çağırarak dili belirtebilirsiniz.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

- OPENAI\_API\_KEY

    Eski **gpty** motorları tarafından kullanılan OpenAI kimlik doğrulama anahtarı. `llm` tabanlı **gpt5** motoru da bu değişkeni okur, ancak `llm keys set openai` ile depolanan anahtarlar da çalışır.

- GREPLE\_XLATE\_CACHE

    Varsayılan önbellek stratejisini ayarlayın (["CACHE OPTIONS"](#cache-options)'e bakın).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Kullandığınız motor için komut satırı aracını yükleyin: `llm` motoru için **gpt5**, DeepL için `deepl`, eski GPT motorları için `gpty`.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlate tarafından konteyner işlemleri için kullanılan genel Docker çalıştırıcısı

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Hedef metin kalıbı hakkında ayrıntılı bilgi için **greple** kılavuzuna bakın. Eşleşen alanı sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Dosyaları **greple** komutunun sonucuna göre değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** seçeneği ile çakışma işaretleyici formatını yan yana göstermek için **sdif** kullanın.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    **--xlate-stripe** seçeneği ile Greple **stripe** modülü kullanımı.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker konteyner görüntüsü.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` kütüphanesi, `xlate` komut dosyasında ve [App::dozo](https://metacpan.org/pod/App%3A%3Adozo)'de seçenek ayrıştırma için kullanılır.

- [https://llm.datasette.io/](https://llm.datasette.io/)

    **gpt5** motorunun LLM modellerine erişmek için kullandığı `llm` komutu.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python kütüphanesi ve CLI komutu.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Kütüphanesi

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI komut satırı arayüzü

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Sadece gerekli kısımları çevirmek ve değiştirmek için Greple modülü DeepL API (Japonca)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API modülü ile 15 dilde belge oluşturma (Japonca)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile otomatik çeviri Docker ortamı (Japonca)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
