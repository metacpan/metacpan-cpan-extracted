# NAME

App::Greple::xlate - modul dukungan penerjemahan untuk greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** modul akan menemukan blok teks yang diinginkan dan menggantinya dengan teks terjemahan. Mesin utama yang digunakan adalah GPT-5.5 (`llm/gpt5.pm`), yang memanggil perintah [llm](https://llm.datasette.io/); DeepL (`deepl.pm`) dan mesin berbasis **gpty** yang sudah ada sebelumnya juga disertakan.

Terjemahan disimpan dalam cache per berkas, sehingga menjalankan kembali perintah tidak memerlukan biaya tambahan untuk teks yang tidak berubah. Saat dokumen diedit, hanya paragraf yang berubah yang dikirim kembali ke API; mesin yang peka konteks juga menerima terjemahan di sekitarnya, teks sumber mentah di sekitar perubahan, dan versi sebelumnya dari paragraf yang diedit, sehingga terjemahan baru tetap mempertahankan gaya penulisan yang sudah ada (lihat **--xlate-context-window**). String yang sensitif dapat disembunyikan sebelum dikirim (lihat ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Jika Anda ingin menerjemahkan blok teks biasa dalam dokumen yang ditulis dalam gaya pod Perl, gunakan perintah **greple** bersama modul `--xlate-engine gpt5` dan `perl` seperti ini:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

Dalam perintah ini, string pola `^([\w\pP].*\n)+` berarti baris berurutan yang dimulai dengan alfanumerik dan tanda baca. Perintah ini menunjukkan area yang akan diterjemahkan dengan disorot. Opsi **--all** digunakan untuk menghasilkan seluruh teks.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Kemudian tambahkan opsi `--xlate` untuk menerjemahkan area yang dipilih. Selanjutnya, sistem akan menemukan bagian-bagian yang diinginkan dan menggantinya dengan hasil terjemahan dari mesin terjemahan.

Secara default, teks asli dan terjemahan dicetak dalam format "penanda konflik" yang kompatibel dengan [git(1)](http://man.he.net/man1/git). Dengan menggunakan format `ifdef`, Anda dapat memperoleh bagian yang diinginkan dengan perintah [unifdef(1)](http://man.he.net/man1/unifdef) dengan mudah. Format keluaran dapat ditentukan dengan opsi **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Jika Anda ingin menerjemahkan seluruh teks, gunakan opsi **--match-all**. Ini adalah jalan pintas untuk menentukan pola `(?s).+` yang cocok dengan seluruh teks.

Data format penanda konflik dapat dilihat dalam gaya berdampingan dengan perintah [sdif](https://metacpan.org/pod/App%3A%3Asdif) dengan opsi `-V`. Karena tidak masuk akal untuk membandingkan per string, opsi `--no-cdif` direkomendasikan. Jika Anda tidak perlu mewarnai teks, tentukan `--no-textcolor` (atau `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

Pemrosesan dilakukan dalam unit yang ditentukan, tetapi dalam kasus urutan beberapa baris teks yang tidak kosong, teks-teks tersebut dikonversi bersama menjadi satu baris. Operasi ini dilakukan sebagai berikut:

- Menghilangkan spasi pada awal dan akhir setiap baris.
- Jika sebuah baris diakhiri dengan karakter tanda baca dengan lebar penuh, gabungkan dengan baris berikutnya.
- Jika sebuah baris diakhiri dengan karakter dengan lebar penuh dan baris berikutnya dimulai dengan karakter dengan lebar penuh, gabungkan kedua baris tersebut.
- Jika akhir atau awal baris bukan merupakan karakter dengan lebar penuh, gabungkan keduanya dengan menyisipkan karakter spasi.

Data cache dikelola berdasarkan teks yang dinormalisasi, sehingga meskipun ada modifikasi yang dilakukan yang tidak memengaruhi hasil normalisasi, data terjemahan yang ditembolok akan tetap efektif.

Proses normalisasi ini dilakukan hanya untuk pola pertama (ke-0) dan pola bernomor genap. Dengan demikian, jika dua pola ditentukan sebagai berikut, teks yang cocok dengan pola pertama akan diproses setelah normalisasi, dan tidak ada proses normalisasi yang dilakukan pada teks yang cocok dengan pola kedua.

    greple -Mxlate -E normalized -E not-normalized

Oleh karena itu, gunakan pola pertama untuk teks yang akan diproses dengan menggabungkan beberapa baris menjadi satu baris, dan gunakan pola kedua untuk teks yang telah diformat sebelumnya. Jika tidak ada teks yang cocok dengan pola pertama, gunakan pola yang tidak cocok dengan apa pun, seperti `(?!)`.

# MASKING

Terkadang, ada bagian teks yang tidak ingin diterjemahkan. Misalnya, tag dalam file penurunan harga. DeepL menyarankan agar dalam kasus seperti itu, bagian teks yang akan dikecualikan dikonversi ke tag XML, diterjemahkan, dan kemudian dikembalikan setelah terjemahan selesai. Untuk mendukung hal ini, dimungkinkan untuk menentukan bagian yang akan disembunyikan dari terjemahan.

    --xlate-setopt maskfile=MASKPATTERN

Ini akan menginterpretasikan setiap baris berkas `MASKPATTERN` sebagai ekspresi reguler, menerjemahkan string yang cocok dengannya, dan mengembalikan setelah diproses. Baris yang dimulai dengan `#` diabaikan.

Pola yang kompleks dapat ditulis dalam beberapa baris dengan baris baru yang di-escape menggunakan tanda garis miring terbalik.

Bagaimana teks diubah dengan masking dapat dilihat dengan opsi **--xlate-mask**.

Penyamaran melindungi markup agar tidak diterjemahkan. Untuk menyembunyikan string sensitif dari layanan terjemahan itu sendiri, lihat ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); keduanya dapat digunakan bersamaan.

Antarmuka ini bersifat eksperimental dan dapat berubah di masa depan.

# ANONYMIZATION AND TEMPLATES

String sensitif dapat disembunyikan sebelum dikirim ke API terjemahan dan dipulihkan dalam hasil terjemahan. Tersedia tiga sumber aturan anonimisasi: berkas kamus (**--xlate-anonymize**), tanda inline dalam dokumen itu sendiri (**--xlate-anonymize-mark**), dan nilai front matter YAML (**--xlate-frontmatter**). Setiap string diganti dengan tag kategori seperti `<person id=1 />` selama transmisi. Sasaran penyembunyian hanya pada transmisi API: berkas cache lokal menyimpan teks biasa yang telah dipulihkan. Gunakan **--xlate-dryrun** untuk memeriksa dengan tepat apa yang akan dikirimkan.

Untuk dokumen formulir (laporan triwulanan dan sejenisnya), tentukan aktor di bagian awal dan rujuk mereka di bagian isi:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Terjemahkan templat sekali per bahasa dengan `--xlate-template` (dan `--xlate-frontmatter` jika nilainya disimpan dalam berkas), lalu tampilkan setiap kasus dengan mode mandiri **pandoc-embedz** — nilai di bawah `global:` dalam konfigurasi eksternal sama sekali tidak sampai ke API terjemahan:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Untuk tanda-tanda inline, menyediakan konfigurasi definisi makro akan membuat templat terjemahan yang sama menampilkan nama asli atau versi yang disunting:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Kecualikan blok embedz dari terjemahan jika dokumen mengandungnya:

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

    Menentukan mesin terjemahan yang akan digunakan.

    Pada saat ini, mesin berikut ini tersedia

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Modul mesin dicari terlebih dahulu di ruang nama backend (`llm`, lalu `gpty`), kemudian langsung di bawah `App::Greple::xlate`. Jadi, `gpt5` memuat `App::Greple::xlate::llm::gpt5` yang memanggil perintah `llm`, sedangkan `gpt4o` menggunakan `App::Greple::xlate::gpty::gpt4o` sebagai cadangan. Gunakan `--xlate-setopt backend=gpty` untuk memaksa penggunaan backend tertentu.

- **--xlate-labor**
- **--xlabor**

    Alih-alih memanggil mesin penerjemah, Anda diharapkan untuk bekerja. Setelah menyiapkan teks yang akan diterjemahkan, teks tersebut disalin ke clipboard. Anda diharapkan untuk menempelkannya ke formulir, menyalin hasilnya ke clipboard, dan menekan return.

- **--xlate-to** (Default: `EN-US`)

    Tentukan bahasa target. Mesin LLM menerima nama atau kode bahasa apa pun yang dipahami model; hal ini akan disisipkan ke dalam prompt terjemahan. Anda dapat melihat bahasa yang tersedia melalui perintah `deepl languages` saat menggunakan mesin **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Label yang digunakan untuk teks asli dalam format keluaran `conflict`, `colon`, dan `ifdef`. Dengan mesin **DeepL**, nilai non-default juga diteruskan sebagai bahasa sumber.

- **--xlate-format**=_format_ (Default: `conflict`)

    Tentukan format output untuk teks asli dan terjemahan.

    Format berikut ini selain `xtxt` mengasumsikan bahwa bagian yang akan diterjemahkan adalah kumpulan baris. Pada kenyataannya, dimungkinkan untuk menerjemahkan hanya sebagian dari sebuah baris, tetapi menentukan format selain `xtxt` tidak akan menghasilkan hasil yang berarti.

    - **conflict**, **cm**

        Teks asli dan teks yang dikonversi dicetak dalam format penanda konflik [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Anda dapat memulihkan file asli dengan perintah [sed(1)](http://man.he.net/man1/sed) berikutnya.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        Teks asli dan terjemahan ditampilkan dalam gaya wadah khusus penurunan harga.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        Teks di atas akan diterjemahkan ke dalam HTML berikut ini.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Jumlah titik dua adalah 7 secara default. Jika Anda menentukan urutan titik dua seperti `:::::`, ini digunakan sebagai pengganti 7 titik dua.

    - **ifdef**

        Teks asli dan teks yang dikonversi dicetak dalam format [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Anda hanya dapat mengambil teks bahasa Jepang dengan perintah **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Teks asli dan teks yang dikonversi dicetak dipisahkan oleh satu baris kosong. Untuk `spasi+`, ini juga menghasilkan baris baru setelah teks yang dikonversi.

    - **xtxt**

        Jika formatnya adalah `xtxt` (teks terjemahan) atau tidak diketahui, hanya teks terjemahan yang dicetak.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Tentukan panjang maksimum teks yang akan dikirim ke API sekaligus. Nilai default 0 berarti batas yang ditetapkan oleh mesin itu sendiri: untuk layanan akun DeepL gratis, batasnya adalah 128K untuk API (**--xlate**) dan 5000 untuk antarmuka clipboard (**--xlate-labor**). Anda mungkin dapat mengubah nilai-nilai ini jika menggunakan layanan Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Tentukan jumlah maksimum baris teks yang akan dikirim ke API sekaligus.

    Tetapkan nilai ini ke 1 jika Anda ingin menerjemahkan satu baris dalam satu waktu. Opsi ini lebih diutamakan daripada opsi `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Tentukan prompt khusus yang akan dikirim ke mesin terjemahan. Opsi ini tersedia untuk mesin LLM (`gpt3`, `gpt4o`, `gpt5`) tetapi tidak untuk DeepL. Anda dapat menyesuaikan perilaku terjemahan dengan memberikan instruksi spesifik kepada model AI. Jika prompt berisi `%s`, maka akan diganti dengan nama bahasa target.

- **--xlate-context**=_text_

    Tentukan informasi konteks tambahan yang akan dikirim ke mesin penerjemahan. Opsi ini dapat digunakan beberapa kali untuk memberikan beberapa string konteks. Informasi konteks membantu mesin penerjemah memahami latar belakang dan menghasilkan terjemahan yang lebih akurat.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Jumlah blok terjemahan di sekitarnya yang diteruskan sebagai konteks referensi saat menerjemahkan ulang blok yang diubah (default 2). Konteks ini juga mencakup teks sumber mentah di sekitar wilayah yang diubah (judul, struktur daftar, keterangan) dan, jika tersedia, versi sebelumnya dari teks yang diubah yang diambil dari cache, sehingga kata-kata yang tidak diubah tetap dipertahankan. Atur ke 0 untuk menonaktifkan terjemahan berbasis konteks sepenuhnya. Perhatikan bahwa setiap wilayah yang diubah diterjemahkan dalam panggilan API tersendiri dan konteks dapat menambah hingga sekitar 8.000 karakter ke prompt sistem, sehingga terjemahan berbasis konteks menukar biaya tambahan dengan konsistensi.

- **--xlate-cache-seed**=_file_

    Menginisialisasi cache dokumen baru dari berkas cache dokumen lain. Berguna untuk laporan berkala: menginisialisasi cache edisi baru dengan cache edisi sebelumnya, sehingga paragraf yang tidak diubah tidak diterjemahkan ulang dan paragraf yang diedit mempertahankan redaksi edisi sebelumnya. Benih hanya digunakan jika cache tujuan kosong; jika tidak, benih tersebut diabaikan dengan peringatan. Dengan pengaturan default `--xlate-cache=auto`, menentukan benih juga berarti membuat berkas cache dokumen baru.

- **--xlate-anonymize**=_file_

    Anonimkan string sensitif sebelum dikirim ke API terjemahan, dan pulihkan kembali dalam hasil keluaran. Berkas kamus memberikan satu entri per item: dalam format JSON (kanonik, dapat dihasilkan oleh mesin)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    atau dalam format baris sederhana (`category pattern`, `/.../` untuk regex). Setiap item diganti dengan tag kategori seperti `<person id=1 />`; string yang sama selalu mendapatkan tag yang sama, sehingga model dapat melacak identitas masing-masing. Bidang JSON yang tidak dikenal diabaikan, sehingga generator (misalnya LLM lokal yang mengekstrak entitas) dapat menambahkan anotasi mereka sendiri. Kategori `lit` dicadangkan. File cache lokal tetap menyimpan teks biasa yang dipulihkan: penyembunyian hanya ditujukan untuk transmisi API.

    Kamus dapat dihasilkan oleh alat eksternal — misalnya model lokal yang mengekstrak entitas sensitif:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    BOM UTF-8 dalam berkas ditoleransi. Nilai dalam format baris front matter hanya boleh disertai komentar penutup pada barisnya sendiri, bukan setelah nilai tersebut.

- **--xlate-anonymize-mark**\[=_regex_\]

    Kumpulkan entri anonimisasi dari tanda-tanda inline di dalam dokumen itu sendiri. Tandai kemunculan pertama seperti `{{ person("山田太郎") }}` dan setiap kemunculan string tersebut di seluruh dokumen akan dianonimkan. Tanda itu sendiri tetap ada di sumber dan di terjemahan, sehingga dokumen juga dapat diproses oleh pemroses makro bergaya Jinja2 (tentukan makro `person` untuk mencetak atau menyunting nama tersebut). Sebuah _regex_ kustom harus berisi penangkapan bernama `(?<category>...)` dan `(?<text>...)`.

    Perhatikan bahwa dengan opsi nilai opsional seperti ini, argumen file berikutnya akan dianggap sebagai nilainya: tulis `--xlate-anonymize-mark=` (dengan `=` di bagian akhir) saat menggunakan notasi default.

    Notasi alternatif dapat dikonfigurasi, misalnya `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` untuk tanda bergaya `@@person:NAME@@`, atau bentuk komentar HTML yang tetap tidak terlihat dalam Markdown yang dirender. Aturan penandaan dikumpulkan per dokumen: string yang ditandai dalam satu berkas masukan tidak disembunyikan dalam berkas lain pada proses yang sama (berbeda dengan nilai front matter, yang terakumulasi di seluruh berkas).

- **--xlate-template**\[=_regex_\]

    Perlakukan ekspresi templat (default: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) sebagai penanda tempat yang tidak transparan: instruksikan model untuk menyalinnya tanpa perubahan dan verifikasi, per blok, bahwa respons berisi ekspresi yang persis sama, masing-masing dengan jumlah kemunculan yang sama. Urutannya mungkin berubah, karena terjemahan secara sah mengubah urutannya agar mengikuti urutan kata dalam bahasa sasaran. Ekspresi yang rusak akan menghentikan proses; cache akan dicatat dan dibekukan, sehingga tidak ada yang terbuang dari hasil yang telah dibayar.

    Perhatikan bahwa dengan opsi nilai opsional seperti ini, argumen berkas yang mengikuti akan dianggap sebagai nilainya: tulis `--xlate-template=` (dengan `=` di bagian akhir) saat menggunakan notasi default.

- **--xlate-frontmatter**

    Perlakukan blok `---` ... `---` sebagai bagian awal YAML: kecualikan dari terjemahan dan dari potongan konteks fase-2, serta tambahkan nilai `key: value` datarnya ke aturan anonimisasi (kategori `var`) sebagai jaring pengaman. Jika ada beberapa berkas masukan, nilai-nilai yang dikumpulkan akan diakumulasikan (dengan mengutamakan penyembunyian).

    Selalu sisakan baris kosong setelah penutup `---`. Dengan pola pencocokan bergaya paragraf, front matter yang langsung menyambung ke teks isi membentuk satu blok yang melintasi kedua bagian, sehingga pengecualian tidak dapat menekannya (peringatan akan ditampilkan dalam kasus tersebut); nilai-nilai tersebut tetap dianonimkan, tetapi bagian awal itu sendiri akan dikirim untuk diterjemahkan.

- **--xlate-glossary**=_glossary_

    Tentukan ID glosarium yang akan digunakan untuk terjemahan. Opsi ini hanya tersedia saat menggunakan mesin DeepL. ID glosarium harus diperoleh dari akun DeepL Anda dan memastikan terjemahan yang konsisten untuk istilah tertentu.

- **--xlate-dryrun**

    Jangan panggil API terjemahan; sebaliknya, tampilkan, melalui tampilan kemajuan, setiap muatan persis seperti yang akan dikirimkan (setelah anonimisasi dan penyamaran). Berguna untuk memeriksa apa yang dikirimkan oleh sistem dan untuk memperkirakan biaya suatu proses.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Lihat hasil terjemahan secara real-time pada keluaran STDERR. Payload `From` ditampilkan sebagaimana dikirimkan, setelah anonimisasi dan penyamaran.

- **--xlate-stripe**

    Gunakan modul [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) untuk menampilkan bagian yang cocok dengan mode garis zebra. Hal ini berguna ketika bagian yang dicocokkan dihubungkan secara berurutan.

    Palet warna dialihkan menurut warna latar belakang terminal. Jika Anda ingin menentukan secara eksplisit, Anda dapat menggunakan **--xlate-stripe-light** atau **--xlate-stripe-dark**.

- **--xlate-mask**

    Lakukan fungsi masking dan tampilkan teks yang dikonversi apa adanya tanpa pemulihan.

- **--match-all**

    Mengatur seluruh teks file sebagai area target.

- **--lineify-cm**
- **--lineify-colon**

    Dalam kasus format `cm` dan `colon`, output dibagi dan diformat baris demi baris. Oleh karena itu, jika hanya sebagian dari suatu baris yang akan diterjemahkan, hasil yang diharapkan tidak dapat diperoleh. Filter ini memperbaiki output yang rusak dengan menerjemahkan bagian dari sebuah baris menjadi output baris per baris yang normal.

    Dalam implementasi saat ini, jika beberapa bagian dari suatu baris diterjemahkan, maka akan dikeluarkan sebagai baris independen.

# CACHE OPTIONS

Modul **xlate** dapat menyimpan teks terjemahan dalam cache untuk setiap file dan membacanya sebelum eksekusi untuk menghilangkan overhead dari permintaan ke server. Dengan strategi cache default `auto`, modul ini mempertahankan data cache hanya ketika file cache ada untuk file target.

Gunakan **--xlate-cache=clear** untuk memulai manajemen cache atau untuk membersihkan semua data cache yang ada. Setelah dieksekusi dengan opsi ini, file cache baru akan dibuat jika belum ada dan kemudian secara otomatis dipelihara setelahnya.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mempertahankan file cache jika sudah ada.

    - `create`

        Buat file cache kosong dan keluar.

    - `always`, `yes`, `1`

        Pertahankan cache sejauh targetnya adalah file normal.

    - `clear`

        Hapus data cache terlebih dahulu.

    - `never`, `no`, `0`

        Jangan pernah menggunakan file cache meskipun ada.

    - `accumulate`

        Secara default, data yang tidak digunakan akan dihapus dari file cache. Jika Anda tidak ingin menghapusnya dan menyimpannya di dalam file, gunakan `accumulate`.
- **--xlate-update**

    Opsi ini memaksa untuk memperbarui file cache meskipun tidak diperlukan.

# COMMAND LINE INTERFACE

Anda dapat dengan mudah menggunakan modul ini dari baris perintah dengan menggunakan perintah `xlate` yang disertakan dalam distribusi. Lihat halaman manifes `xlate` untuk penggunaan.

Perintah `xlate` mendukung opsi panjang gaya GNU seperti `--to-lang`, `--from-lang`, `--engine`, dan `--file`. Gunakan `xlate -h` untuk melihat semua opsi yang tersedia.

Perintah `xlate` bekerja bersama dengan lingkungan Docker, jadi meskipun Anda tidak memiliki apa pun yang terinstal, Anda dapat menggunakannya selama Docker tersedia. Gunakan opsi `-D` atau `-C`.

Operasi-operasi Docker ditangani oleh [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), yang juga dapat digunakan sebagai perintah mandiri. Perintah `dozo` mendukung berkas konfigurasi `.dozorc` untuk pengaturan kontainer persisten.

Selain itu, karena tersedia makefile untuk berbagai gaya dokumen, penerjemahan ke dalam bahasa lain dapat dilakukan tanpa spesifikasi khusus. Gunakan opsi `-M`.

Anda juga dapat menggabungkan opsi Docker dan `make` sehingga Anda dapat menjalankan `make` di lingkungan Docker.

Menjalankan seperti `xlate -C` akan meluncurkan sebuah shell dengan repositori git yang sedang berjalan.

Baca artikel bahasa Jepang di bagian ["LIHAT JUGA"](#lihat-juga) untuk detailnya.

# EMACS

Muat file `xlate.el` yang disertakan dalam repositori untuk menggunakan perintah `xlate` dari editor Emacs. Fungsi `xlate-region` menerjemahkan wilayah tertentu. Bahasa default adalah `EN-US` dan Anda dapat menentukan bahasa yang digunakan dengan argumen awalan.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Tetapkan kunci autentikasi Anda untuk layanan DeepL.

- OPENAI\_API\_KEY

    Kunci otentikasi OpenAI, digunakan oleh mesin **gpty** versi lama. Mesin **gpt5** berbasis `llm` juga membaca variabel ini, tetapi kunci yang disimpan dengan `llm keys set openai` juga berfungsi.

- GREPLE\_XLATE\_CACHE

    Tetapkan strategi cache default (lihat ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Instal alat baris perintah untuk mesin yang Anda gunakan: `llm` untuk mesin **gpt5**, `deepl` untuk DeepL, `gpty` untuk mesin GPT lama.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Runner Docker Generik yang digunakan oleh xlate untuk operasi kontainer

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Lihat manual **greple** untuk detail tentang pola teks target. Gunakan opsi **--inside**, **--outside**, **--include**, **--exclude** untuk membatasi area pencocokan.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Anda dapat menggunakan modul `-Mupdate` untuk memodifikasi file berdasarkan hasil perintah **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Gunakan **sdif** untuk menampilkan format penanda konflik berdampingan dengan opsi **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Modul Greple **stripe** yang digunakan oleh opsi **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Gambar kontainer Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    Pustaka `getoptlong.sh` yang digunakan untuk penguraian opsi dalam skrip `xlate` dan [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    Perintah `llm` yang digunakan oleh mesin **gpt5** untuk mengakses model LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL pustaka Python dan perintah CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Perpustakaan Python OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Antarmuka baris perintah OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Modul Greple untuk menerjemahkan dan mengganti bagian yang diperlukan saja dengan DeepL API (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Menghasilkan dokumen dalam 15 bahasa dengan modul API DeepL (dalam bahasa Jepang)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Lingkungan Docker terjemahan otomatis dengan DeepL API (dalam bahasa Jepang)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
