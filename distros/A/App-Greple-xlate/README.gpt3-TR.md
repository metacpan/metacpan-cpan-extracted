# NAME

App::Greple::xlate - greple için çeviri desteği modülü

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.29

# DESCRIPTION

**Greple** **xlate** modülü istenen metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda DeepL (`deepl.pm`) ve ChatGPT (`gpt3.pm`) modülleri arka uç motoru olarak uygulanmıştır.

Eğer Perl'in pod stiliyle yazılmış bir belgedeki normal metin bloklarını çevirmek istiyorsanız, şu şekilde **greple** komutunu `xlate::deepl` ve `perl` modülü ile kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Bu komutta, desen dizesi `^(\w.*\n)+`, alfanümerik harfle başlayan ardışık satırları ifade eder. Bu komut, çevrilecek alanı vurgular. Bütün metni üretmek için **--all** seçeneği kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Ardından seçilen alanı çevirmek için `--xlate` seçeneğini ekleyin. Ardından, istenen bölümleri bulacak ve bunları **deepl** komutunun çıktısıyla değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "çatışma işaretçisi" formatında yazdırılır. `ifdef` formatını kullanarak, istediğiniz bölümü [unifdef(1)](http://man.he.net/man1/unifdef) komutuyla kolayca alabilirsiniz. Çıktı formatı **--xlate-format** seçeneğiyle belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Tüm metni çevirmek isterseniz, **--match-all** seçeneğini kullanın. Bu, tüm metni eşleştiren `(?s).+` desenini belirtmek için bir kısayoldur.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Her eşleşen alan için çeviri sürecini başlatın.

    Bu seçenek olmadan, **greple** normal bir arama komutu gibi davranır. Bu nedenle, gerçek çalışmayı başlatmadan önce dosyanın hangi bölümünün çeviri konusu olacağını kontrol edebilirsiniz.

    Komut sonucu standart çıktıya gider, bu nedenle gerekiyorsa dosyaya yönlendirin veya [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) modülünü kullanmayı düşünün.

    **--xlate** seçeneği **--xlate-color** seçeneğini **--color=never** seçeneğiyle çağırır.

    **--xlate-fold** seçeneğiyle dönüştürülen metin belirtilen genişlikte katlanır. Varsayılan genişlik 70'tir ve **--xlate-fold-width** seçeneğiyle ayarlanabilir. Dört sütun, çalıştırma işlemi için ayrılmıştır, bu nedenle her satır en fazla 74 karakter tutabilir.

- **--xlate-engine**=_engine_

    Kullanılacak çeviri motorunu belirtir. `-Mxlate::deepl` gibi doğrudan motor modülünü belirtirseniz, bu seçeneği kullanmanıza gerek yoktur.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine, çalışmanız beklenir. Çevrilecek metni hazırladıktan sonra, panoya kopyalanır. Forma yapıştırmanız, sonucu panoya kopyalamanız ve enter tuşuna basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dilini belirtin. **DeepL** motorunu kullanırken `deepl languages` komutuyla mevcut dilleri alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı formatını belirtin.

    - **conflict**, **cm**

        Orjinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) çakışma işaretçisi formatında yazdırılır.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Orijinal dosyayı aşağıdaki [sed(1)](http://man.he.net/man1/sed) komutuyla geri alabilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Orjinal ve çevrilmiş metin [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` formatında yazdırılır.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** komutuyla yalnızca Japonca metni alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Orjinal ve çevrilmiş metin tek boş satır ile ayrılmış olarak yazdırılır.

    - **xtxt**

        Format `xtxt` (çevrilmiş metin) veya bilinmeyen ise, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Aşağıdaki metni Türkçe'ye satır satır çevirin.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR çıktısında gerçek zamanlı çeviri sonucunu görün.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

# CACHE OPTIONS

**xlate** modülü, her dosyanın çeviri önbelleğini saklayabilir ve sunucuya sorma işleminin üstesinden gelmek için yürütmeden önce onu okuyabilir. Varsayılan önbellek stratejisi `auto` ile, hedef dosya için önbellek verisi yalnızca önbellek dosyası varsa tutulur.

- --cache-clear

    **--cache-clear** seçeneği, önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini yenilemek için kullanılabilir. Bu seçenekle çalıştırıldığında, bir önbellek dosyası yoksa yeni bir önbellek dosyası oluşturulur ve ardından otomatik olarak sürdürülür.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Önbellek dosyasını varsa koruyun.

    - `create`

        Boş önbellek dosyası oluşturun ve çıkın.

    - `always`, `yes`, `1`

        Hedef normal dosya olduğu sürece her durumda önbelleği sürdürün.

    - `clear`

        Öncelikle önbellek verilerini temizleyin.

    - `never`, `no`, `0`

        Önbellek dosyasını varsa kullanmayın.

    - `accumulate`

        Varsayılan davranışa göre, kullanılmayan veriler önbellek dosyasından kaldırılır. Onları kaldırmak istemezseniz ve dosyada tutmak isterseniz, `accumulate` kullanın.

# COMMAND LINE INTERFACE

Bu modülü, depoda bulunan `xlate` komutunu kullanarak komut satırından kolayca kullanabilirsiniz. Kullanım için `xlate` yardım bilgisine bakın.

# EMACS

Emacs düzenleyicisinden `xlate` komutunu kullanmak için depoda bulunan `xlate.el` dosyasını yükleyin. `xlate-region` işlevi verilen bölgeyi çevirir. Varsayılan dil `EN-US`'dir ve dil belirtmek için ön ek argümanını kullanabilirsiniz.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

- OPENAI\_API\_KEY

    OpenAI kimlik doğrulama anahtarı.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL ve ChatGPT için komut satırı araçlarını yüklemeniz gerekmektedir.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python kütüphanesi ve CLI komutu.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Kütüphanesi

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI komut satırı arabirimi

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Hedef metin deseni hakkında ayrıntılar için **greple** kılavuzuna bakın. Eşleşme alanını sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Dosyaları **greple** komutunun sonucuna göre değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** seçeneğiyle çakışma işaretçi formatını yan yana göstermek için **sdif** kullanın.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL API ile sadece gerekli kısımları çevirmek ve değiştirmek için Greple modülü (Japonca olarak)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API modülü ile 15 dilde belge oluşturma (Japonca olarak)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API ile otomatik çeviri Docker ortamı (Japonca olarak)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
