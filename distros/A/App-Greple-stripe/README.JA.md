# NAME

App::Greple::stripe - Greple ゼブラストライプモジュール

# SYNOPSIS

    greple -Mstripe [ module options -- ] ...

# VERSION

Version 1.02

# DESCRIPTION

[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) はマッチしたテキストをゼブラストライプで表示する [greple](https://metacpan.org/pod/App%3A%3AGreple) のモジュールです。

次のコマンドは連続する2行にマッチします。

    greple -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/normal.png">
    </p>
</div>

しかし、マッチしたブロックは同じ色で表示されるので、どこでブロックが途切れるのかがわかりません。一つの方法は、`--blockend`オプションを使って明示的にブロックを表示することです。

    greple -E '(.+\n){1,2}' --face +E --blockend=--

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/blockend.png">
    </p>
</div>

stripeモジュールを使うと、同じパターンにマッチしたブロックは、類似色系列の異なる色で着色されます。

    greple -Mstripe -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/stripe.png">
    </p>
</div>

デフォルトでは2つの色系列が用意されている。そのため、複数のパターンを検索した場合、偶数パターンと奇数パターンでは、それぞれ異なる色系列が割り当てられる。

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
    </p>
</div>

上の例のように複数のパターンを指定した場合、すべてのパターンに一致する行だけが出力される。そこで、この条件を緩和するために`--need=1`オプションが必要となる。

3つ以上のパターンで異なる色系列を使いたい場合は、モジュールを呼び出すときに `step` 回数を指定してください。シリーズ数は6まで増やせます。

    greple -Mstripe::config=step=3 --need=1 -E p1 -E p2 -E p3 ...

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/step-3.png">
    </p>
</div>

# MODULE OPTIONS

**stripe**モジュール特有のオプションがあります。これらはモジュール宣言時に指定するか、モジュール宣言の後に`--`で終わるオプションとして指定します。

以下の3つのコマンドは全く同じ効果をもたらします。

    greple -Mstripe::config=step=3

    greple -Mstripe --config step=3 --

    greple -Mstripe --step=3 --

なお、現時点では下位互換性のために`config`の代わりに`set`関数を使うことができます。

- **-Mstripe::config**=**step**=_n_
- **--step**=_n_

    ステップ数を_n_に設定する。

- **-Mstripe::config**=**darkmode**
- **--darkmode**

    暗い背景色を使う。

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/darkmode.png">
            </p>
    </div>

    すべてのカラーマップの前景色を設定するには `--face` オプションを使います。次のコマンドは前景色を白に設定し、行全体を背景色で塗りつぶします。

        greple -Mstripe --darkmode -- --face +WE

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/dark-white.png">
            </p>
    </div>

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[Getopt::EX::Config](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AConfig)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
