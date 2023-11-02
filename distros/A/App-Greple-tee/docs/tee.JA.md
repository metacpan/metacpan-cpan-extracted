# NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果に置き換えるモジュール

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple の **-Mtee** モジュールは、マッチしたテキスト部分を指定されたフィルタコマンドに送り、その結果で置き換える。このアイデアは、**teip**というコマンドから派生したものである。これは、外部のフィルタコマンドに部分的なデータをバイパスするようなものである。

Filterコマンドはモジュール宣言(`-Mtee`)に続き、2つのダッシュ(`--`)で終了する。例えば、次のコマンドは、データ中の一致した単語に対して、`a-z A-Z` の引数を持つコマンド `tr` コマンドを呼び出する。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換する。**greple**は**--cm**オプションでより効果的に同じことができるので、実はこの例自体はあまり意味がない。

デフォルトでは、このコマンドは一つのプロセスとして実行され、マッチした データはすべて混ぜて送られる。マッチしたテキストが改行で終わっていない場合は、その前に追加され、後に削除される。データは一行ずつマップされるので、入力データと出力データの行数は同じでなければならない。

**--discrete**オプションを使用すると、一致した部品ごとに個別のコマンドが呼び出される。以下のコマンドを実行すると、その違いが分かる。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete**オプションを使用する場合、入出力データの行数は同一である必要はない。

# VERSION

Version 0.9901

# OPTIONS

- **--discrete**

    一致した部品に対して、個別に新しいコマンドを起動する。

- **--fillup**

    空白でない一連の行を、filterコマンドに渡す前に1行にまとめる。幅の広い文字の間の改行文字は削除され、その他の改行文字は空白に置き換えられる。

- **--blockmatch**

    通常、指定された検索パターンにマッチする領域が外部コマンドに送られる。このオプションが指定されると、マッチした領域ではなく、それを含むブロック全体が処理される。

    例えば、パターン`foo`を含む行を外部コマンドに送るには、行全体にマッチするパターンを指定する必要がある：

        greple -Mtee cat -n -- '^.*foo.*\n'

    しかし、**--blockmatch**オプションを使えば、次のように簡単に実行できる：

        greple -Mtee cat -n -- foo

    **--blockmatch** オプションをつけると、このモジュールは [teip(1)](http://man.he.net/man1/teip) の **-g** オプションのような動作をする。

# WHY DO NOT USE TEIP

まず第一に、**teip**コマンドでできることは、いつでもそれを使ってください。これは優れたツールで、**greple**よりずっと速い。

**greple**は文書ファイルの処理を目的としているため、マッチエリアの制御など、それに適した機能を多く持っている。それらの機能を活用するために、**greple**を使う価値はあるかもしれない。

また、**teip**は複数行のデータを1つの単位として扱うことができないが、**greple**は複数行からなるデータチャンクに対して個別のコマンドを実行することが可能である。

# EXAMPLE

次のコマンドは，Perlモジュールファイルに含まれる[perlpod(1)](http://man.he.net/man1/perlpod)スタイルドキュメント内のテキストブロックを検索する。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

このように**Mtee**モジュールと組み合わせて**deepl**コマンドを呼び出すと、DeepLサービスによって翻訳することができる。

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この場合は専用モジュール [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) の方が効果的である。実は、**tee**モジュールの実装のヒントは**xlate**モジュールからきている。

# EXAMPLE 2

次に、LICENSE文書にインデントされた部分がある。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

この部分は**tee**モジュールと**ansifold**コマンドで整形することができる。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

`--discrete` オプションを使うと時間がかかる。そこで、`--separate ' \r'`オプションと`ansifold`を併用することで、NLの代わりにCR文字を使って1行を生成することができる。

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

その後、[tr(1)](http://man.he.net/man1/tr)コマンドなどでCRをNLに変換する。

    ... | tr '\r' '\n'

# EXAMPLE 3

ヘッダ行以外から文字列を grep したい場合を考えてみよう。例えば、`docker image ls`コマンドから画像を検索したいが、ヘッダ行は残しておきたい場合である。以下のコマンドで可能である。

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

オプション`-Mline -L 2:`は2行目から最後の行を検索し、`grep perl`コマンドに送る。オプション`--discrete`が必要だが、これは一度しか呼ばれないので、性能上の欠点はない。

この場合、`teip -l 2- -- grep` は出力行数が入力行数より少ないのでエラーになる。しかし、結果は非常に満足のいくものである :)

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee)、[https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)。

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)を使用する。

# BUGS

`--fillup` オプションは韓国語テキストでは正しく動作しないかもしれない。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
