# NAME

App::Greple::tee - eşleşen metni harici komut sonucu ile değiştiren modül

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple'ın **-Mtee** modülü, eşleşen metin parçasını verilen filtre komutuna gönderir ve bunları komut sonucuyla değiştirir. Bu fikir **teip** adlı komuttan türetilmiştir. Kısmi verileri harici filtre komutuna atlamak gibidir.

Filtre komutu modül bildirimini (`-Mtee`) takip eder ve iki tire (`--`) ile sonlanır. Örneğin, bir sonraki komut verideki eşleşen kelime için `a-z A-Z` argümanları ile `tr` komutunu çağırır.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Yukarıdaki komut eşleşen tüm kelimeleri küçük harften büyük harfe dönüştürür. Aslında bu örneğin kendisi çok kullanışlı değildir çünkü **greple** aynı şeyi **--cm** seçeneği ile daha etkili bir şekilde yapabilir.

Varsayılan olarak, komut tek bir işlem olarak yürütülür ve eşleşen tüm veriler karışık olarak gönderilir. Eşleşen metin satırsonu ile bitmiyorsa, önce eklenir ve sonra kaldırılır. Veriler satır satır eşlenir, bu nedenle girdi ve çıktı verilerinin satır sayısı aynı olmalıdır.

**--discrete** seçeneği kullanıldığında, eşleşen her parça için ayrı bir komut çağrılır. Farkı aşağıdaki komutlarla anlayabilirsiniz.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete** seçeneği kullanıldığında giriş ve çıkış verilerinin satırları aynı olmak zorunda değildir.

# OPTIONS

- **--discrete**

    Eşleşen her parça için ayrı ayrı yeni komut çağırın.

# WHY DO NOT USE TEIP

Öncelikle, **teip** komutu ile yapabildiğiniz her şeyi kullanın. Mükemmel bir araçtır ve **greple**'den çok daha hızlıdır.

**greple** belge dosyalarını işlemek için tasarlandığından, eşleşme alanı kontrolleri gibi buna uygun birçok özelliğe sahiptir. Bu özelliklerden yararlanmak için **greple** kullanmaya değer olabilir.

Ayrıca, **teip** birden fazla veri satırını tek bir birim olarak işleyemezken, **greple** birden fazla satırdan oluşan bir veri yığını üzerinde ayrı komutlar çalıştırabilir.

# EXAMPLE

Sonraki komut, Perl modül dosyasında bulunan [perlpod(1)](http://man.he.net/man1/perlpod) tarzı belge içindeki metin bloklarını bulacaktır.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Yukarıdaki komutu **deepl** komutunu çağıran **-Mtee** modülü ile birlikte çalıştırarak DeepL servisi ile çevirebilirsiniz:

    greple -Mtee deepl text --to JA - -- --discrete ...

**deepl** tek satırlık girdi için daha iyi çalıştığından, komut kısmını bu şekilde değiştirebilirsiniz:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

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
    

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
