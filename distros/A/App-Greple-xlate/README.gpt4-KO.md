# NAME

App::Greple::xlate - greple을 위한 번역 지원 모듈입니다.

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9914

# DESCRIPTION

**Greple** **xlate** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 교체합니다. 현재 DeepL(`deepl.pm`), ChatGPT 4.1(`gpt4.pm`), 그리고 GPT-5(`gpt5.pm`) 모듈이 백엔드 엔진으로 구현되어 있습니다.

Perl의 pod 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면, **greple** 명령어를 `xlate::deepl` 및 `perl` 모듈과 함께 다음과 같이 사용하세요:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

이 명령어에서 패턴 문자열 `^([\w\pP].*\n)+`은 영숫자 및 구두점 문자로 시작하는 연속된 줄을 의미합니다. 이 명령어는 번역할 영역을 하이라이트하여 보여줍니다. 옵션 **--all**는 전체 텍스트를 출력하는 데 사용됩니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

그런 다음 `--xlate` 옵션을 추가하여 선택된 영역을 번역하세요. 그러면 원하는 섹션을 찾아 **deepl** 명령어의 출력으로 교체합니다.

기본적으로 원본과 번역된 텍스트는 [git(1)](http://man.he.net/man1/git)와 호환되는 "충돌 마커" 형식으로 출력됩니다. `ifdef` 형식을 사용하면 [unifdef(1)](http://man.he.net/man1/unifdef) 명령어로 원하는 부분을 쉽게 얻을 수 있습니다. 출력 형식은 **--xlate-format** 옵션으로 지정할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

전체 텍스트를 번역하려면 **--match-all** 옵션을 사용하세요. 이는 전체 텍스트와 일치하는 패턴 `(?s).+`을 지정하는 단축키입니다.

충돌 마커 형식 데이터는 [sdif](https://metacpan.org/pod/App%3A%3Asdif) 명령어와 `-V` 옵션을 사용하여 나란히 보기 스타일로 확인할 수 있습니다. 문자열 단위로 비교하는 것은 의미가 없으므로 `--no-cdif` 옵션을 권장합니다. 텍스트에 색상을 입힐 필요가 없다면 `--no-textcolor` (또는 `--no-tc`)를 지정하세요.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

처리는 지정된 단위로 이루어지지만, 여러 줄의 비어 있지 않은 텍스트가 연속될 경우 하나의 줄로 합쳐서 변환됩니다. 이 작업은 다음과 같이 수행됩니다:

- 각 줄의 시작과 끝에 있는 공백을 제거합니다.
- 줄이 전각 구두점 문자로 끝나면 다음 줄과 연결합니다.
- 줄이 전각 문자로 끝나고 다음 줄이 전각 문자로 시작하면 줄을 연결합니다.
- 줄 끝이나 시작 중 하나라도 전각 문자가 아니면, 줄을 연결할 때 공백 문자를 삽입합니다.

캐시 데이터는 정규화된 텍스트를 기준으로 관리되므로, 정규화 결과에 영향을 주지 않는 수정이 이루어져도 캐시된 번역 데이터는 여전히 유효합니다.

이 정규화 과정은 첫 번째(0번째) 및 짝수 번째 패턴에만 수행됩니다. 따라서 다음과 같이 두 개의 패턴이 지정된 경우, 첫 번째 패턴에 일치하는 텍스트는 정규화 후 처리되고, 두 번째 패턴에 일치하는 텍스트에는 정규화 과정이 수행되지 않습니다.

    greple -Mxlate -E normalized -E not-normalized

따라서 여러 줄을 하나의 줄로 합쳐서 처리할 텍스트에는 첫 번째 패턴을 사용하고, 미리 서식이 지정된 텍스트에는 두 번째 패턴을 사용하세요. 첫 번째 패턴에 일치하는 텍스트가 없다면, `(?!)`과 같이 아무것도 일치하지 않는 패턴을 사용하세요.

# MASKING

가끔 번역을 원하지 않는 텍스트 부분이 있을 수 있습니다. 예를 들어, 마크다운 파일의 태그 등이 그렇습니다.

    --xlate-setopt maskfile=MASKPATTERN

DeepL은 이러한 경우, 번역에서 제외할 부분을 XML 태그로 변환한 후 번역하고, 번역이 완료된 후 복원할 것을 제안합니다.

이를 지원하기 위해, 번역에서 마스킹할 부분을 지정할 수 있습니다.

파일 \`MASKPATTERN\`의 각 줄을 정규 표현식으로 해석하여, 일치하는 문자열을 번역하고 처리 후 복원합니다.

**Greple**

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    **xlate**

    `deepl.pm`

    `gpt3.pm`

    **greple**

    `xlate::deepl`

- **--xlate-engine**=_engine_

    `perl`

    `^([\w\pP].*\n)+`

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **--all**

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    `--xlate`

- **--xlate-to** (Default: `EN-US`)

    **deepl**

- **--xlate-format**=_format_ (Default: `conflict`)

    [git(1)](http://man.he.net/man1/git)

    `ifdef`

    - **conflict**, **cm**

        [unifdef(1)](http://man.he.net/man1/unifdef)

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        **--xlate-format**

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        **--match-all**

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        `(?s).+`

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        `sdif`

    - **ifdef**

        `-V`

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        `--no-cdif`

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        원본 및 변환된 텍스트는 한 줄의 빈 줄로 구분되어 출력됩니다. `space+`의 경우, 변환된 텍스트 뒤에도 줄바꿈이 추가로 출력됩니다.

    - **xtxt**

        형식이 `xtxt` (번역된 텍스트)이거나 알 수 없는 경우, 번역된 텍스트만 출력됩니다.

- **--xlate-maxlen**=_chars_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 길이를 지정합니다. 기본값은 무료 DeepL 계정 서비스 기준으로 설정되어 있습니다: API는 128K(**--xlate**), 클립보드 인터페이스는 5000입니다(**--xlate-labor**). Pro 서비스를 사용하는 경우 이 값을 변경할 수 있습니다.

- **--xlate-maxline**=_n_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 줄 수를 지정합니다.

    한 번에 한 줄씩 번역하려면 이 값을 1로 설정하세요. 이 옵션은 `--xlate-maxlen` 옵션보다 우선 적용됩니다.

- **--xlate-prompt**=_text_

    번역 엔진에 전송할 사용자 지정 프롬프트를 지정합니다. 이 옵션은 ChatGPT 엔진(gpt3, gpt4, gpt4o)을 사용할 때만 사용할 수 있습니다. AI 모델에 특정 지침을 제공하여 번역 동작을 사용자 정의할 수 있습니다. 프롬프트에 `%s`이 포함되어 있으면 대상 언어 이름으로 대체됩니다.

- **--xlate-context**=_text_

    번역 엔진에 전송할 추가 컨텍스트 정보를 지정합니다. 이 옵션은 여러 번 사용할 수 있어 여러 개의 컨텍스트 문자열을 제공할 수 있습니다. 컨텍스트 정보는 번역 엔진이 배경을 이해하고 더 정확한 번역을 생성하는 데 도움이 됩니다.

- **--xlate-glossary**=_glossary_

    번역에 사용할 용어집 ID를 지정합니다. 이 옵션은 DeepL 엔진을 사용할 때만 사용할 수 있습니다. 용어집 ID는 DeepL 계정에서 얻어야 하며, 특정 용어의 일관된 번역을 보장합니다.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 출력에서 실시간으로 번역 결과를 확인할 수 있습니다.

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) 모듈을 사용하여 지브라 스트라이프 방식으로 일치하는 부분을 표시할 수 있습니다. 이는 일치하는 부분이 연속적으로 연결되어 있을 때 유용합니다.

    터미널의 배경색에 따라 색상 팔레트가 전환됩니다. 명시적으로 지정하려면 **--xlate-stripe-light** 또는 **--xlate-stripe-dark**를 사용할 수 있습니다.

- **--xlate-mask**

    마스킹 기능을 수행하고 복원 없이 변환된 텍스트를 그대로 표시합니다.

- **--match-all**

    파일의 전체 텍스트를 대상 영역으로 설정합니다.

- **--lineify-cm**
- **--lineify-colon**

    `cm` 및 `colon` 형식의 경우, 출력이 줄 단위로 분할되어 포맷됩니다. 따라서 한 줄의 일부만 번역할 경우, 기대한 결과를 얻을 수 없습니다. 이러한 필터는 한 줄의 일부만 번역되어 손상된 출력을 정상적인 줄 단위 출력으로 수정합니다.

    현재 구현에서는 한 줄의 여러 부분이 번역될 경우, 각각이 독립적인 줄로 출력됩니다.

# CACHE OPTIONS

**xlate** 모듈은 각 파일의 번역 캐시 텍스트를 저장하고 실행 전에 읽어와 서버에 요청하는 오버헤드를 줄일 수 있습니다. 기본 캐시 전략 `auto`에서는 대상 파일에 대한 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.

캐시 관리를 시작하거나 기존 모든 캐시 데이터를 정리하려면 **--xlate-cache=clear**를 사용하세요. 이 옵션으로 실행하면 캐시 파일이 없을 경우 새로 생성되고 이후 자동으로 관리됩니다.

- --xlate-cache=_strategy_
    - `auto` (Default)

        캐시 파일이 존재하면 유지합니다.

    - `create`

        빈 캐시 파일을 생성하고 종료합니다.

    - `always`, `yes`, `1`

        대상이 일반 파일인 한 캐시를 항상 유지합니다.

    - `clear`

        먼저 캐시 데이터를 삭제합니다.

    - `never`, `no`, `0`

        캐시 파일이 존재하더라도 절대 사용하지 않습니다.

    - `accumulate`

        기본 동작으로는 사용하지 않은 데이터가 캐시 파일에서 제거됩니다. 이를 제거하지 않고 파일에 유지하려면 `accumulate`을 사용하세요.
- **--xlate-update**

    필요하지 않더라도 캐시 파일을 강제로 업데이트합니다.

# COMMAND LINE INTERFACE

배포판에 포함된 `xlate` 명령을 사용하면 명령줄에서 이 모듈을 쉽게 사용할 수 있습니다. 사용법은 `xlate` 매뉴얼 페이지를 참조하세요.

`xlate` 명령은 Docker 환경과 연동되어, 별도의 설치가 없어도 Docker만 있으면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용하세요.

또한 다양한 문서 스타일용 메이크파일이 제공되므로, 특별한 지정 없이도 다른 언어로 번역이 가능합니다. `-M` 옵션을 사용하세요.

Docker와 `make` 옵션을 조합하여 Docker 환경에서 `make`를 실행할 수도 있습니다.

`xlate -C`와 같이 실행하면 현재 작업 중인 git 저장소가 마운트된 셸이 시작됩니다.

자세한 내용은 ["SEE ALSO"](#see-also) 섹션의 일본어 기사를 참조하세요.

# EMACS

저장소에 포함된 `xlate.el` 파일을 로드하여 Emacs 에디터에서 `xlate` 명령을 사용할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    `xlate-region` 함수는 지정된 영역을 번역합니다. 기본 언어는 `EN-US`이며, 접두사 인수를 사용하여 언어를 지정할 수 있습니다.

- OPENAI\_API\_KEY

    DeepL 서비스의 인증 키를 설정하세요.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

OpenAI 인증 키입니다.

DeepL과 ChatGPT용 커맨드라인 도구를 설치해야 합니다.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

# SEE ALSO

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    [App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    도커 컨테이너 이미지입니다.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    DeepL 파이썬 라이브러리와 CLI 명령어입니다.

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 파이썬 라이브러리입니다.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    OpenAI 커맨드라인 인터페이스입니다.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    대상 텍스트 패턴에 대한 자세한 내용은 **greple** 매뉴얼을 참조하세요. 일치 영역을 제한하려면 **--inside**, **--outside**, **--include**, **--exclude** 옵션을 사용하세요.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    `-Mupdate` 모듈을 사용하여 **greple** 명령의 결과로 파일을 수정할 수 있습니다.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    **sdif**을(를) 사용하여 **-V** 옵션과 함께 충돌 마커 형식을 나란히 표시할 수 있습니다.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple **stripe** 모듈은 **--xlate-stripe** 옵션으로 사용합니다.

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API를 사용하여 필요한 부분만 번역하고 교체하는 Greple 모듈 (일본어)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API 모듈로 15개 언어로 문서 생성 (일본어)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
