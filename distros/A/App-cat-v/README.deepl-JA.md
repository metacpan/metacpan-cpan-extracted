# NAME

cat-v - 非印刷文字を可視化する

# SYNOPSIS

cat-v \[ オプション \] args ...

    OPTIONS
       -n   --reset         Disable all character conversion
       -c   --visible=#     Specify visualize characters
       -r   --repeat=#      Specify repeat characters
       -o   --original      Print original line as is
       -t   --expand[=#]    Expand tabs
       -T   --no-expand     Do not expand tabs
      --ts  --tabstyle=#    Set tab style
            --tabstop=#     Set tab width
            --tabhead=#     Set tab-head character
            --tabspace=#    Set tab-space character
       -h   --help          Print this message
       -v   --version       Print version

    OPTIONS FOR EACH CHARACTERS
      --esc                 Enable escape
      --esc=c               Show escape in control format
      --esc=+c              Show escape in control format and reproduce
      --nl=0                Disable newline
      --sp=~                Convert spaces to tilde
      --sp='OPEN BOX'       Unicode name
      --esc=+U+035B         Unicode code point

# VERSION

Version 1.02

# DESCRIPTION

`cat -v`コマンドは、表示できない文字を表示するためによく使われるが、ASCII以外の文字をすべて変換してしまうため、最新のアプリケーションの出力を表示するには必ずしも適していません。

`cat-v`コマンドは、表示可能なグラフィック文字の表示を維持したまま、空白文字と制御文字を可視化します。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/tree.png">
</div>

また、デフォルトではエスケープ文字は変換されないので、ANSIエスケープシーケンスによる装飾は保持されます。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/visualized.png">
</div>

空白文字を可視化することが望ましい場合もあります。`cat -t`コマンドはタブ文字を視覚化できるが、問題は視覚的な書式を壊してしまうことです。書式を保持したまま、どの部分がタブでどの部分が空白文字なのかを確認したい場合があります。行末の余分な空白文字も、視覚化することで気づくことができます。

`cat-v`を使うと、タブ文字は表示上のスペースが変わらないように視覚化されます。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/tabstyle-needle.png">
</div>

制御文字は、制御フォーマットとユニコード記号文字で表示できます。デフォルトでは、改行文字とエスケープ文字以外の制御文字は、対応するユニコード記号として表示されます。

2番目のフィールドはデフォルトの動作です。`s`は記号、`m`はUnicodeマーク、`0`は無変換を表します。

    nul   s  \000  \x{2400}  ␀  SYMBOL FOR NULL
    soh   s  \001  \x{2401}  ␁  SYMBOL FOR START OF HEADING
    stx   s  \002  \x{2402}  ␂  SYMBOL FOR START OF TEXT
    etx   s  \003  \x{2403}  ␃  SYMBOL FOR END OF TEXT
    eot   s  \004  \x{2404}  ␄  SYMBOL FOR END OF TRANSMISSION
    enq   s  \005  \x{2405}  ␅  SYMBOL FOR ENQUIRY
    ack   s  \006  \x{2406}  ␆  SYMBOL FOR ACKNOWLEDGE
    bel   s  \007  \x{2407}  ␇  SYMBOL FOR BELL
    bs    s  \010  \x{2408}  ␈  SYMBOL FOR BACKSPACE
    ht    s  \011  \x{2409}  ␉  SYMBOL FOR HORIZONTAL TABULATION
    nl    m  \012  \x{240A}  ␊  SYMBOL FOR LINE FEED
    vt    s  \013  \x{240B}  ␋  SYMBOL FOR VERTICAL TABULATION
    np    m  \014  \x{240C}  ␌  SYMBOL FOR FORM FEED
    cr    s  \015  \x{240D}  ␍  SYMBOL FOR CARRIAGE RETURN
    so    s  \016  \x{240E}  ␎  SYMBOL FOR SHIFT OUT
    si    s  \017  \x{240F}  ␏  SYMBOL FOR SHIFT IN
    dle   s  \020  \x{2410}  ␐  SYMBOL FOR DATA LINK ESCAPE
    dc1   s  \021  \x{2411}  ␑  SYMBOL FOR DEVICE CONTROL ONE
    dc2   s  \022  \x{2412}  ␒  SYMBOL FOR DEVICE CONTROL TWO
    dc3   s  \023  \x{2413}  ␓  SYMBOL FOR DEVICE CONTROL THREE
    dc4   s  \024  \x{2414}  ␔  SYMBOL FOR DEVICE CONTROL FOUR
    nak   s  \025  \x{2415}  ␕  SYMBOL FOR NEGATIVE ACKNOWLEDGE
    syn   s  \026  \x{2416}  ␖  SYMBOL FOR SYNCHRONOUS IDLE
    etb   s  \027  \x{2417}  ␗  SYMBOL FOR END OF TRANSMISSION BLOCK
    can   s  \030  \x{2418}  ␘  SYMBOL FOR CANCEL
    em    s  \031  \x{2419}  ␙  SYMBOL FOR END OF MEDIUM
    sub   s  \032  \x{241A}  ␚  SYMBOL FOR SUBSTITUTE
    esc   0  \033  \x{241B}  ␛  SYMBOL FOR ESCAPE
    fs    s  \034  \x{241C}  ␜  SYMBOL FOR FILE SEPARATOR
    gs    s  \035  \x{241D}  ␝  SYMBOL FOR GROUP SEPARATOR
    rs    s  \036  \x{241E}  ␞  SYMBOL FOR RECORD SEPARATOR
    us    s  \037  \x{241F}  ␟  SYMBOL FOR UNIT SEPARATOR
    sp    m  \040  \x{2420}  ␠  SYMBOL FOR SPACE
    del   s  \177  \x{2421}  ␡  SYMBOL FOR DELETE
    nbsp  s  \240  \x{2423}  ␣  OPEN BOX

現時点では、Unicodeマークは以下の文字で利用可能です。

    nul   \x{2205}  ∅  EMPTY SET
    bel   \x{237E}  ⍾  BELL SYMBOL
    nl    \x{23CE}  ⏎  RETURN SYMBOL
    np    \x{2398}  ⎘  NEXT PAGE
    sp    \x{00B7}  ·  MIDDLE DOT
    del   \x{232B}  ⌫  ERASE TO THE LEFT

# OPTIONS

- **-n**, **--reset**

    すべての文字変換を無効にし、繰り返し文字をリセットします。

- **-c**, **--visible** _name_=_flag_,...

    可視化する文字と変換形式を指定するために、パラメータとして文字タイプとフラグを与えます。

        c  control style
        s  symbol style
        m  Unicode mark (if exists)
        0  do not convert
        *  non-alphanumeric char is used as a replacement

    オプション `-c nl=1` は、改行文字を可視化するのにも使えます。改行文字の場合のみ、変換結果を表示した後、元の文字も同時に出力されます。

    文字の種類で指定するには、上のリストの名前を使う。タブを変換せずにエスケープを変換したい場合は、次のようにします。

        cat-v -c tab=0 -c esc=s

    複数の項目を同時に指定することができます。以下の例では、`tab`と`bel`を0に、`esc`を`s`に設定しています。

        cat-v -c tab=bel=0,esc=s

    名前に `all` を指定すると、その値はすべての文字タイプに適用されます。次のコマンドは、すべての文字を`s`に設定し、`nl`、`nl`、`np`、`sp`を`m`に設定し、`esc`を無効にします。これがデフォルトの状態です。

        cat-v -c all=s,nul=nl=np=sp=m,esc=0

- **--**_name_\[=_replacement_\]

    すべての制御文字は、その名前を持つオプションでアクセスすることもできます。例えば、オプション `--nl` は改行文字のために定義されています。

    単独で使用すると、この文字の可視性が有効になります。

        cat-v --nl

    無効にするには0を指定します。

        cat-v --nl=0

    アルファベットや数字以外の文字が指定された場合は、その文字に置き換えられます。

        cat-v --nl='$'

    2文字以上の文字列が指定された場合、Unicode文字名として解釈されます。

        cat-v --nl='RETURN SYMBOL' --sp='MIDDLE DOT'

    フラグが`+`で始まる場合、その文字はリピートリストに追加されます。

        cat-v --esc=+s

    つまり、上記のコマンドは、次のように書いたのと同じ意味になります。

        cat-v --esc=s --repeat +esc

- **--repeat**=_name_\[,_name_...\]

    変換後の文字と同時に元の文字を出力する文字種を指定します。デフォルトは`nl,np`です。以下のようにすると、エスケープ文字が可視化された元のANSIシーケンスが正しく出力されます。

        cat-v -c esc --repeat esc,nl

    _name_ が `+` で始まる場合は、既存の設定に加えてその文字を追加します。

        cat-v -c esc --repeat +esc

- **-o**, **-oo**, **--original**

    変換後の文字列が元の文字列と異なる場合、変換後の文字列が出力される前に元の文字列が出力されます。2回指定すると、常に元の文字列が出力されます。

    この出力は、[App::cdif](https://metacpan.org/pod/App%3A%3Acdif)の`--line-by-line` (`--lxl`)オプションで使うことができます。

- **-t**\[_n_\], **--expand**\[=_n_\]
- **-T**, **--no-expand**

    タブ文字はデフォルトで展開されます。明示的に無効にするには、**-T**または**--no-expand**オプションを使用します。

    **-t**オプションに任意の数字が与えられた場合、それはタブ幅として扱われます。次の2つのコマンドは等価である：

        cat-v -t4
        cat-v -t --tabstop=4

    デフォルトでは`needle`スタイルが適用され、`--tabstyle`で変更できます。`--tabstyle` オプションが引数なしで指定された場合、利用可能なスタイルのリストが表示されます。

    `~/.cat-vrc`ファイルに以下の設定を記述することで、デフォルトでタブ展開を無効にすることができます。

        option default --no-expand

    その場合、`-t`オプションで一時的にタブ展開を有効にすることができます。

- **--tabstop**=# (DEFAULT: 8)

    タブ幅を設定します。

- **--tabhead**=#
- **--tabspace**=#

    タブヘッドとそれに続くスペース文字を設定します。オプ シ ョ ン値が 1 文字 よ り 長い場合は、 unicode 名 と し て評価 さ れます。

- **--tabstyle**, **--ts**
- **--tabstyle**=_style_, **--ts**=...
- **--tabstyle**=_head-style_,_space-style_ **--ts**=...

    タブの展開方法を設定します。例えば、`記号`または`影`を選択します。`squat-arrow,middle-dot`のように2つのスタイル名を組み合わせた場合、タブヘッドには`squat-arrow`を、タブスペースには`middle-dot`を使用します。

    パラメータなしで呼ばれた場合、利用可能なスタイルリストを表示します。スタイルは [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) ライブラリで定義されています。

# INSTALL

## CPANMINUS

CPANアーカイブから：

    cpanm App::cat::v

GITリポジトリから

    cpanm https://github.com/tecolicom/App-cat-v.git

# SEE ALSO

- [https://github.com/tecolicom/App-cat-v.git](https://github.com/tecolicom/App-cat-v.git)

    Gitリポジトリ。

- [App::optex::util::filter](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Autil%3A%3Afilter)

    `cat-v`コマンドの前身は、もともと[App::optex](https://metacpan.org/pod/App%3A%3Aoptex)コマンドのフィルタモジュールとして作られたものです。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
