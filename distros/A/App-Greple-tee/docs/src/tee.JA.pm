=encoding utf-8

=head1 NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果に置き換えるモジュールです。

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple の B<-Mtee> モジュールは、マッチしたテキスト部分を指定されたフィルタコマンドに送り、その結果で置き換えます。このアイデアは、B<teip>というコマンドから派生したものです。これは、外部のフィルタコマンドに部分的なデータをバイパスするようなものです。

Filterコマンドはモジュール宣言(C<-Mtee>)に続き、2つのダッシュ(C<-->)で終了します。例えば、次のコマンドは、データ中の一致した単語に対して、C<a-z A-Z> の引数を持つコマンド C<tr> コマンドを呼び出します。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換します。B<greple>はB<--cm>オプションでより効果的に同じことができるので、実はこの例自体はあまり意味がありません。

デフォルトでは、このコマンドは一つのプロセスとして実行され、マッチした データはすべて混ぜて送られます。マッチしたテキストが改行で終わっていない場合は、その前に追加され、後に削除されます。データは一行ずつマップされるので、入力データと出力データの行数は同じでなければなりません。

B<--discrete>オプションを使用すると、一致した部品ごとに個別のコマンドが呼び出されます。以下のコマンドを実行すると、その違いが分かります。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

B<--discrete>オプションを使用する場合、入出力データの行数は同一である必要はありません。

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

一致した部品に対して、個別に新しいコマンドを起動します。

=item B<--fillup>

空白でない一連の行を、filterコマンドに渡す前に1行にまとめます。幅の広い文字の間の改行文字は削除され、その他の改行文字は空白に置き換えられます。

=item B<--blocks>

通常、指定された検索パターンにマッチする領域が外部コマンドに送られます。このオプションが指定されると、マッチした領域ではなく、それを含むブロック全体が処理されます。

例えば、パターンC<foo>を含む行を外部コマンドに送るには、行全体にマッチするパターンを指定する必要があります：

    greple -Mtee cat -n -- '^.*foo.*\n' --all

しかし、B<--blocks> オプションを使えば、次のように簡単にできます：

    greple -Mtee cat -n -- foo --blocks

B<--blocks> オプションをつけると、このモジュールは L<teip(1)> の B<-g> オプションに似た挙動をします。B<--blocks> オプションを使うと、このモジュールはより L<teip(1)> の B<-g> オプションに近い動作をします。

B<--blocks> を B<--all> オプションと一緒に使わないでください。

=item B<--squeeze>

2つ以上の連続する改行文字を1つにまとめます。

=back

=head1 WHY DO NOT USE TEIP

まず第一に、B<teip>コマンドでできることは、いつでもそれを使ってください。これは優れたツールで、B<greple>よりずっと速いです。

B<greple>は文書ファイルの処理を目的としているため、マッチエリアの制御など、それに適した機能を多く持っています。それらの機能を活用するために、B<greple>を使う価値はあるかもしれません。

また、B<teip>は複数行のデータを1つの単位として扱うことができませんが、B<greple>は複数行からなるデータチャンクに対して個別のコマンドを実行することが可能です。

=head1 EXAMPLE

次のコマンドは，Perlモジュールファイルに含まれるL<perlpod(1)>スタイルドキュメント内のテキストブロックを検索します。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

このようにB<Mtee>モジュールと組み合わせてB<deepl>コマンドを呼び出すと、DeepLサービスによって翻訳することができます。

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この場合は専用モジュール L<App::Greple::xlate::deepl> の方が効果的です。実は、B<tee>モジュールの実装のヒントはB<xlate>モジュールからきています。

=head1 EXAMPLE 2

次に、LICENSE文書にインデントされた部分があります。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
この部分はB<tee>モジュールとB<ansifold>コマンドで整形することができます。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

C<--discrete> オプションを使うと時間がかかります。そこで、C<--separate ' \r'>オプションとC<ansifold>を併用することで、NLの代わりにCR文字を使って1行を生成することができます。

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

その後、L<tr(1)>コマンドなどでCRをNLに変換します。

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

ヘッダ行以外から文字列を grep したい場合を考えてみましょう。例えば、C<docker image ls>コマンドから画像を検索したいが、ヘッダ行は残しておきたい場合です。以下のコマンドで可能です。

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

オプションC<-Mline -L 2:>は2行目から最後の行を検索し、C<grep perl>コマンドに送ります。オプションC<--discrete>が必要ですが、これは一度しか呼ばれないので、性能上の欠点はありません。

この場合、C<teip -l 2- -- grep> は出力行数が入力行数より少ないのでエラーになります。しかし、結果は非常に満足のいくものです :)

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>、L<https://github.com/kaz-utashiro/App-Greple-tee>。

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>を使用します。

=head1 BUGS

C<--fillup> オプションは韓国語テキストでは正しく動作しないかもしれません。

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
