=encoding utf-8

=head1 NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果に置き換えるモジュール

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple の B<-Mtee> モジュールは、マッチしたテキスト部分を指定されたフィルタコマンドに送り、その結果で置き換える。このアイデアは、B<teip>というコマンドから派生したものである。これは、外部のフィルタコマンドに部分的なデータをバイパスするようなものである。

Filterコマンドはモジュール宣言(C<-Mtee>)に続き、2つのダッシュ(C<-->)で終了する。例えば、次のコマンドは、データ中の一致した単語に対して、C<a-z A-Z> の引数を持つコマンド C<tr> コマンドを呼び出する。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換する。B<greple>はB<--cm>オプションでより効果的に同じことができるので、実はこの例自体はあまり意味がない。

デフォルトでは、このコマンドは一つのプロセスとして実行され、マッチした データはすべて混ぜて送られる。マッチしたテキストが改行で終わっていない場合は、その前に追加され、後に削除される。データは一行ずつマップされるので、入力データと出力データの行数は同じでなければならない。

B<--discrete>オプションを使用すると、一致した部品ごとに個別のコマンドが呼び出される。以下のコマンドを実行すると、その違いが分かる。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

B<--discrete>オプションを使用する場合、入出力データの行数は同一である必要はない。

=head1 VERSION

Version 0.9901

=head1 OPTIONS

=over 7

=item B<--discrete>

一致した部品に対して、個別に新しいコマンドを起動する。

=item B<--fillup>

空白でない一連の行を、filterコマンドに渡す前に1行にまとめる。幅の広い文字の間の改行文字は削除され、その他の改行文字は空白に置き換えられる。

=item B<--blockmatch>

通常、指定された検索パターンにマッチする領域が外部コマンドに送られる。このオプションが指定されると、マッチした領域ではなく、それを含むブロック全体が処理される。

例えば、パターンC<foo>を含む行を外部コマンドに送るには、行全体にマッチするパターンを指定する必要がある：

    greple -Mtee cat -n -- '^.*foo.*\n'

しかし、B<--blockmatch>オプションを使えば、次のように簡単に実行できる：

    greple -Mtee cat -n -- foo

B<--blockmatch> オプションをつけると、このモジュールは L<teip(1)> の B<-g> オプションのような動作をする。

=back

=head1 WHY DO NOT USE TEIP

まず第一に、B<teip>コマンドでできることは、いつでもそれを使ってください。これは優れたツールで、B<greple>よりずっと速い。

B<greple>は文書ファイルの処理を目的としているため、マッチエリアの制御など、それに適した機能を多く持っている。それらの機能を活用するために、B<greple>を使う価値はあるかもしれない。

また、B<teip>は複数行のデータを1つの単位として扱うことができないが、B<greple>は複数行からなるデータチャンクに対して個別のコマンドを実行することが可能である。

=head1 EXAMPLE

次のコマンドは，Perlモジュールファイルに含まれるL<perlpod(1)>スタイルドキュメント内のテキストブロックを検索する。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

このようにB<Mtee>モジュールと組み合わせてB<deepl>コマンドを呼び出すと、DeepLサービスによって翻訳することができる。

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この場合は専用モジュール L<App::Greple::xlate::deepl> の方が効果的である。実は、B<tee>モジュールの実装のヒントはB<xlate>モジュールからきている。

=head1 EXAMPLE 2

次に、LICENSE文書にインデントされた部分がある。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
この部分はB<tee>モジュールとB<ansifold>コマンドで整形することができる。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

C<--discrete> オプションを使うと時間がかかる。そこで、C<--separate ' \r'>オプションとC<ansifold>を併用することで、NLの代わりにCR文字を使って1行を生成することができる。

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

その後、L<tr(1)>コマンドなどでCRをNLに変換する。

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

ヘッダ行以外から文字列を grep したい場合を考えてみよう。例えば、C<docker image ls>コマンドから画像を検索したいが、ヘッダ行は残しておきたい場合である。以下のコマンドで可能である。

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

オプションC<-Mline -L 2:>は2行目から最後の行を検索し、C<grep perl>コマンドに送る。オプションC<--discrete>が必要だが、これは一度しか呼ばれないので、性能上の欠点はない。

この場合、C<teip -l 2- -- grep> は出力行数が入力行数より少ないのでエラーになる。しかし、結果は非常に満足のいくものである :)

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>、L<https://github.com/kaz-utashiro/App-Greple-tee>。

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>を使用する。

=head1 BUGS

C<--fillup> オプションは韓国語テキストでは正しく動作しないかもしれない。

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "0.9901";

use v5.14;
use warnings;
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use App::cdif::Command;
use Data::Dumper;

our $command;
our $blockmatch;
our $discrete;
our $fillup;

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv;
    }
}

use Unicode::EastAsianWidth;

sub fillup_paragraph {
    (my $s1, local $_, my $s2) = $_[0] =~ /\A(\s*)(.*?)(\s*)\z/s or die;
    s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//g;
    s/\s+/ /g;
    $s1 . $_ . $s2;
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if ($fillup) {
	$data =~ s/^.+(?:\n.+)*/fillup_paragraph(${^MATCH})/pmge;
    }
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    $exec->command($command)->setstdin($data)->update->data // '';
}

sub jammed_call {
    my @need_nl = grep { $_[$_] !~ /\n\z/ } keys @_;
    my @from = @_;
    $from[$_] .= "\n" for @need_nl;
    my @lines = map { int tr/\n/\n/ } @from;
    my $from = join '', @from;
    my $out = call $from;
    my @out = $out =~ /.*\n/g;
    if (@out < sum @lines) {
	die "Unexpected response from command:\n\n$out\n";
    }
    my @to = map { join '', splice @out, 0, $_ } @lines;
    $to[$_] =~ s/\n\z// for @need_nl;
    return @to;
}

my @jammed;

sub postgrep {
    my $grep = shift;
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback}->[0] ]
	      } $grep->result
	    ] ];
    }
    return if $discrete;
    @jammed = my @block = ();
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }
    @jammed = jammed_call @block if @block;
}

sub callback {
    if ($discrete) {
	call { @_ }->{match};
    }
    else {
	shift @jammed // die;
    }
}

1;

__DATA__

builtin --blockmatch $blockmatch
builtin --discrete!  $discrete
builtin --fillup!    $fillup

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
