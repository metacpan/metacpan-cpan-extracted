# NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果に置き換えるモジュールです。

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple の **-Mtee** モジュールは、マッチしたテキスト部分を指定されたフィルタコマンドに送り、その結果で置き換えます。このアイデアは、**teip**というコマンドから派生したものです。これは、外部のフィルタコマンドに部分的なデータをバイパスするようなものです。

Filterコマンドはモジュール宣言(`-Mtee`)に続き、2つのダッシュ(`--`)で終了します。例えば、次のコマンドは、データ中の一致した単語に対して、`a-z A-Z` の引数を持つコマンド `tr` コマンドを呼び出します。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換します。**greple**は**--cm**オプションでより効果的に同じことができるので、実はこの例自体はあまり意味がありません。

デフォルトでは、このコマンドは一つのプロセスとして実行され、マッチした データはすべて混ぜて送られます。マッチしたテキストが改行で終わっていない場合は、その前に追加され、後に削除されます。データは一行ずつマップされるので、入力データと出力データの行数は同じでなければなりません。

**--discrete**オプションを使用すると、一致した部品ごとに個別のコマンドが呼び出されます。以下のコマンドを実行すると、その違いが分かります。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete**オプションを使用する場合、入出力データの行数は同一である必要はありません。

# VERSION

Version 0.9902

# OPTIONS

- **--discrete**

    一致した部品に対して、個別に新しいコマンドを起動します。

- **--fillup**

    空白でない一連の行を、filterコマンドに渡す前に1行にまとめます。幅の広い文字の間の改行文字は削除され、その他の改行文字は空白に置き換えられます。

- **--blocks**

    通常、指定された検索パターンにマッチする領域が外部コマンドに送られます。このオプションが指定されると、マッチした領域ではなく、それを含むブロック全体が処理されます。

    例えば、パターン`foo`を含む行を外部コマンドに送るには、行全体にマッチするパターンを指定する必要があります：

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    しかし、**--blocks** オプションを使えば、次のように簡単にできます：

        greple -Mtee cat -n -- foo --blocks

    **--blocks** オプションをつけると、このモジュールは [teip(1)](http://man.he.net/man1/teip) の **-g** オプションに似た挙動をします。**--blocks** オプションを使うと、このモジュールはより [teip(1)](http://man.he.net/man1/teip) の **-g** オプションに近い動作をします。

    **--blocks** を **--all** オプションと一緒に使わないでください。

- **--squeeze**

    2つ以上の連続する改行文字を1つにまとめます。

# WHY DO NOT USE TEIP

まず第一に、**teip**コマンドでできることは、いつでもそれを使ってください。これは優れたツールで、**greple**よりずっと速いです。

**greple**は文書ファイルの処理を目的としているため、マッチエリアの制御など、それに適した機能を多く持っています。それらの機能を活用するために、**greple**を使う価値はあるかもしれません。

また、**teip**は複数行のデータを1つの単位として扱うことができませんが、**greple**は複数行からなるデータチャンクに対して個別のコマンドを実行することが可能です。

# EXAMPLE

次のコマンドは，Perlモジュールファイルに含まれる[perlpod(1)](http://man.he.net/man1/perlpod)スタイルドキュメント内のテキストブロックを検索します。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

このように**Mtee**モジュールと組み合わせて**deepl**コマンドを呼び出すと、DeepLサービスによって翻訳することができます。

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この場合は専用モジュール [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) の方が効果的です。実は、**tee**モジュールの実装のヒントは**xlate**モジュールからきています。

# EXAMPLE 2

次に、LICENSE文書にインデントされた部分があります。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

この部分は**tee**モジュールと**ansifold**コマンドで整形することができます。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

`--discrete` オプションを使うと時間がかかります。そこで、`--separate ' \r'`オプションと`ansifold`を併用することで、NLの代わりにCR文字を使って1行を生成することができます。

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

その後、[tr(1)](http://man.he.net/man1/tr)コマンドなどでCRをNLに変換します。

    ... | tr '\r' '\n'

# EXAMPLE 3

ヘッダ行以外から文字列を grep したい場合を考えてみましょう。例えば、`docker image ls`コマンドから画像を検索したいが、ヘッダ行は残しておきたい場合です。以下のコマンドで可能です。

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

オプション`-Mline -L 2:`は2行目から最後の行を検索し、`grep perl`コマンドに送ります。オプション`--discrete`が必要ですが、これは一度しか呼ばれないので、性能上の欠点はありません。

この場合、`teip -l 2- -- grep` は出力行数が入力行数より少ないのでエラーになります。しかし、結果は非常に満足のいくものです :)

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee)、[https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)。

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)を使用します。

# BUGS

`--fillup` オプションは韓国語テキストでは正しく動作しないかもしれません。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
