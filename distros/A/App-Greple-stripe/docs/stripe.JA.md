# NAME

App::Greple::stripe - Greple ゼブラストライプモジュール

# SYNOPSIS

    greple -Mstripe [ module options -- ] ...

# VERSION

Version 0.9903

# DESCRIPTION

[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) は [greple](https://metacpan.org/pod/App%3A%3AGreple) 用のモジュールで、マッチしたテキストをゼブラストライプで表示します。

次のコマンドは連続する2行にマッチします。

    greple -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/normal.png">
    </p>
</div>

しかし、マッチしたブロックはそれぞれ同じ色で表示されるため、どこでブロックが途切れるのかがわかりません。一つの方法は、`--blockend`オプションを使って明示的にブロックを表示することである。

    greple -E '(.+\n){1,2}' --face +E --blockend=--

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/blockend.png">
    </p>
</div>

stripe モジュールを使うと、同じパターンにマッチしたブロックは、類似した色系列の異なる色で着色されます。

    greple -Mstripe -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/stripe.png">
    </p>
</div>

デフォルトでは、2つの色系列が用意されている。そのため、複数のパターンを検索した場合、偶数パターンと奇数パターンでは異なる色系列が割り当てられる。複数のパターンを指定した場合、すべてのパターンに一致する行だけが出力されるので、この条件を緩和するには `--need=1` オプションが必要である。

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
    </p>
</div>

3つ以上のパターンで異なる色のシリーズを使いたい場合は、モジュールを呼び出す際に`ステップ`カウントを指定する。シリーズ数は6まで増やせる。

    greple -Mstripe::set=step=3 --need=1 -E p1 -E p2 -E p3 ...

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/step-3.png">
    </p>
</div>

# MODULE OPTIONS

**stripe**モジュール特有のオプションがある。これらは、モジュール宣言時に指定するか、モジュール宣言の後に`--`で終わるオプションとして指定することができる。

以下の2つのコマンドは全く同じ効果を持つ。

    greple -Mstripe=set=step=3

    greple -Mstripe --step=3 --

- **-Mstripe::set**=**step**=_n_
- **--step**=_n_

    ステップ数を _n_ にする。

- **-Mstripe::set**=**darkmode**
- **--darkmode**

    暗い背景色を使う。

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/darkmode.png">
            </p>
    </div>

    `--face`オプションを使用して、すべてのカラーマップの前景色を設定する。次のコマンドは描画色を白に設定し、行全体を背景色で塗りつぶす。

        greple -Mstripe --darkmode -- --face +WE

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/dark-white.png">
            </p>
    </div>

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
