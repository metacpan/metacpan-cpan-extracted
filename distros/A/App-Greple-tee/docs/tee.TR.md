# NAME

App::Greple::tee - eşleşen metni harici komut sonucu ile değiştiren modül

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.02

# DESCRIPTION

Greple'ın **-Mtee** modülü, eşleşen metin parçasını verilen filtre komutuna gönderir ve bunları komut sonucuyla değiştirir. Bu fikir **teip** adlı komuttan türetilmiştir. Kısmi verileri harici filtre komutuna atlamak gibidir.

Filtre komutu modül bildirimini (`-Mtee`) takip eder ve iki tire (`--`) ile sonlanır. Örneğin, bir sonraki komut verideki eşleşen kelime için `a-z A-Z` argümanları ile `tr` komutunu çağırır.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Yukarıdaki komut eşleşen tüm kelimeleri küçük harften büyük harfe dönüştürür. Aslında bu örneğin kendisi çok kullanışlı değildir çünkü **greple** aynı şeyi **--cm** seçeneği ile daha etkili bir şekilde yapabilir.

Varsayılan olarak, komut tek bir süreç olarak yürütülür ve eşleşen tüm veriler sürece karışık olarak gönderilir. Eşleşen metin satırsonu ile bitmiyorsa, gönderilmeden önce eklenir ve alındıktan sonra kaldırılır. Girdi ve çıktı verileri satır satır eşleştirilir, bu nedenle girdi ve çıktı satırlarının sayısı aynı olmalıdır.

**--discrete** seçeneği kullanıldığında, eşleşen her metin alanı için ayrı bir komut çağrılır. Farkı aşağıdaki komutlarla anlayabilirsiniz.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete** seçeneği kullanıldığında giriş ve çıkış verilerinin satırları aynı olmak zorunda değildir.

# OPTIONS

- **--discrete**

    Eşleşen her parça için ayrı ayrı yeni komut çağırın.

- **--bulkmode**

    <--ayrık> seçeneği ile her komut isteğe bağlı olarak yürütülür. Bu durumda
    <--bulkmode> option causes all conversions to be performed at once.

- **--crmode**

    Bu seçenek, her bloğun ortasındaki tüm satırsonu karakterlerini satırbaşı karakterleriyle değiştirir. Komutun çalıştırılması sonucunda bulunan satır başları yeni satır karakterine geri döndürülür. Böylece, birden fazla satırdan oluşan bloklar **--ayrık** seçeneği kullanılmadan toplu olarak işlenebilir.

- **--fillup**

    Bir dizi boş olmayan satırı filtre komutuna geçirmeden önce tek bir satırda birleştirin. Geniş karakterler arasındaki yeni satır karakterleri silinir ve diğer yeni satır karakterleri boşluklarla değiştirilir.

- **--squeeze**

    İki veya daha fazla ardışık satırsonu karakterini tek bir karakterde birleştirir.

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip)'in **--offload** seçeneği farklı bir modül olan [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL) (**-ML**) içinde uygulanmaktadır.

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    **-ML** modülünü sadece çift sayılı satırları işlemek için aşağıdaki gibi de kullanabilirsiniz.

        greple -Mtee cat -n -- -ML 2::2

# LEGACIES

**--stretch** (**-S**) seçeneği **greple** modülünde uygulandığı için **--blocks** seçeneğine artık gerek yoktur. Basitçe aşağıdakileri uygulayabilirsiniz.

    greple -Mtee cat -n -- --all -SE foo

Gelecekte kullanımdan kaldırılabileceği için **--blocks** seçeneğinin kullanılması önerilmez.

- **--blocks**

    Normalde, belirtilen arama deseniyle eşleşen alan harici komuta gönderilir. Bu seçenek belirtilirse, eşleşen alan değil, onu içeren tüm blok işlenecektir.

    Örneğin, `foo` kalıbını içeren satırları harici komuta göndermek için, tüm satırla eşleşen kalıbı belirtmeniz gerekir:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Ancak **--blocks** seçeneği ile aşağıdaki kadar basit bir şekilde yapılabilir:

        greple -Mtee cat -n -- foo --blocks

    **--blocks** seçeneği ile bu modül daha çok [teip(1)](http://man.he.net/man1/teip)'in **-g** seçeneği gibi davranır. Aksi takdirde, davranış **-o** seçeneği ile [teip(1)](http://man.he.net/man1/teip)'e benzer.

    **--blocks** seçeneğini **--all** seçeneği ile birlikte kullanmayın, çünkü blok tüm veri olacaktır.

# WHY DO NOT USE TEIP

Öncelikle, **teip** komutu ile yapabildiğiniz her şeyi kullanın. Mükemmel bir araçtır ve **greple**'den çok daha hızlıdır.

**greple** belge dosyalarını işlemek için tasarlandığından, eşleşme alanı kontrolleri gibi buna uygun birçok özelliğe sahiptir. Bu özelliklerden yararlanmak için **greple** kullanmaya değer olabilir.

Ayrıca, **teip** birden fazla veri satırını tek bir birim olarak işleyemezken, **greple** birden fazla satırdan oluşan bir veri yığını üzerinde ayrı komutlar çalıştırabilir.

# EXAMPLE

Sonraki komut, Perl modül dosyasında bulunan [perlpod(1)](http://man.he.net/man1/perlpod) tarzı belge içindeki metin bloklarını bulacaktır.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

Yukarıdaki komutu **deepl** komutunu çağıran **-Mtee** modülü ile birlikte çalıştırarak DeepL servisi ile çevirebilirsiniz:

    greple -Mtee deepl text --to JA - -- --fillup ...

Yine de özel modül [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) bu amaç için daha etkilidir. Aslında, **tee** modülünün uygulama ipucu **xlate** modülünden gelmiştir.

# EXAMPLE 2

Sonraki komut LICENSE belgesinde bazı girintili kısımlar bulacaktır.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

Bu kısmı **tee** modülünü **ansifold** komutu ile kullanarak yeniden biçimlendirebilirsiniz:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Ayrık seçeneği birden fazla işlem başlatır, bu nedenle işlemin yürütülmesi daha uzun sürer. Bu yüzden NL yerine CR karakterini kullanarak tek satır üreten `ansifold` ile `--separate '\r'` seçeneğini kullanabilirsiniz.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Daha sonra CR karakterini [tr(1)](http://man.he.net/man1/tr) komutu veya başka bir komutla NL'ye dönüştürün.

    ... | tr '\r' '\n'

# EXAMPLE 3

Başlık olmayan satırlardaki dizeler için grep yapmak istediğiniz bir durumu düşünün. Örneğin, `docker image ls` komutundan Docker görüntü adlarını aramak, ancak başlık satırını bırakmak isteyebilirsiniz. Bunu aşağıdaki komutla yapabilirsiniz.

    greple -Mtee grep perl -- -ML 2: --discrete --all

`-ML 2:` seçeneği sondan ikinci satırları alır ve bunları `grep perl` komutuna gönderir. Girdi ve çıktı satırlarının sayısı değiştiği için --discrete seçeneği gereklidir, ancak komut yalnızca bir kez çalıştırıldığı için performans açısından bir dezavantajı yoktur.

Aynı şeyi **teip** komutuyla yapmaya çalışırsanız, `teip -l 2- -- grep` hata verecektir çünkü çıktı satırlarının sayısı girdi satırlarının sayısından azdır. Ancak elde edilen sonuçta bir sorun yoktur.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# BUGS

`--fillup` seçeneği Korece metni birleştirirken Hangul karakterleri arasındaki boşlukları kaldıracaktır.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
