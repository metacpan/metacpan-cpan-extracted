# NAME

App::Greple::xlate - Greple용 번역 지원 모듈

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.31

# DESCRIPTION

**그림** **엑스레이트** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 대체합니다. 현재 DeepL (`deepl.pm`) 및 ChatGPT (`gpt3.pm`) 모듈이 백엔드 엔진으로 구현되어 있습니다. gpt-4에 대한 실험적 지원도 포함되어 있습니다.

Perl의 포드 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면 다음과 같이 **greple** 명령과 `xlate::deepl` 및 `perl` 모듈을 사용합니다:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

이 명령에서 패턴 문자열 `^(\w.*\n)+`는 영숫자로 시작하는 연속된 줄을 의미합니다. 이 명령은 번역할 영역을 강조 표시합니다. 옵션 **--all**은 전체 텍스트를 생성하는 데 사용됩니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

그런 다음 `--엑스레이트` 옵션을 추가하여 선택한 영역을 번역합니다. 그런 다음 원하는 섹션을 찾아 **딥** 명령 출력으로 대체합니다.

기본적으로 원본 및 번역된 텍스트는 [git(1)](http://man.he.net/man1/git)과 호환되는 "충돌 마커" 형식으로 인쇄됩니다. `ifdef` 형식을 사용하면 [unifdef(1)](http://man.he.net/man1/unifdef) 명령으로 원하는 부분을 쉽게 얻을 수 있습니다. 출력 형식은 **--xlate-format** 옵션으로 지정할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

전체 텍스트를 번역하려면 **--match-all** 옵션을 사용합니다. 이는 전체 텍스트와 일치하는 `(?s).+` 패턴을 지정하는 단축키입니다.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    일치하는 각 영역에 대해 번역 프로세스를 호출합니다.

    이 옵션이 없으면 **greple**은 일반 검색 명령처럼 작동합니다. 따라서 실제 작업을 호출하기 전에 파일에서 어느 부분이 번역 대상이 될지 확인할 수 있습니다.

    명령 결과는 표준 아웃으로 이동하므로 필요한 경우 파일로 리디렉션하거나 [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) 모듈을 사용하는 것을 고려할 수 있습니다.

    옵션 **--xlate**는 **--color=never** 옵션과 함께 **--xlate-color** 옵션을 호출합니다.

    **--xlate-fold** 옵션을 사용하면 변환된 텍스트가 지정된 너비만큼 접힙니다. 기본 너비는 70이며 **--xlate-fold-width** 옵션으로 설정할 수 있습니다. 실행 작업을 위해 4개의 열이 예약되어 있으므로 각 줄에는 최대 74자가 들어갈 수 있습니다.

- **--xlate-engine**=_engine_

    사용할 번역 엔진을 지정합니다. `-Mxlate::deep`과 같이 엔진 모듈을 직접 지정하는 경우에는 이 옵션을 사용할 필요가 없습니다.

- **--xlate-labor**
- **--xlabor**

    번역 엔진을 호출하는 대신 작업해야 합니다. 번역할 텍스트를 준비한 후 클립보드에 복사합니다. 양식에 붙여넣고 결과를 클립보드에 복사한 다음 Return 키를 누르면 됩니다.

- **--xlate-to** (Default: `EN-US`)

    대상 언어를 지정합니다. **DeepL** 엔진을 사용할 때 `deepl languages` 명령으로 사용 가능한 언어를 가져올 수 있습니다.

- **--xlate-format**=_format_ (Default: `conflict`)

    원본 및 번역 텍스트의 출력 형식을 지정합니다.

    - **conflict**, **cm**

        원본 텍스트와 변환된 텍스트는 [git(1)](http://man.he.net/man1/git) 충돌 마커 형식으로 인쇄됩니다.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        다음 [sed(1)](http://man.he.net/man1/sed) 명령으로 원본 파일을 복구할 수 있습니다.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        원본 텍스트와 변환된 텍스트는 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 형식으로 인쇄됩니다.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        일본어 텍스트만 검색하려면 **unifdef** 명령으로 검색할 수 있습니다:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        원본 텍스트와 변환된 텍스트는 하나의 빈 줄로 구분하여 인쇄됩니다.

    - **xtxt**

        형식이 `xtxt`(번역된 텍스트) 또는 알 수 없는 경우 번역된 텍스트만 인쇄됩니다.

- **--xlate-maxlen**=_chars_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 길이를 지정합니다. 기본값은 무료 DeepL 계정 서비스의 경우 API의 경우 128K(**--xlate**), 클립보드 인터페이스의 경우 5000(**--xlate-labor**)으로 설정되어 있습니다. Pro 서비스를 사용하는 경우 이 값을 변경할 수 있습니다.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    번역 결과는 STDERR 출력에서 실시간으로 확인할 수 있습니다.

- **--match-all**

    파일의 전체 텍스트를 대상 영역으로 설정합니다.

# CACHE OPTIONS

**엑스레이트** 모듈은 각 파일에 대한 번역 텍스트를 캐시하여 저장하고 실행 전에 읽어들여 서버에 요청하는 오버헤드를 없앨 수 있습니다. 기본 캐시 전략 `auto`를 사용하면 대상 파일에 대한 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.

- --cache-clear

    **--cache-clear** 옵션은 캐시 관리를 시작하거나 기존의 모든 캐시 데이터를 새로 고치는 데 사용할 수 있습니다. 이 옵션을 실행하면 캐시 파일이 없는 경우 새 캐시 파일이 생성되고 이후에는 자동으로 유지 관리됩니다.

- --xlate-cache=_strategy_
    - `auto` (Default)

        캐시 파일이 있는 경우 캐시 파일을 유지 관리합니다.

    - `create`

        빈 캐시 파일을 생성하고 종료합니다.

    - `always`, `yes`, `1`

        타겟이 정상 파일인 한 캐시를 유지합니다.

    - `clear`

        캐시 데이터를 먼저 지웁니다.

    - `never`, `no`, `0`

        캐시 파일이 존재하더라도 절대 사용하지 않습니다.

    - `accumulate`

        기본 동작에 따라 사용하지 않는 데이터는 캐시 파일에서 제거됩니다. 제거하지 않고 파일에 유지하려면 `accumulate`를 사용하세요.

# COMMAND LINE INTERFACE

이 모듈은 배포에 포함된 `xlate` 명령을 사용하여 명령줄에서 쉽게 사용할 수 있습니다. 사용법은 `xlate` 도움말 정보를 참조하세요.

`xlate` 명령은 Docker 환경과 함께 작동하므로 아무것도 설치되어 있지 않더라도 Docker를 사용할 수 있으면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용합니다.

또한 다양한 문서 스타일에 대한 메이크파일이 제공되므로 특별한 지정 없이 다른 언어로 번역이 가능합니다. `-M` 옵션을 사용합니다.

Docker 환경에서도 make를 실행할 수 있도록 Docker와 make 옵션을 결합할 수도 있습니다.

`xlate -GC`처럼 실행하면 현재 작업 중인 git 리포지토리가 마운트된 셸이 실행됩니다.

자세한 내용은 ["또는 참조"](#또는-참조) 섹션의 일본어 기사를 참조하세요.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
        -w # wrap line by # width
        -o # output format (default "xtxt", or "cm", "ifdef")
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
        -M   run make
        -n   dry-run
    Docker options
        -G   mount git top-level directory
        -B   run in non-interactive (batch) mode
        -R   mount read-only
        -E * specify environment variable to be inherited
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

저장소에 포함된 `xlate.el` 파일을 로드하여 Emacs 편집기에서 `xlate` 명령을 사용합니다. `xlate-region` 함수는 지정된 지역을 번역합니다. 기본 언어는 `EN-US`이며 접두사 인수를 사용하여 호출하는 언어를 지정할 수 있습니다.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL 서비스에 대한 인증 키를 설정합니다.

- OPENAI\_API\_KEY

    OpenAI 인증 키.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL 및 ChatGPT용 명령줄 도구를 설치해야 합니다.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL 파이썬 라이브러리 및 CLI 명령.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI 파이썬 라이브러리

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 명령줄 인터페이스

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    대상 텍스트 패턴에 대한 자세한 내용은 **greple** 매뉴얼을 참조하세요. **--내부**, **--외부**, **--포함**, **--제외** 옵션을 사용하여 일치하는 영역을 제한할 수 있습니다.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate` 모듈을 사용하여 **greple** 명령의 결과에 따라 파일을 수정할 수 있습니다.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    충돌 마커 형식을 **-V** 옵션과 함께 나란히 표시하려면 **에스디프**를 사용합니다.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    필요한 부분만 번역하고 DeepL API(일본어)로 대체하는 Greple 모듈 (일본어)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API 모듈로 15개 언어로 문서 생성 (일본어)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API를 사용한 자동 번역 도커 환경 (일본어)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
