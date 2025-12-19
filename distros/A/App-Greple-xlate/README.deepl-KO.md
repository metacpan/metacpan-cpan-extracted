# NAME

App::Greple::xlate - Greple용 번역 지원 모듈

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9923

# DESCRIPTION

**Greple** **xlate** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 대체합니다. 현재 DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`) 및 GPT-5 (`gpt5.pm`) 모듈이 백엔드 엔진으로 구현되어 있습니다.

Perl의 포드 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면 다음과 같이 **greple** 명령과 `xlate::deepl` 및 `perl` 모듈을 사용합니다:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

이 명령에서 패턴 문자열 `^([\w\pP].*\n)+`은 영숫자 및 구두점으로 시작하는 연속된 줄을 의미합니다. 이 명령은 번역할 영역을 강조 표시합니다. 옵션 **--all**은 전체 텍스트를 생성하는 데 사용됩니다.

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

충돌 마커 형식 데이터는 [sdif](https://metacpan.org/pod/App%3A%3Asdif) 명령과 `-V` 옵션을 사용하여 나란히 나란히 볼 수 있습니다. 문자열 단위로 비교하는 것은 의미가 없으므로 `--no-cdif` 옵션을 사용하는 것이 좋습니다. 텍스트에 색상을 지정할 필요가 없는 경우 `--no-textcolor`(또는 `--no-tc`)를 지정합니다.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

처리는 지정된 단위로 수행되지만 비어 있지 않은 여러 줄의 텍스트 시퀀스의 경우 한 줄로 함께 변환됩니다. 이 작업은 다음과 같이 수행됩니다:

- 각 줄의 시작과 끝에서 공백을 제거합니다.
- 한 줄이 전폭 구두점 문자로 끝나면 다음 줄로 연결합니다.
- 한 줄이 전폭 문자로 끝나고 다음 줄이 전폭 문자로 시작되는 경우 두 줄을 연결합니다.
- 한 줄의 끝이나 시작이 전폭 문자가 아닌 경우 공백 문자를 삽입하여 연결합니다.

캐시 데이터는 정규화된 텍스트를 기반으로 관리되므로 정규화 결과에 영향을 미치지 않는 수정이 이루어지더라도 캐시된 번역 데이터는 여전히 유효합니다.

이 정규화 프로세스는 첫 번째(0번째) 및 짝수 패턴에 대해서만 수행됩니다. 따라서 다음과 같이 두 개의 패턴을 지정하면 첫 번째 패턴과 일치하는 텍스트는 정규화 후 처리되고 두 번째 패턴과 일치하는 텍스트에는 정규화 프로세스가 수행되지 않습니다.

    greple -Mxlate -E normalized -E not-normalized

따라서 여러 줄을 한 줄로 결합하여 처리할 텍스트에는 첫 번째 패턴을 사용하고, 미리 서식이 지정된 텍스트에는 두 번째 패턴을 사용합니다. 첫 번째 패턴에 일치할 텍스트가 없는 경우 `(?!)`과 같이 아무것도 일치하지 않는 패턴을 사용합니다.

# MASKING

간혹 번역하고 싶지 않은 텍스트 부분이 있을 수 있습니다. 예를 들어 마크다운 파일의 태그가 있습니다. DeepL 에서는 이러한 경우 제외할 텍스트 부분을 XML 태그로 변환하여 번역한 다음 번역이 완료된 후 복원할 것을 제안합니다. 이를 지원하기 위해 번역에서 마스킹할 부분을 지정할 수 있습니다.

    --xlate-setopt maskfile=MASKPATTERN

이렇게 하면 파일 \`MASKPATTERN\`의 각 줄을 정규식으로 해석하여 일치하는 문자열을 번역하고 처리 후 되돌려 놓습니다. `#`로 시작하는 줄은 무시됩니다.

복잡한 패턴은 백슬래시 에스파스 새줄을 사용하여 여러 줄에 작성할 수 있습니다.

마스킹을 통해 텍스트가 어떻게 변환되는지는 **--xlate-mask** 옵션에서 확인할 수 있습니다.

