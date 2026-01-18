# NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果で置き換えるモジュール

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.04

# DESCRIPTION

Greple の **-Mtee** モジュールは、マッチしたテキスト部分を指定したフィルタコマンドに送り、そのコマンドの結果で置き換えます。アイデアは **teip** と呼ばれるコマンドに由来します。データの一部を外部フィルタコマンドにバイパスするようなイメージです。

フィルタコマンドはモジュール宣言（`-Mtee`）に続けて記述し、二つのダッシュ（`--`）で終端します。例えば、次のコマンドはデータ中のマッチした単語に対して、コマンド `tr` を `a-z A-Z` の引数で呼び出します。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換します。実はこの例自体はあまり有用ではありません。というのも、**greple** 自身が **--cm** オプションで同様のことをより効率的に行えるからです。

デフォルトでは、コマンドは単一プロセスとして実行され、すべてのマッチしたデータは混在したままそのプロセスに送られます。マッチしたテキストが改行で終わっていなければ、送信前に改行が追加され、受信後に取り除かれます。入力と出力のデータは行単位で対応付けられるため、入力と出力の行数は一致していなければなりません。

**--discrete** オプションを使うと、マッチした各テキスト領域ごとに個別のコマンドが呼び出されます。違いは次のコマンド群で確認できます。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete** オプションを用いる場合、入力と出力の行数は一致している必要はありません。

# OPTIONS

- **--discrete**

    マッチした各部分ごとに新しいコマンドを個別に起動します。

- **--bulkmode**

    <--discrete> オプションでは各コマンドはオンデマンドで実行されます。<--bulkmode> オプションではすべての変換を一括で実行します。

- **--crmode**

    このオプションは、各ブロックの途中にあるすべての改行文字をキャリッジリターンに置き換えます。コマンド実行結果に含まれるキャリッジリターンは改めて改行に戻されます。これにより、**--discrete** オプションを使わずとも、複数行から成るブロックをバッチ処理できます。

    これは [ansifold](https://metacpan.org/pod/ansifold) コマンドの **--crmode** オプションと相性がよく、CR 区切りのテキストを結合し、CR で区切られた折り畳み行を出力します。

- **--fillup**

    フィルタコマンドに渡す前に、連続する非空行を1行にまとめます。全角文字（日本語、中国語）の間の改行は削除し、その他の改行は空白に置き換えます。韓国語（ハングル）は ASCII テキスト同様に空白で連結します。

- **--squeeze**

    連続する2つ以上の改行を1つにまとめます。

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip) の **--offload** オプションは、別モジュール [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL)（**-ML**）で実装されています。

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    **-ML** モジュールを使って、次のように偶数行のみを処理することもできます。

        greple -Mtee cat -n -- -ML 2::2

# CONFIGURATION

モジュールのパラメータは、次の文法で **Getopt::EX::Config** モジュールにより設定できます。

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

これはシェルのエイリアスやモジュールファイルと組み合わせると便利です。

利用可能なパラメータは **discrete**, **bulkmode**, **crmode**, **fillup**, **squeeze**, **blocks** です。

# FUNCTION CALL

外部コマンドの代わりに、コマンド名の前に`&`を付けることでPerl関数を呼び出せます。

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

関数はフォークされた子プロセスで実行されるため、次の要件に従う必要があります:

- 一致したテキストを**STDIN**から読み込む
- 変換結果を**STDOUT**へ出力する
- 引数は`@ARGV`および`@_`の両方で渡される

任意の完全修飾関数名を使用できます:

    greple -Mtee '&Your::Module::function' -- ...

モジュールは未ロードの場合、自動的にロードされます。

便宜のため、以下の短いエイリアスが利用可能です:

- **&ansicolumn**

    `App::ansicolumn::ansicolumn`を呼び出します。

- **&ansifold**

    `App::ansifold::ansifold`を呼び出します。

- **&cat-v**

    `App::cat::v->new->run(@_)`を呼び出します。

関数呼び出しを使用すると、呼び出しごとに外部プロセスをフォークするオーバーヘッドを回避でき、**--discrete**オプションと併用した場合にパフォーマンスを大幅に向上させることができます。

# LEGACIES

**greple** に **--stretch**（**-S**）オプションが実装されたため、**--blocks** オプションは不要になりました。次のように簡単に実行できます。

    greple -Mtee cat -n -- --all -SE foo

将来的に非推奨となる可能性があるため、**--blocks** の使用は推奨されません。

- **--blocks**

    通常、指定された検索パターンに一致する領域が外部コマンドに送られます。このオプションを指定すると、一致した領域ではなく、それを含むブロック全体が処理されます。

    例えば、パターン `foo` を含む行を外部コマンドに送るには、行全体に一致するパターンを指定する必要があります:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    しかし **--blocks** オプションを使えば、次のように簡単に実行できます:

        greple -Mtee cat -n -- foo --blocks

    **--blocks** オプションを用いると、このモジュールは [teip(1)](http://man.he.net/man1/teip) の **-g** オプションにより近い動作になります。そうでなければ、動作は **-o** オプションを付けた [teip(1)](http://man.he.net/man1/teip) に似ています。

    **--blocks** を **--all** オプションと併用しないでください。ブロックがデータ全体になってしまいます。

# WHY DO NOT USE TEIP

まず何より、**teip** コマンドで実現できる場合はそれを使ってください。優れたツールであり、**greple** よりもはるかに高速です。

**greple** は文書ファイルの処理を目的に設計されているため、マッチ領域の制御など、それに適した多くの機能を備えています。それらの機能を活用するために **greple** を使う価値はあります。

また、**teip** は複数行のデータをひとつの単位として扱えませんが、**greple** は複数行からなるデータチャンクに対して個別のコマンドを実行できます。

# EXAMPLE

次のコマンドは、Perl モジュールファイルに含まれる [perlpod(1)](http://man.he.net/man1/perlpod) 形式ドキュメント内のテキストブロックを見つけます。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

上記コマンドに **-Mtee** モジュールを組み合わせて **deepl** コマンドを呼び出すことで、DeepL サービスで翻訳できます。使い方は次のとおりです:

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この目的には専用モジュール [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) のほうが効果的です。実際、**tee** モジュールの実装のヒントは **xlate** モジュールから得られました。

# EXAMPLE 2

次のコマンドは、LICENSE ドキュメント内のいくつかのインデントされた部分を見つけます。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

この部分は、**tee** モジュールと **ansifold** コマンドを使って再整形できます。両方の **--crmode** オプションを併用すると、複数行ブロックを効率よく処理できます:

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

**--discrete** オプションも使用できますが、複数のプロセスを起動するため、実行に時間がかかります。

# EXAMPLE 3

ヘッダー行以外から文字列を grep したい状況を考えてみます。例えば、`docker image ls` コマンドから Docker イメージ名を検索したいが、ヘッダー行は残したい場合です。以下のコマンドで実現できます。

    greple -Mtee grep perl -- -ML 2: --discrete --all

オプション `-ML 2:` は、後ろから2行目以降を取り出して `grep perl` コマンドに送ります。入力と出力の行数が変わるため --discrete オプションが必要ですが、コマンドは一度しか実行されないので性能上のデメリットはありません。

同じことを **teip** コマンドでやろうとすると、`teip -l 2- -- grep` は出力行数が入力行数より少ないためエラーになります。ただし、得られる結果自体に問題はありません。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold), [https://github.com/tecolicom/App-ansifold](https://github.com/tecolicom/App-ansifold)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
