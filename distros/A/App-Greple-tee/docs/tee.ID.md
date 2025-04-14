# NAME

App::Greple::tee - modul untuk mengganti teks yang cocok dengan hasil perintah eksternal

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.02

# DESCRIPTION

Modul **-Mtee** dari Greple mengirimkan bagian teks yang cocok dengan perintah filter yang diberikan, dan menggantinya dengan hasil perintah. Idenya berasal dari perintah yang disebut **teip**. Ini seperti melewatkan sebagian data ke perintah filter eksternal.

Perintah filter mengikuti deklarasi modul (`-Mtee`) dan diakhiri dengan dua tanda hubung (`--`). Sebagai contoh, perintah berikutnya memanggil perintah `tr` dengan argumen `a-z A-Z` untuk kata yang cocok dalam data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Perintah di atas mengubah semua kata yang cocok dari huruf kecil menjadi huruf besar. Sebenarnya contoh ini sendiri tidak begitu berguna karena **greple** dapat melakukan hal yang sama secara lebih efektif dengan opsi **--cm**.

Secara default, perintah ini dijalankan sebagai satu proses, dan semua data yang cocok akan dikirim ke proses yang digabungkan. Jika teks yang dicocokkan tidak diakhiri dengan baris baru, maka teks tersebut akan ditambahkan sebelum dikirim dan dihapus setelah diterima. Data input dan output dipetakan baris demi baris, sehingga jumlah baris input dan output harus identik.

Dengan menggunakan opsi **--discrete**, perintah individual dipanggil untuk setiap area teks yang cocok. Anda dapat mengetahui perbedaannya dengan perintah berikut.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Baris data input dan output tidak harus identik ketika digunakan dengan opsi **--discrete**.

# OPTIONS

- **--discrete**

    Memanggil perintah baru satu per satu untuk setiap bagian yang cocok.

- **--bulkmode**

    Dengan opsi <--discrete>, setiap perintah dieksekusi sesuai permintaan. Opsi
    <--bulkmode> option causes all conversions to be performed at once.

- **--crmode**

    Opsi ini mengganti semua karakter baris baru di tengah setiap blok dengan karakter carriage return. Carriage return yang terdapat dalam hasil eksekusi perintah dikembalikan ke karakter baris baru. Dengan demikian, blok yang terdiri dari beberapa baris dapat diproses secara batch tanpa menggunakan opsi **--discrete**.

- **--fillup**

    Gabungkan urutan baris yang tidak kosong menjadi satu baris sebelum meneruskannya ke perintah filter. Karakter baris baru di antara karakter lebar akan dihapus, dan karakter baris baru lainnya diganti dengan spasi.

- **--squeeze**

    Menggabungkan dua atau lebih karakter baris baru yang berurutan menjadi satu.

- **-ML** **--offload** _command_

    Opsi **--offload** dari [teip(1)](http://man.he.net/man1/teip) diimplementasikan di modul berbeda [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL) (**-ML**).

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    Anda juga bisa menggunakan modul **-ML** untuk memproses baris bernomor genap seperti berikut ini.

        greple -Mtee cat -n -- -ML 2::2

# LEGACIES

Opsi **--blok** tidak lagi diperlukan karena opsi **--stretch** (**-S**) telah diimplementasikan di **greple**. Anda cukup melakukan hal berikut.

    greple -Mtee cat -n -- --all -SE foo

Tidak disarankan untuk menggunakan **--blok** karena mungkin tidak digunakan lagi di masa mendatang.

- **--blocks**

    Biasanya, area yang cocok dengan pola pencarian yang ditentukan dikirim ke perintah eksternal. Jika opsi ini ditentukan, bukan area yang cocok tetapi seluruh blok yang berisi area tersebut yang akan diproses.

    Misalnya, untuk mengirim baris yang berisi pola `foo` ke perintah eksternal, Anda perlu menentukan pola yang cocok untuk seluruh baris:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Namun dengan opsi **--blok**, hal ini dapat dilakukan dengan mudah sebagai berikut:

        greple -Mtee cat -n -- foo --blocks

    Dengan opsi **--blok**, modul ini berperilaku lebih mirip dengan opsi **-g** dari [teip(1)](http://man.he.net/man1/teip). Jika tidak, perilakunya mirip dengan [teip(1)](http://man.he.net/man1/teip) dengan opsi **-o**.

    Jangan gunakan **--blok** dengan opsi **--all**, karena blok akan menjadi seluruh data.

# WHY DO NOT USE TEIP

Pertama-tama, kapanpun Anda dapat melakukannya dengan perintah **teip**, gunakanlah. Ini adalah alat yang sangat baik dan jauh lebih cepat daripada **greple**.

Karena **greple** didesain untuk memproses file dokumen, maka ia memiliki banyak fitur yang sesuai untuk itu, seperti kontrol area pencocokan. Mungkin ada baiknya menggunakan **greple** untuk memanfaatkan fitur-fitur tersebut.

Selain itu, **teip** tidak dapat menangani beberapa baris data sebagai satu kesatuan, sedangkan **greple** dapat menjalankan perintah individual pada potongan data yang terdiri dari beberapa baris.

# EXAMPLE

Perintah berikutnya akan menemukan blok teks di dalam dokumen gaya [perlpod(1)](http://man.he.net/man1/perlpod) yang disertakan dalam file modul Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

Anda dapat menerjemahkannya melalui layanan DeepL dengan menjalankan perintah di atas yang diyakinkan dengan modul **-Mtee** yang memanggil perintah **deepl** seperti ini:

    greple -Mtee deepl text --to JA - -- --fillup ...

Modul khusus [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) lebih efektif untuk tujuan ini. Sebenarnya, petunjuk implementasi dari modul **tee** berasal dari modul **xlate**.

# EXAMPLE 2

Perintah selanjutnya akan menemukan beberapa bagian yang menjorok ke dalam dokumen LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

Anda dapat memformat ulang bagian ini dengan menggunakan modul **tee** dengan perintah **ansifold**:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Opsi --discrete akan memulai beberapa proses, sehingga prosesnya akan memakan waktu lebih lama untuk dieksekusi. Jadi, Anda dapat menggunakan opsi `--pisah '\r'` dengan `ansifold` yang menghasilkan satu baris menggunakan karakter CR, bukan NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Kemudian ubah karakter CR menjadi NL setelahnya dengan perintah [tr(1)](http://man.he.net/man1/tr) atau yang lainnya.

    ... | tr '\r' '\n'

# EXAMPLE 3

Pertimbangkan situasi di mana Anda ingin mencari string dari baris non-header. Sebagai contoh, Anda mungkin ingin mencari nama citra Docker dari perintah `docker image ls`, tetapi meninggalkan baris header. Anda dapat melakukannya dengan perintah berikut.

    greple -Mtee grep perl -- -ML 2: --discrete --all

Opsi `-ML 2:` mengambil baris kedua hingga terakhir dan mengirimkannya ke perintah `grep perl`. Opsi --discrete diperlukan karena jumlah baris dari input dan output berubah, tetapi karena perintah ini hanya dieksekusi satu kali, maka tidak ada kekurangan dalam hal performa.

Jika Anda mencoba melakukan hal yang sama dengan perintah **teip**, `teip -l 2- - grep` akan memberikan kesalahan karena jumlah baris output kurang dari jumlah baris input. Namun, tidak ada masalah dengan hasil yang diperoleh.

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

Opsi `--fillup` akan menghilangkan spasi di antara karakter Hangul saat menggabungkan teks bahasa Korea.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