이 인터페이스는 실험적이며 향후 변경될 수 있습니다.

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

    현재 사용 가능한 엔진은 다음과 같습니다.

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**의 인터페이스는 불안정하며 현재로서는 제대로 작동한다고 보장할 수 없습니다.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    번역 엔진을 호출하는 대신 작업해야 합니다. 번역할 텍스트를 준비한 후 클립보드에 복사합니다. 양식에 붙여넣고 결과를 클립보드에 복사한 다음 Return 키를 누르면 됩니다.

- **--xlate-to** (Default: `EN-US`)

    대상 언어를 지정합니다. **DeepL** 엔진을 사용할 때 `deepl languages` 명령으로 사용 가능한 언어를 가져올 수 있습니다.

- **--xlate-format**=_format_ (Default: `conflict`)

    원본 및 번역 텍스트의 출력 형식을 지정합니다.

    `xtxt` 이외의 다음 형식은 번역할 부분이 줄의 모음이라고 가정합니다. 실제로는 한 줄의 일부만 번역할 수 있지만 `xtxt` 이외의 형식을 지정하면 의미 있는 결과가 나오지 않습니다.

    - **conflict**, **cm**

        원본 텍스트와 변환된 텍스트는 [git(1)](http://man.he.net/man1/git) 충돌 마커 형식으로 인쇄됩니다.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        다음 [sed(1)](http://man.he.net/man1/sed) 명령으로 원본 파일을 복구할 수 있습니다.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        원본 텍스트와 번역된 텍스트는 마크다운의 사용자 정의 컨테이너 스타일로 출력됩니다.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        위의 텍스트는 HTML에서 다음과 같이 번역됩니다.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        콜론 개수는 기본적으로 7입니다. `:::::`와 같이 콜론 순서를 지정하면 콜론 7개 대신 사용됩니다.

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
    - **space+**

        원본 텍스트와 변환된 텍스트는 하나의 빈 줄로 구분하여 인쇄됩니다. `스페이스+`의 경우 변환된 텍스트 뒤에 줄 바꿈도 출력합니다.

    - **xtxt**

        형식이 `xtxt`(번역된 텍스트) 또는 알 수 없는 경우 번역된 텍스트만 인쇄됩니다.

- **--xlate-maxlen**=_chars_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 길이를 지정합니다. 기본값은 무료 DeepL 계정 서비스의 경우 API의 경우 128K(**--xlate**), 클립보드 인터페이스의 경우 5000(**--xlate-labor**)으로 설정되어 있습니다. Pro 서비스를 사용하는 경우 이 값을 변경할 수 있습니다.

- **--xlate-maxline**=_n_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 줄 수를 지정합니다.

    한 번에 한 줄씩 번역하려면 이 값을 1로 설정합니다. 이 옵션은 `--xlate-maxlen` 옵션보다 우선합니다.

- **--xlate-prompt**=_text_

    번역 엔진에 전송할 사용자 지정 프롬프트를 지정합니다. 이 옵션은 ChatGPT 엔진(gpt3, gpt4, gpt4o)을 사용할 때만 사용할 수 있습니다. AI 모델에 특정 지침을 제공하여 번역 동작을 사용자 지정할 수 있습니다. 프롬프트에 `%s`이 포함되어 있으면 대상 언어 이름으로 대체됩니다.

- **--xlate-context**=_text_

    번역 엔진에 전송할 추가 컨텍스트 정보를 지정합니다. 이 옵션을 여러 번 사용하여 여러 개의 컨텍스트 문자열을 제공할 수 있습니다. 컨텍스트 정보는 번역 엔진이 배경을 이해하고 보다 정확한 번역을 생성하는 데 도움이 됩니다.

- **--xlate-glossary**=_glossary_

    번역에 사용할 용어집 ID를 지정합니다. 이 옵션은 DeepL 엔진을 사용할 때만 사용할 수 있습니다. 용어집 ID는 DeepL 계정에서 가져와야 하며 특정 용어의 일관된 번역을 보장합니다.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    번역 결과는 STDERR 출력에서 실시간으로 확인할 수 있습니다.

- **--xlate-stripe**

    일치하는 부분을 지브라 스트라이프 방식으로 표시하려면 [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) 모듈을 사용합니다. 이 옵션은 일치하는 부분이 연속적으로 연결될 때 유용합니다.

    색상 팔레트는 단말기의 배경색에 따라 전환됩니다. 명시적으로 지정하고 싶으면 **--지연 스트라이프-밝음** 또는 **--지연 스트라이프-어두움**을 사용할 수 있습니다.

- **--xlate-mask**

    마스킹 기능을 수행하여 변환된 텍스트를 복원하지 않고 그대로 표시합니다.

- **--match-all**

    파일의 전체 텍스트를 대상 영역으로 설정합니다.

- **--lineify-cm**
- **--lineify-colon**

    `cm` 및 `colon` 형식의 경우 출력이 한 줄씩 분할되어 형식이 지정됩니다. 따라서 한 줄의 일부만 번역해야 하는 경우 예상되는 결과를 얻을 수 없습니다. 이 필터는 한 줄의 일부를 정상적인 줄 단위 출력으로 번역하여 손상된 출력을 수정합니다.

    현재 구현에서는 한 줄의 여러 부분이 번역되는 경우 독립된 줄로 출력됩니다.

# CACHE OPTIONS

**엑스레이트** 모듈은 각 파일에 대한 번역 텍스트를 캐시하여 저장하고 실행 전에 읽어들여 서버에 요청하는 오버헤드를 없앨 수 있습니다. 기본 캐시 전략 `auto`를 사용하면 대상 파일에 대한 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.

캐시 관리를 시작하거나 기존의 모든 캐시 데이터를 정리하려면 **--xlate-cache=clear**를 사용합니다. 이 옵션을 실행하면 캐시 파일이 없는 경우 새 캐시 파일이 생성되고 이후 자동으로 유지 관리됩니다.

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
- **--xlate-update**

    이 옵션은 필요하지 않은 경우에도 캐시 파일을 강제로 업데이트합니다.

# COMMAND LINE INTERFACE

이 모듈은 배포에 포함된 `xlate` 명령을 사용하여 명령줄에서 쉽게 사용할 수 있습니다. 사용법은 `xlate` 매뉴얼 페이지를 참조하세요.

`xlate` 명령은 `--to-lang`, `--from-lang`, `--engine` 및 `--file`와 같은 GNU 스타일의 긴 옵션을 지원합니다. 사용 가능한 모든 옵션을 보려면 `xlate -h`을 사용하세요.

`xlate` 명령은 Docker 환경과 함께 작동하므로 아무것도 설치되어 있지 않더라도 Docker를 사용할 수 있으면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용합니다.

Docker 작업은 [App::dozo](https://metacpan.org/pod/App%3A%3Adozo)으로 처리되며, 독립 실행형 명령으로도 사용할 수 있습니다. `dozo` 명령은 영구 컨테이너 설정을 위한 `.dozorc` 구성 파일을 지원합니다.

또한 다양한 문서 스타일에 대한 메이크파일이 제공되므로 특별한 지정 없이 다른 언어로 번역이 가능합니다. `-M` 옵션을 사용합니다.

Docker와 `make` 옵션을 결합하여 `make`를 Docker 환경에서 실행할 수도 있습니다.

`xlate -C`처럼 실행하면 현재 작업 중인 git 리포지토리가 마운트된 셸이 시작됩니다.

자세한 내용은 ["또는 참조"](#또는-참조) 섹션의 일본어 기사를 참조하세요.

# EMACS

저장소에 포함된 `xlate.el` 파일을 로드하여 Emacs 편집기에서 `xlate` 명령을 사용합니다. `xlate-region` 함수는 지정된 지역을 번역합니다. 기본 언어는 `EN-US`이며 접두사 인수를 사용하여 호출하는 언어를 지정할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

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

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlate에서 컨테이너 작업에 사용하는 일반 Docker 러너입니다.

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    도커 컨테이너 이미지.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` - `xlate` 스크립트 및 [App::dozo](https://metacpan.org/pod/App%3A%3Adozo)에서 옵션 구문 분석에 사용되는 &lt;m id=5 /> 라이브러리.

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

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    회색 **줄무늬** 모듈은 **--xlate-stripe** 옵션으로 사용합니다.

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
