=encoding utf-8

=head1 NAME

App::Greple::tee - eşleşen metni harici komut sonucu ile değiştiren modül

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple'ın B<-Mtee> modülü, eşleşen metin parçasını verilen filtre komutuna gönderir ve bunları komut sonucuyla değiştirir. Bu fikir B<teip> adlı komuttan türetilmiştir. Kısmi verileri harici filtre komutuna atlamak gibidir.

Filtre komutu modül bildirimini (C<-Mtee>) takip eder ve iki tire (C<-->) ile sonlanır. Örneğin, bir sonraki komut verideki eşleşen kelime için C<a-z A-Z> argümanları ile C<tr> komutunu çağırır.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Yukarıdaki komut eşleşen tüm kelimeleri küçük harften büyük harfe dönüştürür. Aslında bu örneğin kendisi çok kullanışlı değildir çünkü B<greple> aynı şeyi B<--cm> seçeneği ile daha etkili bir şekilde yapabilir.

Varsayılan olarak, komut tek bir işlem olarak yürütülür ve eşleşen tüm veriler karışık olarak gönderilir. Eşleşen metin satırsonu ile bitmiyorsa, önce eklenir ve sonra kaldırılır. Veriler satır satır eşlenir, bu nedenle girdi ve çıktı verilerinin satır sayısı aynı olmalıdır.

B<--discrete> seçeneği kullanıldığında, eşleşen her parça için ayrı bir komut çağrılır. Farkı aşağıdaki komutlarla anlayabilirsiniz.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

B<--discrete> seçeneği kullanıldığında giriş ve çıkış verilerinin satırları aynı olmak zorunda değildir.

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

Eşleşen her parça için ayrı ayrı yeni komut çağırın.

=item B<--fillup>

Bir dizi boş olmayan satırı filtre komutuna geçirmeden önce tek bir satırda birleştirir. Geniş karakterler arasındaki yeni satır karakterleri silinir ve diğer yeni satır karakterleri boşluklarla değiştirilir.

=item B<--blocks>

Normalde, belirtilen arama deseniyle eşleşen alan harici komuta gönderilir. Bu seçenek belirtilirse, eşleşen alan değil, onu içeren tüm blok işlenecektir.

Örneğin, C<foo> kalıbını içeren satırları harici komuta göndermek için, tüm satırla eşleşen kalıbı belirtmeniz gerekir:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Ancak B<--blocks> seçeneği ile aşağıdaki kadar basit bir şekilde yapılabilir:

    greple -Mtee cat -n -- foo --blocks

B<--blocks> seçeneği ile bu modül daha çok L<teip(1)>'in B<-g> seçeneği gibi davranır. Aksi takdirde, davranış B<-o> seçeneği ile L<teip(1)>'e benzer.

B<--blocks> seçeneğini B<--all> seçeneği ile birlikte kullanmayın, çünkü blok tüm veri olacaktır.

=item B<--squeeze>

İki veya daha fazla ardışık satırsonu karakterini tek bir karakterde birleştirir.

=back

=head1 WHY DO NOT USE TEIP

Öncelikle, B<teip> komutu ile yapabildiğiniz her şeyi kullanın. Mükemmel bir araçtır ve B<greple>'den çok daha hızlıdır.

B<greple> belge dosyalarını işlemek için tasarlandığından, eşleşme alanı kontrolleri gibi buna uygun birçok özelliğe sahiptir. Bu özelliklerden yararlanmak için B<greple> kullanmaya değer olabilir.

Ayrıca, B<teip> birden fazla veri satırını tek bir birim olarak işleyemezken, B<greple> birden fazla satırdan oluşan bir veri yığını üzerinde ayrı komutlar çalıştırabilir.

=head1 EXAMPLE

Sonraki komut, Perl modül dosyasında bulunan L<perlpod(1)> tarzı belge içindeki metin bloklarını bulacaktır.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Yukarıdaki komutu B<deepl> komutunu çağıran B<-Mtee> modülü ile birlikte çalıştırarak DeepL servisi ile çevirebilirsiniz:

    greple -Mtee deepl text --to JA - -- --fillup ...

Yine de özel modül L<App::Greple::xlate::deepl> bu amaç için daha etkilidir. Aslında, B<tee> modülünün uygulama ipucu B<xlate> modülünden gelmiştir.

=head1 EXAMPLE 2

Sonraki komut LICENSE belgesinde bazı girintili kısımlar bulacaktır.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Bu kısmı B<tee> modülünü B<ansifold> komutu ile kullanarak yeniden biçimlendirebilirsiniz:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

C<--ayrık> seçeneğini kullanmak zaman alıcıdır. Bu nedenle, NL yerine CR karakteri kullanarak tek satır üreten C<ansifold> ile C<--separate '\r'> seçeneğini kullanabilirsiniz.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Daha sonra CR karakterini L<tr(1)> komutu veya başka bir komutla NL'ye dönüştürün.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Başlık olmayan satırlardaki dizeler için grep yapmak istediğiniz bir durumu düşünün. Örneğin, C<docker image ls> komutundaki resimleri aramak, ancak başlık satırını bırakmak isteyebilirsiniz. Bunu aşağıdaki komutla yapabilirsiniz.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

C<-Mline -L 2:> seçeneği sondan ikinci satırları alır ve bunları C<grep perl> komutuna gönderir. C<--discrete> seçeneği gereklidir, ancak bu yalnızca bir kez çağrılır, bu nedenle performans dezavantajı yoktur.

Bu durumda, C<teip -l 2- -- grep> hata üretir çünkü çıktıdaki satır sayısı girdiden azdır. Ancak sonuç oldukça tatmin edicidir :)

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

=head1 BUGS

C<--fillup> seçeneği Korece metin için doğru çalışmayabilir.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
