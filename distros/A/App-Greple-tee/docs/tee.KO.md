# NAME

App::Greple::tee - 일치하는 텍스트를 외부 명령 결과로 대체하는 모듈

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple의 **-Mtee** 모듈은 지정된 필터 명령에 일치하는 텍스트 부분을 전송하고 명령 결과로 대체합니다. 이 아이디어는 **teip**이라는 명령에서 파생되었습니다. 일부 데이터를 외부 필터 명령으로 우회하는 것과 같습니다.

필터 명령은 모듈 선언(`-Mtee`)을 따르고 두 개의 대시(`--`)로 끝납니다. 예를 들어, 다음 명령은 데이터에서 일치하는 단어에 대한 `a-z A-Z` 인수를 사용하여 `tr` 명령을 호출합니다.

    greple -Mtee tr a-z A-Z -- '\w+' ...

위의 명령은 일치하는 모든 단어를 소문자에서 대문자로 변환합니다. 사실 이 예제 자체는 **--cm** 옵션을 사용하면 동일한 작업을 더 효과적으로 수행할 수 있기 때문에 그다지 유용하지 않습니다.

기본적으로 이 명령은 단일 프로세스로 실행되며 일치하는 모든 데이터가 혼합되어 전송됩니다. 일치하는 텍스트가 개행으로 끝나지 않으면 앞에 추가되고 뒤에 제거됩니다. 데이터는 한 줄씩 매핑되므로 입력 및 출력 데이터의 줄 수는 동일해야 합니다.

**-- 불연속** 옵션을 사용하면 일치하는 각 부분에 대해 개별 명령이 호출됩니다. 다음 명령을 통해 차이점을 확인할 수 있습니다.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**-- 불연속** 옵션과 함께 사용할 경우 입력 및 출력 데이터의 줄이 동일할 필요는 없습니다.

# VERSION

Version 0.9902

# OPTIONS

- **--discrete**

    일치하는 모든 부분에 대해 개별적으로 새 명령을 호출합니다.

- **--fillup**

    필터 명령에 전달하기 전에 빈 줄이 아닌 일련의 줄을 한 줄로 결합합니다. 넓은 문자 사이의 개행 문자는 삭제되고 다른 개행 문자는 공백으로 바뀝니다.

- **--blocks**

    일반적으로 지정된 검색 패턴과 일치하는 영역이 외부 명령으로 전송됩니다. 이 옵션을 지정하면 일치하는 영역이 아니라 해당 패턴이 포함된 전체 블록이 처리됩니다.

    예를 들어 `foo` 패턴이 포함된 줄을 외부 명령으로 보내려면 전체 줄에 일치하는 패턴을 지정해야 합니다:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    하지만 **--블록** 옵션을 사용하면 다음과 같이 간단하게 수행할 수 있습니다:

        greple -Mtee cat -n -- foo --blocks

    **--블록** 옵션을 사용하면 이 모듈은 [teip(1)](http://man.he.net/man1/teip)의 **-g** 옵션처럼 동작합니다. 그렇지 않으면 **-o** 옵션이 있는 [teip(1)](http://man.he.net/man1/teip)와 동작이 유사합니다.

    블록이 전체 데이터가 되므로 **--블록**을 **--all** 옵션과 함께 사용하지 마십시오.

- **--squeeze**

    두 개 이상의 연속된 개행 문자를 하나로 결합합니다.

# WHY DO NOT USE TEIP

우선, **teip** 명령으로 할 수 있을 때마다 이 명령을 사용하세요. 이 명령은 훌륭한 도구이며 **greple**보다 훨씬 빠릅니다.

**greple**은 문서 파일을 처리하도록 설계되었기 때문에 일치 영역 제어와 같이 이에 적합한 기능이 많이 있습니다. 이러한 기능을 활용하려면 **greple**을 사용하는 것이 좋습니다.

또한 **teip**은 여러 줄의 데이터를 단일 단위로 처리할 수 없는 반면, **greple**은 여러 줄로 구성된 데이터 청크에 대해 개별 명령을 실행할 수 있습니다.

# EXAMPLE

다음 명령은 Perl 모듈 파일에 포함된 [perlpod(1)](http://man.he.net/man1/perlpod) 스타일 문서 내에서 텍스트 블록을 찾습니다.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

DeepL 서비스에서 위 명령어를 **-Mtee** 모듈과 결합하여 실행하면 다음과 같이 **deepl** 명령어를 호출합니다:

    greple -Mtee deepl text --to JA - -- --fillup ...

하지만 이런 용도로는 전용 모듈인 [App::Greple::xlate::deep](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeep)을 사용하는 것이 더 효과적입니다. 사실 **tee** 모듈의 구현 힌트는 **xlate** 모듈에서 따온 것입니다.

# EXAMPLE 2

다음 명령은 라이선스 문서에서 들여쓰기된 부분을 찾습니다.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

이 부분은 **tee** 모듈을 **ansifold** 명령과 함께 사용하여 다시 포맷할 수 있습니다:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

`--불연속` 옵션을 사용하면 시간이 많이 걸립니다. 따라서 NL 대신 CR 문자를 사용하여 한 줄을 생성하는 `--별도 '\r'` 옵션을 `ansifold`와 함께 사용할 수 있습니다.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

그런 다음 [tr(1)](http://man.he.net/man1/tr) 명령 등으로 CR 문자를 NL로 변환합니다.

    ... | tr '\r' '\n'

# EXAMPLE 3

헤더가 아닌 줄에서 문자열을 찾으려는 상황을 생각해 봅시다. 예를 들어, 헤더 줄은 그대로 두고 `docker image ls` 명령에서 이미지를 검색하고 싶을 수 있습니다. 다음 명령을 사용하면 됩니다.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

옵션 `-Mline -L 2:`는 두 번째 줄부터 마지막 줄까지 검색하여 `grep perl` 명령으로 보냅니다. 옵션 `-- 불연속`이 필요하지만 이 옵션은 한 번만 호출되므로 성능 저하가 없습니다.

이 경우 출력의 줄 수가 입력보다 적기 때문에 `teip -l 2- -- grep`가 오류를 생성합니다. 하지만 결과는 꽤 만족스럽습니다.)

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# BUGS

`--fillup` 옵션은 한글 텍스트에 대해 제대로 작동하지 않을 수 있습니다.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
