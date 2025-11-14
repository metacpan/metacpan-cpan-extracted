# NAME

App::Greple::xlate - greple용 번역 지원 모듈

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9915

# DESCRIPTION

**Greple** **xlate** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 대체합니다. 현재 DeepL (`deepl.pm`), ChatGPT 4.1 (`gpt4.pm`), 그리고 GPT-5 (`gpt5.pm`) 모듈이 백엔드 엔진으로 구현되어 있습니다.

Perl의 POD 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면, 다음과 같이 **greple** 명령을 `xlate::deepl` 및 `perl` 모듈과 함께 사용하세요:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

이 명령에서 패턴 문자열 `^([\w\pP].*\n)+` 은 영숫자 및 구두점 문자로 시작하는 연속된 줄을 의미합니다. 이 명령은 번역할 영역을 하이라이트하여 표시합니다. 옵션 **--all** 는 전체 텍스트를 생성하는 데 사용됩니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

그런 다음 선택된 영역을 번역하려면 `--xlate` 옵션을 추가하세요. 그러면 원하는 섹션을 찾아 **deepl** 명령 출력으로 교체합니다.

기본적으로 원문과 번역문은 [git(1)](http://man.he.net/man1/git) 와(과) 호환되는 "충돌 마커" 형식으로 출력됩니다. `ifdef` 형식을 사용하면 [unifdef(1)](http://man.he.net/man1/unifdef) 명령으로 원하는 부분을 쉽게 얻을 수 있습니다. 출력 형식은 **--xlate-format** 옵션으로 지정할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

전체 텍스트를 번역하려면 **--match-all** 옵션을 사용하세요. 이는 전체 텍스트에 매칭되는 패턴 `(?s).+` 을 지정하는 단축 방법입니다.

충돌 마커 형식 데이터는 `-V` 옵션과 함께 [sdif](https://metacpan.org/pod/App%3A%3Asdif) 명령으로 좌우 나란히 보기 스타일로 볼 수 있습니다. 문자열 단위 비교는 의미가 없으므로 `--no-cdif` 옵션을 권장합니다. 텍스트에 색상을 입힐 필요가 없으면 `--no-textcolor`(또는 `--no-tc`)를 지정하세요.

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

처리는 지정된 단위로 수행되지만, 비어 있지 않은 여러 줄이 연속된 경우 하나의 줄로 함께 변환됩니다. 이 작업은 다음과 같이 수행됩니다:

- 각 줄의 시작과 끝의 공백을 제거합니다.
- 줄이 전각 구두문자로 끝나면 다음 줄과 이어 붙입니다.
- 줄이 전각 문자로 끝나고 다음 줄이 전각 문자로 시작하면 줄을 연결합니다.
- 줄의 끝 또는 시작 중 어느 한쪽이라도 전각 문자가 아니면, 공백 문자를 삽입하여 연결합니다.

캐시 데이터는 정규화된 텍스트를 기준으로 관리되므로, 정규화 결과에 영향을 주지 않는 수정이 이루어져도 캐시된 번역 데이터는 계속 유효합니다.

이 정규화 과정은 첫 번째(0번째) 및 짝수 번째 패턴에만 수행됩니다. 따라서 다음과 같이 두 개의 패턴이 지정된 경우, 첫 번째 패턴에 일치하는 텍스트는 정규화 후에 처리되며, 두 번째 패턴에 일치하는 텍스트에는 정규화가 수행되지 않습니다.

    greple -Mxlate -E normalized -E not-normalized

따라서 여러 줄을 하나의 줄로 결합하여 처리할 텍스트에는 첫 번째 패턴을 사용하고, 사전 서식화된 텍스트에는 두 번째 패턴을 사용하세요. 첫 번째 패턴에 일치하는 텍스트가 없다면 `(?!)` 와 같은 아무것도 일치하지 않는 패턴을 사용하세요.

# MASKING

가끔 번역하고 싶지 않은 텍스트 부분이 있습니다. 예를 들어, 마크다운 파일의 태그가 그렇습니다. DeepL은 이러한 경우 제외할 텍스트를 XML 태그로 변환하여 번역하고, 번역이 완료된 후 원래대로 복원할 것을 제안합니다. 이를 지원하기 위해, 번역에서 마스킹할 부분을 지정할 수 있습니다.

    --xlate-setopt maskfile=MASKPATTERN

파일 \`MASKPATTERN\`의 각 줄을 정규식으로 해석하여 이에 매칭되는 문자열을 변환한 뒤, 처리 후 되돌립니다. `#` 로 시작하는 줄은 무시됩니다.

복잡한 패턴은 백슬래시로 개행을 이스케이프하여 여러 줄에 걸쳐 작성할 수 있습니다.

마스킹에 의해 텍스트가 어떻게 변환되는지는 **--xlate-mask** 옵션으로 확인할 수 있습니다.

이 인터페이스는 실험적이며 향후 변경될 수 있습니다.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    일치한 각 영역에 대해 번역 프로세스를 호출합니다.

    이 옵션이 없으면 **greple** 는 일반 검색 명령처럼 동작합니다. 따라서 실제 작업을 수행하기 전에 파일의 어느 부분이 번역 대상이 될지 확인할 수 있습니다.

    명령 결과는 표준 출력으로 나가므로 필요하면 파일로 리디렉션하거나, [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) 모듈 사용을 고려하십시오.

    옵션 **--xlate** 는 **--color=never** 옵션과 함께 **--xlate-color** 옵션을 호출합니다.

    **--xlate-fold** 옵션을 사용하면 변환된 텍스트가 지정한 폭으로 접힙니다. 기본 폭은 70이며 **--xlate-fold-width** 옵션으로 설정할 수 있습니다. 들여쓰기 작업을 위해 네 칸이 예약되므로 각 줄은 최대 74자를 담을 수 있습니다.

- **--xlate-engine**=_engine_

    사용할 번역 엔진을 지정합니다. `-Mxlate::deepl` 처럼 엔진 모듈을 직접 지정하면 이 옵션을 사용할 필요가 없습니다.

    현재 다음 엔진들이 사용 가능합니다

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** 의 인터페이스는 불안정하며 현재 올바르게 동작함을 보장할 수 없습니다.

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    번역 엔진을 호출하는 대신 사용자가 수동으로 작업하는 방식을 기대합니다. 번역할 텍스트를 준비한 뒤 클립보드로 복사합니다. 양식에 붙여넣고, 결과를 클립보드로 복사한 다음, 리턴 키를 누르십시오.

- **--xlate-to** (Default: `EN-US`)

    대상 언어를 지정합니다. **DeepL** 엔진을 사용할 때는 `deepl languages` 명령으로 사용 가능한 언어를 얻을 수 있습니다.

- **--xlate-format**=_format_ (Default: `conflict`)

    원문과 번역문에 대한 출력 형식을 지정합니다.

    `xtxt` 이 아닌 다음 형식들은 번역 대상 부분이 여러 줄의 집합이라고 가정합니다. 실제로는 한 줄의 일부만 번역하는 것도 가능하지만, `xtxt` 이외의 형식을 지정하면 의미 있는 결과가 나오지 않습니다.

    - **conflict**, **cm**

        원문과 변환된 텍스트는 [git(1)](http://man.he.net/man1/git) 충돌 마커 형식으로 출력됩니다.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        다음 [sed(1)](http://man.he.net/man1/sed) 명령으로 원본 파일을 복구할 수 있습니다.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        원문과 번역문은 마크다운의 커스텀 컨테이너 스타일로 출력됩니다.

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

        콜론의 개수는 기본적으로 7개입니다. `:::::` 처럼 콜론 시퀀스를 지정하면 7개 대신 그것이 사용됩니다.

    - **ifdef**

        원문과 변환된 텍스트는 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 형식으로 출력됩니다.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** 명령으로 일본어 텍스트만 추출할 수 있습니다:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        원문과 변환된 텍스트는 한 개의 빈 줄로 구분되어 출력됩니다. `space+`의 경우, 변환된 텍스트 뒤에 개행도 출력합니다.

    - **xtxt**

        형식이 `xtxt`(번역된 텍스트) 또는 알 수 없는 경우, 번역된 텍스트만 출력됩니다.

- **--xlate-maxlen**=_chars_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 길이를 지정합니다. 기본값은 무료 DeepL 계정 서비스 기준으로 설정되어 있습니다: API의 경우(**--xlate**) 128K, 클립보드 인터페이스(**--xlate-labor**)의 경우 5000입니다. Pro 서비스를 사용 중이라면 이 값을 변경할 수 있습니다.

- **--xlate-maxline**=_n_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 줄 수를 지정합니다.

    한 줄씩 번역하려면 이 값을 1로 설정하십시오. 이 옵션은 `--xlate-maxlen` 옵션보다 우선합니다.

- **--xlate-prompt**=_text_

    번역 엔진으로 전송할 사용자 정의 프롬프트를 지정합니다. 이 옵션은 ChatGPT 엔진(gpt3, gpt4, gpt4o) 사용 시에만 사용할 수 있습니다. AI 모델에 구체적인 지시를 제공하여 번역 동작을 사용자 정의할 수 있습니다. 프롬프트에 `%s`가 포함되어 있으면 대상 언어 이름으로 대체됩니다.

- **--xlate-context**=_text_

    번역 엔진으로 전송할 추가 컨텍스트 정보를 지정합니다. 이 옵션은 여러 번 사용하여 여러 컨텍스트 문자열을 제공할 수 있습니다. 컨텍스트 정보는 번역 엔진이 배경을 이해하고 더 정확한 번역을 생성하는 데 도움이 됩니다.

- **--xlate-glossary**=_glossary_

    번역에 사용할 용어집 ID를 지정합니다. 이 옵션은 DeepL 엔진을 사용할 때만 제공됩니다. 용어집 ID는 DeepL 계정에서 얻어야 하며 특정 용어의 일관된 번역을 보장합니다.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 출력에서 번역 결과를 실시간으로 확인합니다.

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) 모듈을 사용하여 매칭된 부분을 얼룩말 줄무늬 방식으로 표시합니다. 매칭된 부분이 연속해서 이어질 때 유용합니다.

    터미널의 배경색에 따라 색상 팔레트가 전환됩니다. 명시적으로 지정하려면 **--xlate-stripe-light** 또는 **--xlate-stripe-dark**를 사용할 수 있습니다.

- **--xlate-mask**

    마스킹 기능을 수행하고 복원 없이 변환된 텍스트를 있는 그대로 표시합니다.

- **--match-all**

    파일의 전체 텍스트를 대상 영역으로 설정합니다.

- **--lineify-cm**
- **--lineify-colon**

    `cm` 및 `colon` 형식의 경우 출력이 줄 단위로 분할되어 포맷됩니다. 따라서 한 줄의 일부만 번역할 경우 기대한 결과를 얻을 수 없습니다. 이 필터들은 한 줄의 일부를 번역하여 출력이 손상된 경우 정상적인 줄 단위 출력으로 수정합니다.

    현재 구현에서는 한 줄의 여러 부분이 번역되면 각각 독립된 줄로 출력됩니다.

# CACHE OPTIONS

**xlate** 모듈은 파일별 번역 텍스트를 캐시로 저장하고 실행 전에 읽어 서버 요청 오버헤드를 제거할 수 있습니다. 기본 캐시 전략 `auto`에서는 대상 파일에 캐시 파일이 존재할 때만 캐시 데이터를 유지합니다.

**--xlate-cache=clear**를 사용하여 캐시 관리를 시작하거나 기존의 모든 캐시 데이터를 정리하십시오. 이 옵션으로 한 번 실행되면 캐시 파일이 없을 경우 새 캐시 파일이 생성되고 이후 자동으로 유지됩니다.

- --xlate-cache=_strategy_
    - `auto` (Default)

        캐시 파일이 존재하면 유지합니다.

    - `create`

        빈 캐시 파일을 생성하고 종료합니다.

    - `always`, `yes`, `1`

        대상이 일반 파일인 한 캐시를 유지합니다.

    - `clear`

        먼저 캐시 데이터를 지웁니다.

    - `never`, `no`, `0`

        존재하더라도 캐시 파일을 절대 사용하지 않습니다.

    - `accumulate`

        기본 동작으로 사용되지 않은 데이터는 캐시 파일에서 제거됩니다. 제거하지 않고 파일에 유지하려면 `accumulate`를 사용하십시오.
- **--xlate-update**

    이 옵션은 필요하지 않더라도 캐시 파일의 업데이트를 강제합니다.

# COMMAND LINE INTERFACE

배포본에 포함된 `xlate` 명령을 사용하면 명령줄에서 이 모듈을 손쉽게 사용할 수 있습니다. 사용법은 `xlate` 매뉴얼 페이지를 참조하십시오.

`xlate` 명령은 Docker 환경과 연동되므로, 로컬에 아무것도 설치되어 있지 않아도 Docker만 사용할 수 있다면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용하십시오.

또한 다양한 문서 스타일용 메이크파일이 제공되므로, 특별한 지정 없이도 다른 언어로 번역이 가능합니다. `-M` 옵션을 사용하십시오.

Docker와 `make` 옵션을 조합하여 Docker 환경에서 `make`를 실행할 수도 있습니다.

`xlate -C`처럼 실행하면 현재 작업 중인 git 저장소가 마운트된 셸이 실행됩니다.

자세한 내용은 ["SEE ALSO"](#see-also) 절의 일본어 글을 읽어보세요.

# EMACS

저장소에 포함된 `xlate.el` 파일을 로드하여 Emacs 편집기에서 `xlate` 명령을 사용하십시오. `xlate-region` 함수는 지정한 영역을 번역합니다. 기본 언어는 `EN-US`이며, 접두사 인수로 호출하여 언어를 지정할 수 있습니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL 서비스의 인증 키를 설정하십시오.

- OPENAI\_API\_KEY

    OpenAI 인증 키.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepL과 ChatGPT용 명령줄 도구를 설치해야 합니다.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker 컨테이너 이미지.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python 라이브러리와 CLI 명령.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 라이브러리

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 명령줄 인터페이스

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    **greple** 매뉴얼에서 대상 텍스트 패턴에 대한 자세한 내용을 확인하십시오. 일치 범위를 제한하려면 **--inside**, **--outside**, **--include**, **--exclude** 옵션을 사용하십시오.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple** 명령 결과로 파일을 수정하려면 `-Mupdate` 모듈을 사용할 수 있습니다.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** 옵션과 함께 **sdif**을 사용하여 충돌 마커 형식을 나란히 표시하십시오.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** 모듈은 **--xlate-stripe** 옵션으로 사용합니다.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL API로 필요한 부분만 번역하고 교체하는 Greple 모듈(일본어)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL API 모듈로 15개 언어 문서 생성(일본어)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL API로 자동 번역 Docker 환경(일본어)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
