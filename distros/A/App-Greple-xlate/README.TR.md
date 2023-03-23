# NAME

App::Greple::xlate - greple için çeviri destek modülü

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.20

# DESCRIPTION

**Greple** **xlate** modülü metin bloklarını bulur ve bunları çevrilmiş metinle değiştirir. Şu anda sadece DeepL servisi **xlate::deepl** modülü tarafından desteklenmektedir.

[pod](https://metacpan.org/pod/pod) stili belgede normal metin bloğunu çevirmek istiyorsanız, **greple** komutunu `xlate::deepl` ve `perl` modülü ile aşağıdaki gibi kullanın:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

`^(\w.*\n)+` kalıbı alfa-nümerik harfle başlayan ardışık satırlar anlamına gelir. Bu komut çevrilecek alanı gösterir. **--all** seçeneği tüm metni üretmek için kullanılır.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Daha sonra seçilen alanı çevirmek için `--xlate` seçeneğini ekleyin. **deepl** komut çıktısı ile bunları bulacak ve değiştirecektir.

Varsayılan olarak, orijinal ve çevrilmiş metin [git(1)](http://man.he.net/man1/git) ile uyumlu "conflict marker" formatında yazdırılır. `ifdef` formatını kullanarak, [unifdef(1)](http://man.he.net/man1/unifdef) komutu ile istediğiniz kısmı kolayca elde edebilirsiniz. Biçim **--xlate-format** seçeneği ile belirtilebilir.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Metnin tamamını çevirmek istiyorsanız, **--match-all** seçeneğini kullanın. Bu, kalıbın tüm metinle eşleştiğini belirtmek için kısa yoldur `(?s).+`.

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

    Kullanılacak çeviri motorunu belirtin. Bu seçeneği kullanmak zorunda değilsiniz çünkü `xlate::deepl` modülü bunu `--xlate-engine=deepl` olarak bildirir.

- **--xlate-labor**
- **--xlabor**

    Çeviri motorunu çağırmak yerine, sizin çalışmanız beklenir. Çevrilecek metin hazırlandıktan sonra panoya kopyalanır. Bunları forma yapıştırmanız, sonucu panoya kopyalamanız ve return tuşuna basmanız beklenir.

- **--xlate-to** (Default: `EN-US`)

    Hedef dili belirtin. **DeepL** motorunu kullanırken `deepl languages` komutu ile mevcut dilleri alabilirsiniz.

- **--xlate-format**=_format_ (Default: `conflict`)

    Orijinal ve çevrilmiş metin için çıktı formatını belirtin.

    - **conflict**, **cm**

        Orijinal ve çevrilmiş metni [git(1)](http://man.he.net/man1/git) çakışma işaretleyici biçiminde yazdırın.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Bir sonraki [sed(1)](http://man.he.net/man1/sed) komutu ile orijinal dosyayı kurtarabilirsiniz.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Orijinal ve çevrilmiş metni [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` biçiminde yazdırın.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** komutu ile sadece Japonca metni alabilirsiniz:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Orijinal ve çevrilmiş metni tek bir boş satırla ayırarak yazdırın.

    - **xtxt**

        Biçim `xtxt` (çevrilmiş metin) veya bilinmiyorsa, yalnızca çevrilmiş metin yazdırılır.

- **--xlate-maxlen**=_chars_ (Default: 0)

    API'ye bir kerede gönderilecek maksimum metin uzunluğunu belirtin. Varsayılan değer ücretsiz hesap hizmeti için ayarlanmıştır: API için 128K (**--xlate**) ve pano arayüzü için 5000 (**--xlate-labor**). Pro hizmeti kullanıyorsanız bu değerleri değiştirebilirsiniz.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Çeviri sonucunu STDERR çıktısında gerçek zamanlı olarak görün.

- **--match-all**

    Dosyanın tüm metnini hedef alan olarak ayarlayın.

# CACHE OPTIONS

**xlate** modülü her dosya için önbellekte çeviri metnini saklayabilir ve sunucuya sorma ek yükünü ortadan kaldırmak için yürütmeden önce okuyabilir. Varsayılan önbellek stratejisi `auto` ile, önbellek verilerini yalnızca hedef dosya için önbellek dosyası mevcut olduğunda tutar.

- --cache-clear

    **--cache-clear** seçeneği önbellek yönetimini başlatmak veya mevcut tüm önbellek verilerini yenilemek için kullanılabilir. Bu seçenekle çalıştırıldığında, mevcut değilse yeni bir önbellek dosyası oluşturulacak ve daha sonra otomatik olarak korunacaktır.

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

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL hizmeti için kimlik doğrulama anahtarınızı ayarlayın.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python kütüphanesi ve CLI komutu.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Hedef metin kalıbı hakkında ayrıntılı bilgi için **greple** kılavuzuna bakın. Eşleşen alanı sınırlamak için **--inside**, **--outside**, **--include**, **--exclude** seçeneklerini kullanın.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Dosyaları **greple** komutunun sonucuna göre değiştirmek için `-Mupdate` modülünü kullanabilirsiniz.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** seçeneği ile çakışma işaretleyici formatını yan yana göstermek için **sdif** kullanın.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
