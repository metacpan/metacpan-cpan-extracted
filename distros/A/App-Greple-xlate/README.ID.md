# NAME

App::Greple::xlate - modul dukungan penerjemahan untuk greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# DESCRIPTION

Modul **Greple** **xlate** menemukan blok teks dan menggantinya dengan teks yang telah diterjemahkan. Saat ini hanya layanan DeepL yang didukung oleh modul **xlate::deepl**.

Jika Anda ingin menerjemahkan blok teks normal dalam dokumen gaya [pod](https://metacpan.org/pod/pod), gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pola `^(\w.*\n)+` berarti baris berurutan yang dimulai dengan huruf alfanumerik. Perintah ini menunjukkan area yang akan diterjemahkan. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Ini akan menemukan dan menggantinya dengan keluaran perintah **deepl**.

Secara default, teks asli dan terjemahan dicetak dalam format "penanda konflik" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat memperoleh bagian yang diinginkan dengan perintah [unifdef(1)](http://man.he.net/man1/unifdef) dengan mudah. Format dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-entire**. Ini adalah jalan pintas untuk menentukan pola yang cocok dengan seluruh teks `(?).*`.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Memanggil proses penerjemahan untuk setiap area yang cocok.

    Tanpa opsi ini, **greple** berperilaku sebagai perintah pencarian biasa. Jadi, Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum memanggil pekerjaan yang sebenarnya.

    Hasil perintah akan keluar ke standar, jadi alihkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.

    Dengan opsi **--xlate-fold**, teks yang dikonversi akan dilipat dengan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi **--xlate-fold-width**. Empat kolom dicadangkan untuk operasi run-in, sehingga setiap baris dapat menampung paling banyak 74 karakter.

- **--xlate-engine**=_engine_

    Tentukan mesin penerjemahan yang akan digunakan. Anda tidak perlu menggunakan opsi ini karena modul `xlate::deepl` mendeklarasikannya sebagai `--xlate-engine=deepl`.

- **--xlate-labor**

    Setelah memanggil mesin penerjemahan, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.

- **--xlate-to** (Default: `JA`)

    Tentukan bahasa target. Anda bisa mendapatkan bahasa yang tersedia dengan perintah `deepl languages` ketika menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: conflict)

    Tentukan format output untuk teks asli dan terjemahan.

    - **conflict**

        Mencetak teks asli dan teks terjemahan dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Mencetak teks asli dan teks terjemahan dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Anda hanya dapat mengambil teks bahasa Jepang dengan perintah **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Mencetak teks asli dan teks terjemahan yang dipisahkan oleh satu baris kosong.

    - **none**

        Jika formatnya adalah `none` atau tidak diketahui, hanya teks terjemahan yang dicetak.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real time dalam output STDERR.

- **--match-entire**

    Mengatur seluruh teks file sebagai area target.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan dalam cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead dari permintaan ke server. Dengan strategi cache default `auto`, modul ini mempertahankan data cache hanya ketika file cache ada untuk file target.

- --refresh

    Opsi <--refresh> dapat digunakan untuk memulai manajemen cache atau menyegarkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mempertahankan file cache jika ada.

    - `create`

        Buat file cache kosong dan keluar.

    - `always`, `yes`, `1`

        Pertahankan cache sejauh targetnya adalah file normal.

    - `refresh`

        Mempertahankan cache tetapi tidak membaca cache yang sudah ada.

    - `never`, `no`, `0`

        Jangan pernah menggunakan file cache meskipun ada.

    - `accumulate`

        Secara default, data yang tidak terpakai akan dihapus dari file cache. Jika anda tidak ingin menghapusnya dan tetap menyimpannya di dalam file, gunakan `accumulate`.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Tetapkan kunci autentikasi Anda untuk layanan DeepL.

# SEE ALSO

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL pustaka Python dan perintah CLI.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat manual **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gunakan **sdif** untuk menampilkan format penanda konflik berdampingan dengan opsi **-V**.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
