# NAME

App::Greple::xlate - modul dukungan terjemahan untuk greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

Modul **Greple** **xlate** mencari blok teks dan menggantinya dengan teks yang diterjemahkan. Saat ini, modul DeepL (`deepl.pm`) dan ChatGPT (`gpt3.pm`) diimplementasikan sebagai mesin backend.

Jika Anda ingin menerjemahkan blok teks normal yang ditulis dalam gaya [pod](https://metacpan.org/pod/pod), gunakan perintah **greple** dengan modul `xlate::deepl` dan `perl` seperti ini:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pola `^(\w.*\n)+` berarti baris-baris berurutan yang dimulai dengan huruf alfanumerik. Perintah ini menampilkan area yang akan diterjemahkan. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Ini akan mencari dan menggantinya dengan output perintah **deepl**.

Secara default, teks asli dan diterjemahkan dicetak dalam format "conflict marker" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat mendapatkan bagian yang diinginkan dengan mudah menggunakan perintah [unifdef(1)](http://man.he.net/man1/unifdef). Format output dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah pintasan untuk menentukan pola `(?s).+` yang cocok dengan seluruh teks.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Menggunakan proses terjemahan untuk setiap area yang cocok.

    Tanpa opsi ini, **greple** berperilaku sebagai perintah pencarian normal. Jadi Anda dapat memeriksa bagian mana dari file yang akan menjadi subjek terjemahan sebelum memanggil pekerjaan sebenarnya.

    Hasil perintah ditampilkan di stdout, jadi alihkan ke file jika perlu, atau pertimbangkan untuk menggunakan modul [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    Opsi **--xlate** memanggil opsi **--xlate-color** dengan opsi **--color=never**.

    Dengan opsi **--xlate-fold**, teks yang dikonversi dilipat dengan lebar yang ditentukan. Lebar default adalah 70 dan dapat diatur dengan opsi **--xlate-fold-width**. Empat kolom dipesan untuk operasi run-in, sehingga setiap baris dapat menampung paling banyak 74 karakter.

- **--xlate-engine**=_engine_

    Menentukan mesin terjemahan yang akan digunakan. Jika Anda menentukan modul mesin secara langsung, seperti `-Mxlate::deepl`, Anda tidak perlu menggunakan opsi ini.

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin terjemahan, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, salin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasil ke clipboard, dan menekan enter.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Anda dapat mendapatkan bahasa yang tersedia dengan perintah `deepl languages` saat menggunakan mesin **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format output untuk teks asli dan terjemahan.

    - **conflict**, **cm**

        Cetak teks asli dan terjemahan dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Cetak teks asli dan terjemahan dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Anda dapat mengambil hanya teks Jepang dengan perintah **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Cetak teks asli dan terjemahan yang dipisahkan oleh satu baris kosong.

    - **xtxt**

        Jika formatnya adalah `xtxt` (teks terjemahan) atau tidak diketahui, hanya teks terjemahan yang dicetak.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Terjemahkan teks berikut ke dalam bahasa Indonesia, baris per baris.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real time dalam output STDERR.

- **--match-all**

    Atur seluruh teks file sebagai area target.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan yang di-cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead meminta ke server. Dengan strategi cache default `auto`, ia hanya mempertahankan data cache ketika file cache ada untuk file target.

- --cache-clear

    Opsi **--cache-clear** dapat digunakan untuk memulai manajemen cache atau menyegarkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika tidak ada, dan kemudian secara otomatis dipelihara setelah itu.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Pertahankan file cache jika ada.

    - `create`

        Buat file cache kosong dan keluar.

    - `always`, `yes`, `1`

        Pertahankan cache apa pun selama target adalah file normal.

    - `clear`

        Hapus data cache terlebih dahulu.

    - `never`, `no`, `0`

        Jangan pernah menggunakan file cache bahkan jika ada.

    - `accumulate`

        Dengan perilaku default, data yang tidak digunakan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan tetap di file, gunakan `accumulate`.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam repositori. Lihat informasi bantuan `xlate` untuk penggunaan.

# EMACS

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan wilayah yang diberikan. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa dengan memanggilnya dengan argumen awalan.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Atur kunci otentikasi Anda untuk layanan DeepL.

- OPENAI\_API\_KEY

    Kunci otentikasi OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Anda harus menginstal alat baris perintah untuk DeepL dan ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Pustaka DeepL Python dan perintah CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Pustaka Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Antarmuka baris perintah OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat panduan **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

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
