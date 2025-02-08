# NAME

cat-v - 可视化非打印字符

# SYNOPSIS

cat-v \[ 选项 \] args ...

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

Version 1.03

# DESCRIPTION

`cat -v` 命令常用于显示无法显示的字符，但并不总是适合查看现代应用程序的输出，因为它会转换所有非 ASCII 字符。

`cat-v` 命令可将空白和控制字符可视化，同时保留显示可显示的图形字符。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/tree.png">
</div>

此外，默认情况下不转换转义字符，因此保留了 ANSI 转义序列的装饰。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/visualized.png">
</div>

有时需要将空白字符可视化。`cat -t` 命令可以将制表符可视化，但问题是它破坏了可视化格式。我们可能希望在保留格式的同时，看到哪些部分是制表符，哪些部分是空白字符。行尾的额外空白字符也可以通过可视化来发现。

使用 `cat-v`，制表符可以可视化，显示的空格不会改变。

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-cat-v/main/images/tabstyle-needle.png">
</div>

控制字符可以用控制格式和 Unicode 符号字符显示。默认情况下，换行符和转义字符以外的控制字符显示为相应的 Unicode 符号。

第二个字段是默认操作。`s` 表示符号，`m` 表示 Unicode 标识，`0` 表示不转换。

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

目前，Unicode 标识可用于以下字符

    nul   \x{2205}  ∅  EMPTY SET
    bel   \x{237E}  ⍾  BELL SYMBOL
    nl    \x{23CE}  ⏎  RETURN SYMBOL
    np    \x{2398}  ⎘  NEXT PAGE
    sp    \x{00B7}  ·  MIDDLE DOT
    del   \x{232B}  ⌫  ERASE TO THE LEFT

# OPTIONS

- **-n**, **--reset**

    禁用所有字符转换和制表符扩展，并重置重复字符。因此，`cat-v -n`实际上什么也不做，就像 `cat` 命令一样。

- **-c**, **--visible** _name_=_flag_,...

    将字符类型和标记作为参数，以指定要可视化的字符和转换格式。

        c  control style
        e  escape style
        s  symbol style
        m  Unicode mark (if exists)
        0  do not convert
        *  non-alphanumeric char is used as a replacement

    选项 `-c nl=1` 也可用于显示换行符。仅对于换行符，在显示转换结果后，会同时输出原始字符。

    使用上面列表中的名称来指定字符类型。如果要转换转义字符而不转换制表符，请使用以下命令

        cat-v -c tab=0 -c esc=s

    可以同时指定多个项目。下面的示例将 `tab` 和 `bel` 设置为 0，将 `esc` 设置为 `s`。

        cat-v -c tab=bel=0,esc=s

    如果为名称指定了 `all`，则该值适用于所有字符类型。下面的命令将所有字符设置为 `s`，然后将 `nl`、`nl`、`np` 和 `sp` 设置为 `m`，并禁用 `esc`。这是默认状态。

        cat-v -c all=s,nul=nl=np=sp=m,esc=0

    如果没有指定任何名称标签，则假定给出的是 `all`。下面的命令以转义形式打印除换行符以外的所有控制字符，这与 Perl 的字符串字面形式兼容。

        cat-v -n -ce,nl=0

    上述命令与此完全相同。

        cat-v --no-expand --reset --visible all=e,nl=0

- **--**_name_\[=_replacement_\]

    所有控制字符也可以通过带有其名称的选项访问。例如，选项 `--nl` 是为换行符定义的。

    单独使用时，它可以激活该字符的可见性。

        cat-v --nl

    若要禁用，则设置值为 0。

        cat-v --nl=0

    如果输入的不是字母或数字，则会被该字母取代。

        cat-v --nl='$'

    如果输入两个或两个以上字符的字符串，该字符串将被解释为 Unicode 字符名。

        cat-v --nl='RETURN SYMBOL' --sp='MIDDLE DOT'

    如果标志以 `+` 开头，则该字符将被添加到重复列表中。

        cat-v --esc=+s

    因此，上述命令的含义将与如下内容相同。

        cat-v --esc=s --repeat +esc

- **--repeat**=_name_\[,_name_...\]

    指定在输出转换字符的同时输出原始字符的字符类型。默认设置为 `nl,np`。下面的命令将正确输出带有转义字符的原始 ANSI 序列。

        cat-v -c esc --repeat esc,nl

    如果 _name_ 以 `+` 开头，则在现有配置的基础上添加该字符。

        cat-v -c esc --repeat +esc

- **-o**, **-oo**, **--original**

    如果转换后的字符串与原始字符串不同，则先输出原始字符串，然后再输出转换后的字符串。如果指定两次，则始终打印原始字符串。

    您可以将此输出与 [App::cdif](https://metacpan.org/pod/App%3A%3Acdif) 的 `--line-by-line` (`--lxl`) 选项一起使用。

- **-t**\[_n_\], **--expand**\[=_n_\]
- **-T**, **--no-expand**

    Tab 字符默认为展开字符。要明确禁用它，请使用 **-T** 或 **--no-expand** 选项。

    如果为 **-t** 选项指定了一个可选数字，该数字将被视为制表符宽度。以下两条命令是等价的：

        cat-v -t4
        cat-v -t --tabstop=4

    默认情况下使用 `needle` 样式，可以使用 `--tabstyle` 更改。如果指定 `--tabstyle` 选项且不带参数，则会显示可用样式列表。

    通过在 `~/.cat-vrc` 文件中设置以下选项，可以默认禁用制表符扩展。

        option default --no-expand

    在这种情况下，可以使用 `-t` 选项临时启用制表符扩展。

- **--tabstop**=# (DEFAULT: 8)

    设置制表符宽度。

- **--tabhead**=#
- **--tabspace**=#

    设置制表符头和后面的空格字符。如果选项值的长度超过单字符，则将其视为 unicode 名称。

- **--tabstyle**, **--ts**
- **--tabstyle**=_style_, **--ts**=...
- **--tabstyle**=_head-style_,_space-style_ **--ts**=...

    设置制表符展开的样式。例如选择 `symbol` 或 `shade`。如果组合了两个样式名称，如 `squat-arrow,middle-dot`，则在制表符头使用 `squat-arrow`，在制表符空间使用 `middle-dot`。

    如果调用时不带参数，则显示可用样式表。样式在 [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) 库中定义。

- **-E**, **--escape-backslash**

    将反斜线字符转换为转义形式 `//`。

    虽然反斜杠不是控制字符，但通过这种方式，将其他控制字符转换为转义表达式的结果可以完全解释为各种编程语言的字符串字面意义。

    下面的命令可以重现原始文件的全部内容。

        echo -ne "$(cat-v -Ence FILE)"

# INSTALL

## CPANMINUS

来自 CPAN 档案：

    cpanm App::cat::v

来自 GIT 代码库：

    cpanm https://github.com/tecolicom/App-cat-v.git

# SEE ALSO

- [https://github.com/tecolicom/App-cat-v.git](https://github.com/tecolicom/App-cat-v.git)

    Git 仓库。

- [App::optex::util::filter](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Autil%3A%3Afilter)

    `cat-v` 命令的前身最初是作为 [App::optex](https://metacpan.org/pod/App%3A%3Aoptex) 命令的过滤器模块创建的。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
