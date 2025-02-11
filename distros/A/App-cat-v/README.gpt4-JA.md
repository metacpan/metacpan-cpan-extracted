# NAME

cat-v - 非表示文字の可視化

# SYNOPSIS

cat-v \[ オプション \] 引数 ...

    OPTIONS
       -n   --reset         Disable all character conversion
       -c   --visible=#     Specify visualize characters
       -r   --repeat=#      Specify repeat characters
       -o   --original      Print original line as is
       -t   --expand[=#]    Expand tabs
       -T   --no-expand     Do not expand tabs
       -E                   Escape backslash character
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

Version 1.04

# DESCRIPTION

`cat -v` コマンドは表示できない文字を表示するためによく使われますが、全ての非ASCII文字を変換するため、現代のアプリケーションの出力を見るのには常に適しているわけではありません。

`cat-v` コマンドは空白や制御文字を可視化しながら、表示可能なグラフィック文字の表示を保持します。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/tree.png">
</div>

また、デフォルトではエスケープ文字は変換されないため、ANSIエスケープシーケンスによる装飾が保持されます。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/visualized.png">
</div>

時には空白文字を可視化したいことがあります。`cat -t` コマンドはタブ文字を可視化できますが、問題は視覚的なフォーマットを壊してしまうことです。フォーマットを保持しながら、どの部分がタブでどの部分がスペース文字であるかを見たいかもしれません。行末の余分な空白文字も可視化することで気づくことができます。

`cat-v` を使用すると、表示上のスペースが変わらないようにタブ文字が可視化されます。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/tabstyle-needle.png">
</div>

制御文字は制御フォーマットとUnicode記号文字で表示することができます。デフォルトでは、改行とエスケープ文字以外の制御文字は対応するUnicode記号として表示されます。

第二フィールドはデフォルトのアクションです。`s` は記号、`m` はUnicodeマーク、`0` は変換なしを意味します。

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

この時点で、以下の文字に対してUnicodeマーキングが利用可能です

    nul   \x{2205}  ∅  EMPTY SET
    bel   \x{237E}  ⍾  BELL SYMBOL
    nl    \x{23CE}  ⏎  RETURN SYMBOL
    np    \x{2398}  ⎘  NEXT PAGE
    sp    \x{00B7}  ·  MIDDLE DOT
    esc   \x{21B0}  ↰  UPWARDS ARROW WITH TIP LEFTWARDS
    del   \x{232B}  ⌫  ERASE TO THE LEFT

# OPTIONS

- **-n**, **--reset**

    文字変換やタブ展開を無効にし、繰り返し文字をリセットします。したがって、`cat-v -n` は何も行わないのと同じです、`cat` コマンドのように。

    デフォルトの動作がリセットされると、それ以降に指定されたオプションのみが効果を持ちます。例えば、次のコマンドはタブ文字のみを視覚化します。

        cat-v -nt

- **-c**, **--visible** _name_=_flag_,...

    可視化される文字と変換フォーマットを指定するために、文字タイプとフラグをパラメータとして与えます。

        c  control style
        e  escape style
        s  symbol style
        m  Unicode mark (if exists)
        0  do not convert
        *  non-alphanumeric char is used as a replacement

    オプション `-c nl=1` も使用して改行文字を可視化することができます。改行文字のみ、変換の結果を表示した後、元の文字が同時に出力されます。

    上記のリストの名前を使用して、文字タイプごとに指定します。タブを変換せずにエスケープを変換したい場合は、以下を使用します

        cat-v -c tab=0 -c esc=s

    複数の項目を同時に指定することができます。以下の例では、`tab` と `bel` を 0 に設定し、`esc` を `s` に設定します。

        cat-v -c tab=bel=0,esc=s

    名前に `all` が指定された場合、その値は全ての文字タイプに適用されます。以下のコマンドは全ての文字を `s` に設定し、その後 `nl`、`nl`、`np`、`sp` を `m` に設定し、`esc` を無効にします。これがデフォルトの状態です。

        cat-v -c all=s,nul=nl=np=sp=m,esc=0

    名前ラベルが指定されていない場合、`all` が指定されたと見なされます。次のコマンドは、改行を除くすべての制御文字をエスケープ形式で印刷します。これは Perl の文字列リテラルと互換性があります。

        cat-v -n -ce,nl=0

    上記のコマンドはこれと同一です。

        cat-v --no-expand --reset --visible all=e,nl=0

- **--**_name_\[=_replacement_\]

    全ての制御文字は、その名前でオプションを使用してアクセスすることもできます。例えば、改行文字にはオプション `--nl` が定義されています。

    単独で使用すると、その文字の可視性が有効になります。

        cat-v --nl

    無効にするには、値 0 を与えます。

        cat-v --nl=0

    アルファベットや数字以外の文字が与えられた場合、その文字に置き換えられます。

        cat-v --nl='$'

    2文字以上の文字列が与えられた場合、Unicode文字名として解釈されます。

        cat-v --nl='RETURN SYMBOL' --sp='MIDDLE DOT'

    フラグが`+`で始まる場合、その文字は繰り返しリストに追加されます。

        cat-v --esc=+s

    したがって、上記のコマンドは、以下のように書いた場合と同じ意味を持ちます。

        cat-v --esc=s --repeat +esc

- **--repeat**=_name_\[,_name_...\]

    変換された文字と同時に元の文字を出力するための文字タイプを指定します。デフォルト設定は`nl,np`です。以下は、エスケープ文字を視覚化した状態で元のANSIシーケンスを正しく出力します。

        cat-v -c esc --repeat esc,nl

    _name_が`+`で始まる場合、既存の設定にその文字を追加します。

        cat-v -c esc --repeat +esc

- **-o**, **-oo**, **--original**

    変換された文字列が元の文字列と異なる場合、変換された文字列が出力される前に元の文字列が出力されます。2回指定された場合、元の文字列は常に出力されます。

    この出力は、[App::cdif](https://metacpan.org/pod/App%3A%3Acdif)の`--line-by-line`（`--lxl`）オプションで使用できます。

- **-t**\[_n_\], **--expand**\[=_n_\]
- **-T**, **--no-expand**

    タブ文字はデフォルトで展開されます。明示的に無効にするには、**-T**または**--no-expand**オプションを使用します。

    **-t** オプションに任意の数値が指定された場合、それはタブ幅として扱われます。以下の二つのコマンドは同等です：

        cat-v -t4
        cat-v -t --tabstop=4

    デフォルトでは、スタイル `needle` が適用されますが、`--tabstyle` で変更することができます。引数なしで `--tabstyle` オプションが指定された場合、利用可能なスタイルのリストが表示されます。

    `~/.cat-vrc`ファイルに以下の設定を入れることで、デフォルトでタブ展開を無効にすることができます。

        option default --no-expand

    そのような場合、`-t`オプションで一時的にタブ展開を有効にすることができます。

- **--tabstop**=# (DEFAULT: 8)

    タブ幅を設定します。

- **--tabhead**=#
- **--tabspace**=#

    タブの先頭とそれに続くスペース文字を設定します。オプションの値が単一文字より長い場合、ユニコード名として評価されます。

- **--tabstyle**, **--ts**
- **--tabstyle**=_style_, **--ts**=...
- **--tabstyle**=_head-style_,_space-style_ **--ts**=...

    タブの展開方法のスタイルを設定します。例えば`symbol`や`shade`を選択します。2つのスタイル名が組み合わされている場合、例えば`squat-arrow,middle-dot`、タブの先頭には`squat-arrow`を、タブスペースには`middle-dot`を使用します。

    パラメータなしで呼び出された場合、利用可能なスタイルリストを表示します。スタイルは[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold)ライブラリで定義されています。

- **-E**, **--escape-backslash**

    バックスラッシュ文字をエスケープ形式 `\\` に変換します。

    バックスラッシュは制御文字ではありませんが、この方法では他の制御文字をエスケープ表現に変換する結果が、さまざまなプログラミング言語の文字列リテラルとして完全に解釈されます。

    次のコマンドは元のファイルの完全な内容を再現します。

        echo -ne "$(cat-v -Ence FILE)"

# INSTALL

## CPANMINUS

CPANアーカイブから：

    cpanm App::cat::v

GITリポジトリから：

    cpanm https://github.com/tecolicom/App-cat-v.git

# SEE ALSO

- [https://github.com/tecolicom/App-cat-v.git](https://github.com/tecolicom/App-cat-v.git)

    Gitリポジトリ。

- [App::optex::util::filter](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Autil%3A%3Afilter)

    `cat-v`コマンドの前身は、もともと[App::optex](https://metacpan.org/pod/App%3A%3Aoptex)コマンドのフィルターモジュールとして作成されました。

- [https://harmful.cat-v.org/cat-v/](https://harmful.cat-v.org/cat-v/)

    UNIXスタイル、または cat -v は有害と考えられています

- [https://harmful.cat-v.org/cat-v/unix\_prog\_design.pdf](https://harmful.cat-v.org/cat-v/unix_prog_design.pdf)

    UNIX環境でのプログラム設計

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
