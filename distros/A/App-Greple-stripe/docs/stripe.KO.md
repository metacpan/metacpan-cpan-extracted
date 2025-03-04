# NAME

App::Greple::stripe - Greple 지브라 스트라이프 모듈

# SYNOPSIS

    greple -Mstripe [ module options -- ] ...

# VERSION

Version 1.01

# DESCRIPTION

[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)는 일치하는 텍스트를 지브라 스트라이프 방식으로 표시하는 [greple](https://metacpan.org/pod/App%3A%3AGreple)용 모듈입니다.

다음 명령은 연속된 두 줄을 일치시킵니다.

    greple -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/normal.png">
    </p>
</div>

그러나 일치하는 각 블록은 동일한 색상으로 표시되므로 블록이 끊어지는 위치가 명확하지 않습니다. 한 가지 방법은 `--blockend` 옵션을 사용하여 블록을 명시적으로 표시하는 것입니다.

    greple -E '(.+\n){1,2}' --face +E --blockend=--

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/blockend.png">
    </p>
</div>

스트라이프 모듈을 사용하면 동일한 패턴과 일치하는 블록이 비슷한 색상 계열의 다른 색상으로 표시됩니다.

    greple -Mstripe -E '(.+\n){1,2}' --face +E

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/stripe.png">
    </p>
</div>

기본적으로 두 가지 색상 계열이 준비되어 있습니다. 따라서 여러 패턴을 검색할 때 짝수 패턴과 홀수 패턴에는 서로 다른 색상 계열이 할당됩니다.

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
    </p>
</div>

위의 예와 같이 여러 패턴을 지정하면 모든 패턴과 일치하는 줄만 출력됩니다. 따라서 이 조건을 완화하려면 `--need=1` 옵션이 필요합니다.

세 개 이상의 패턴에 서로 다른 색상 계열을 사용하려면 모듈을 호출할 때 `단계` 개수를 지정하세요. 계열 수는 최대 6까지 늘릴 수 있습니다.

    greple -Mstripe::config=step=3 --need=1 -E p1 -E p2 -E p3 ...

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/step-3.png">
    </p>
</div>

# MODULE OPTIONS

**스트라이프** 모듈에 특정한 옵션이 있습니다. 모듈을 선언할 때 지정하거나 모듈 선언 뒤에 `--`로 끝나는 옵션으로 지정할 수 있습니다.

다음 두 명령은 정확히 같은 효과를 냅니다.

    greple -Mstripe=config=step=3

    greple -Mstripe --step=3 --

- **-Mstripe::config**=**step**=_n_
- **--step**=_n_

    걸음 수를 _n_으로 설정합니다.

- **-Mstripe::config**=**darkmode**
- **--darkmode**

    어두운 배경색을 사용합니다.

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/darkmode.png">
            </p>
    </div>

    모든 컬러맵의 전경색을 설정하려면 `--face` 옵션을 사용합니다. 다음 명령은 전경색을 흰색으로 설정하고 전체 줄을 배경색으로 채웁니다.

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

Copyright ©︎ 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
