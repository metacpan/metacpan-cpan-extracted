# NAME

App::Greple::stripe - Greple 斑马纹模块

# SYNOPSIS

    greple -Mstripe [ module options -- ] ...

# VERSION

Version 1.02

# DESCRIPTION

[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) 是 [greple](https://metacpan.org/pod/App%3A%3AGreple) 的一个模块，用于以斑马条纹方式显示匹配文本。

下面的命令匹配两个连续的行。

    greple -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/normal.png">
    </p>
</div>

但是，每个匹配的块都用相同的颜色着色，因此不清楚块在哪里断开。一种方法是使用 `-blockend` 选项显式显示这些块。

    greple -E '(.+\n){1,2}' --face +E --blockend=--

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/blockend.png">
    </p>
</div>

使用条纹模块，匹配相同图案的图块会用相似颜色系列的不同颜色着色。

    greple -Mstripe -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/stripe.png">
    </p>
</div>

默认情况下，会准备两个颜色系列。因此，在搜索多个图案时，偶数图案和奇数图案会被分配不同的颜色系列。

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
    </p>
</div>

如果像上例那样指定了多个模式，则只会输出与所有模式匹配的行。因此，需要使用 `--need=1` 选项来放宽这一条件。

如果要为三个或更多图案使用不同的颜色系列，请在调用模块时指定 `step` 数量。系列数最多可以增加到 6 个。

    greple -Mstripe::config=step=3 --need=1 -E p1 -E p2 -E p3 ...

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/step-3.png">
    </p>
</div>

# MODULE OPTIONS

**stripe** 模块有一些特定的选项。这些选项可以在模块声明时指定，也可以在模块声明后以 `--` 结尾作为选项指定。

以下三条命令具有完全相同的效果。

    greple -Mstripe::config=step=3

    greple -Mstripe --config step=3 --

    greple -Mstripe --step=3 --

请注意，此时可以使用 `set` 函数代替 `config`，以实现向后兼容。

- **-Mstripe::config**=**step**=_n_
- **--step**=_n_

    将步数设置为 _n_。

- **-Mstripe::config**=**darkmode**
- **--darkmode**

    使用深色背景

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/darkmode.png">
            </p>
    </div>

    使用 `-face` 选项为所有颜色映射设置前景色。以下命令将前景色设置为白色，并用背景色填充整行。

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
