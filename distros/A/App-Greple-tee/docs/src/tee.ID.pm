=encoding utf-8

=head1 NAME

App::Greple::tee - modul untuk mengganti teks yang cocok dengan hasil perintah eksternal

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Modul B<-Mtee> dari Greple mengirimkan bagian teks yang cocok dengan perintah filter yang diberikan, dan menggantinya dengan hasil perintah. Idenya berasal dari perintah yang disebut B<teip>. Ini seperti melewatkan sebagian data ke perintah filter eksternal.

Perintah filter mengikuti deklarasi modul (C<-Mtee>) dan diakhiri dengan dua tanda hubung (C<-->). Sebagai contoh, perintah berikutnya memanggil perintah C<tr> dengan argumen C<a-z A-Z> untuk kata yang cocok dalam data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Perintah di atas mengubah semua kata yang cocok dari huruf kecil menjadi huruf besar. Sebenarnya contoh ini sendiri tidak begitu berguna karena B<greple> dapat melakukan hal yang sama secara lebih efektif dengan opsi B<--cm>.

Secara default, perintah ini dijalankan sebagai satu proses, dan semua data yang cocok dikirim ke proses tersebut secara bersamaan. Jika teks yang dicocokkan tidak diakhiri dengan baris baru, maka teks tersebut akan ditambahkan sebelum dan dihapus setelahnya. Data dipetakan baris demi baris, sehingga jumlah baris data input dan output harus sama.

Dengan menggunakan opsi B<--discrete>, perintah individual dipanggil untuk setiap bagian yang cocok. Anda dapat mengetahui perbedaannya dengan perintah berikut.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Baris data input dan output tidak harus identik ketika digunakan dengan opsi B<--discrete>.

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

Memanggil perintah baru satu per satu untuk setiap bagian yang cocok.

=item B<--fillup>

Menggabungkan urutan baris yang tidak kosong menjadi satu baris sebelum meneruskannya ke perintah filter. Karakter baris baru di antara karakter lebar dihapus, dan karakter baris baru lainnya diganti dengan spasi.

=item B<--blocks>

Biasanya, area yang cocok dengan pola pencarian yang ditentukan dikirim ke perintah eksternal. Jika opsi ini ditentukan, bukan area yang cocok tetapi seluruh blok yang berisi area tersebut yang akan diproses.

Misalnya, untuk mengirim baris yang berisi pola C<foo> ke perintah eksternal, Anda perlu menentukan pola yang cocok untuk seluruh baris:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Namun dengan opsi B<--blok>, hal ini dapat dilakukan dengan mudah sebagai berikut:

    greple -Mtee cat -n -- foo --blocks

Dengan opsi B<--blok>, modul ini berperilaku lebih mirip dengan opsi B<-g> dari L<teip(1)>. Jika tidak, perilakunya mirip dengan L<teip(1)> dengan opsi B<-o>.

Jangan gunakan B<--blok> dengan opsi B<--all>, karena blok akan menjadi seluruh data.

=item B<--squeeze>

Menggabungkan dua atau lebih karakter baris baru yang berurutan menjadi satu.

=back

=head1 WHY DO NOT USE TEIP

Pertama-tama, kapanpun Anda dapat melakukannya dengan perintah B<teip>, gunakanlah. Ini adalah alat yang sangat baik dan jauh lebih cepat daripada B<greple>.

Karena B<greple> didesain untuk memproses file dokumen, maka ia memiliki banyak fitur yang sesuai untuk itu, seperti kontrol area pencocokan. Mungkin ada baiknya menggunakan B<greple> untuk memanfaatkan fitur-fitur tersebut.

Selain itu, B<teip> tidak dapat menangani beberapa baris data sebagai satu kesatuan, sedangkan B<greple> dapat menjalankan perintah individual pada potongan data yang terdiri dari beberapa baris.

=head1 EXAMPLE

Perintah berikutnya akan menemukan blok teks di dalam dokumen gaya L<perlpod(1)> yang disertakan dalam file modul Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Anda dapat menerjemahkannya melalui layanan DeepL dengan menjalankan perintah di atas yang diyakinkan dengan modul B<-Mtee> yang memanggil perintah B<deepl> seperti ini:

    greple -Mtee deepl text --to JA - -- --fillup ...

Modul khusus L<App::Greple::xlate::deepl> lebih efektif untuk tujuan ini. Sebenarnya, petunjuk implementasi dari modul B<tee> berasal dari modul B<xlate>.

=head1 EXAMPLE 2

Perintah selanjutnya akan menemukan beberapa bagian yang menjorok ke dalam dokumen LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Anda dapat memformat ulang bagian ini dengan menggunakan modul B<tee> dengan perintah B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Menggunakan opsi C<--discrete> memakan waktu. Jadi, Anda dapat menggunakan opsi C<--pisah '\r'> dengan C<ansifold> yang menghasilkan satu baris menggunakan karakter CR, bukan NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Kemudian ubah karakter CR menjadi NL setelahnya dengan perintah L<tr(1)> atau yang lainnya.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Pertimbangkan situasi di mana Anda ingin mencari string dari baris yang bukan header. Sebagai contoh, Anda mungkin ingin mencari gambar dari perintah C<docker image ls>, tetapi meninggalkan baris header. Anda dapat melakukannya dengan perintah berikut.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Opsi C<-Mline -L 2:> mengambil baris kedua hingga terakhir dan mengirimkannya ke perintah C<grep perl>. Opsi C<--discrete> diperlukan, tetapi ini hanya dipanggil sekali, sehingga tidak ada kekurangan dalam hal performa.

Dalam kasus ini, C<teip -l 2- - grep> menghasilkan kesalahan karena jumlah baris pada output lebih sedikit dari input. Namun, hasilnya cukup memuaskan :)

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

Opsi C<--fillup> mungkin tidak bekerja dengan baik untuk teks bahasa Korea.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
