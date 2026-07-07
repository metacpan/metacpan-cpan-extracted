# NAME

App::Greple::xlate - greple용 번역 지원 모듈

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** 모듈은 원하는 텍스트 블록을 찾아 번역된 텍스트로 대체합니다. 기본 엔진은 [llm](https://llm.datasette.io/) 명령을 호출하는 GPT-5.5(`llm/gpt5.pm`)이며, DeepL(`deepl.pm`) 및 레거시 **gpty** 기반 엔진도 포함되어 있습니다.

번역은 파일별로 캐시되므로, 변경되지 않은 텍스트에 대해 명령을 다시 실행해도 비용이 들지 않습니다. 문서가 편집되면 변경된 단락만 API로 다시 전송됩니다. 컨텍스트 인식 엔진은 주변 번역, 변경 주변의 원시 소스 텍스트, 그리고 편집된 단락의 이전 버전도 함께 받으므로 새 번역은 기존에 확립된 문구를 유지합니다(**--xlate-context-window** 참조). 민감한 문자열은 전송 전에 숨길 수 있습니다(["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates) 참조).

Perl의 pod 스타일로 작성된 문서에서 일반 텍스트 블록을 번역하려면 다음과 같이 `--xlate-engine gpt5` 및 `perl` 모듈과 함께 **greple** 명령을 사용하십시오:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

이 명령에서 패턴 문자열 `^([\w\pP].*\n)+` 은 영숫자 및 구두점 문자로 시작하는 연속된 줄을 의미합니다. 이 명령은 번역할 영역을 하이라이트하여 표시합니다. 옵션 **--all** 는 전체 텍스트를 생성하는 데 사용됩니다.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

그런 다음 선택된 영역을 번역하려면 `--xlate` 옵션을 추가하세요. 그러면 원하는 섹션을 찾아 번역 엔진의 출력으로 교체합니다.

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

이는 파일의 각 줄을 `MASKPATTERN`로 해석하여 정규 표현식으로 사용하고, 이에 매칭되는 문자열을 번역한 뒤 처리 후 되돌립니다. `#`로 시작하는 줄은 무시됩니다.

복잡한 패턴은 백슬래시로 개행을 이스케이프하여 여러 줄에 걸쳐 작성할 수 있습니다.

마스킹에 의해 텍스트가 어떻게 변환되는지는 **--xlate-mask** 옵션으로 확인할 수 있습니다.

마스킹은 마크업이 번역되지 않도록 보호합니다. 번역 서비스 자체로부터 민감한 문자열을 숨기려면 ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)를 참조하십시오. 둘 다 함께 사용할 수 있습니다.

이 인터페이스는 실험적이며 향후 변경될 수 있습니다.

# ANONYMIZATION AND TEMPLATES

민감한 문자열은 번역 API로 전송되기 전에 숨기고 출력에서 복원할 수 있습니다. 익명화 규칙의 소스는 세 가지가 있습니다: 사전 파일(**--xlate-anonymize**), 문서 자체의 인라인 마크(**--xlate-anonymize-mark**), YAML 프런트 매터 값(**--xlate-frontmatter**). 각 문자열은 전송 중에 `<person id=1 />`와 같은 범주 태그로 대체됩니다. 은닉 대상은 API 전송에만 해당합니다. 로컬 캐시 파일에는 복원된 일반 텍스트가 저장됩니다. 실제로 무엇이 전송될지 정확히 확인하려면 **--xlate-dryrun** 를 사용하십시오.

양식 문서(분기 보고서 등)의 경우, 먼저 행위자를 정의하고 본문에서 참조합니다:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

`--xlate-template` 를 사용하여 언어별로 템플릿을 한 번 번역하고(값이 파일에 유지되는 경우 `--xlate-frontmatter` 도 함께), 그런 다음 **pandoc-embedz** 독립 실행 모드로 각 사례를 렌더링합니다. 외부 설정의 `global:` 아래에 있는 값은 번역 API에 전혀 전달되지 않습니다:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

인라인 마크의 경우, 매크로 정의 설정을 제공하면 동일한 번역된 템플릿이 실제 이름이나 익명 처리된 버전 중 하나로 렌더링됩니다:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

문서에 embedz 블록이 포함되어 있을 때는 해당 블록을 번역에서 제외합니다:

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

    사용할 번역 엔진을 지정합니다.

    현재 다음 엔진들이 사용 가능합니다

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    엔진 모듈은 먼저 백엔드 네임스페이스(`llm`, 그다음 `gpty`)에서 검색한 다음, `App::Greple::xlate` 바로 아래에서 검색합니다. 따라서 `gpt5` 는 `llm` 명령을 호출하는 `App::Greple::xlate::llm::gpt5` 를 로드하는 반면, `gpt4o` 는 `App::Greple::xlate::gpty::gpt4o` 로 폴백합니다. 특정 백엔드를 강제로 사용하려면 `--xlate-setopt backend=gpty` 를 사용하십시오.

- **--xlate-labor**
- **--xlabor**

    번역 엔진을 호출하는 대신 사용자가 수동으로 작업하는 방식을 기대합니다. 번역할 텍스트를 준비한 뒤 클립보드로 복사합니다. 양식에 붙여넣고, 결과를 클립보드로 복사한 다음, 리턴 키를 누르십시오.

- **--xlate-to** (Default: `EN-US`)

    대상 언어를 지정합니다. LLM 엔진은 모델이 이해하는 모든 언어 이름이나 코드를 허용하며, 이는 번역 프롬프트에 보간됩니다. **DeepL** 엔진을 사용할 때는 `deepl languages` 명령으로 사용 가능한 언어를 얻을 수 있습니다.

- **--xlate-from** (Default: `ORIGINAL`)

    `conflict`, `colon` 및 `ifdef` 출력 형식에서 원문에 사용되는 레이블입니다. **DeepL** 엔진에서는 기본값이 아닌 값도 원본 언어로 전달됩니다.

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

    한 번에 API로 전송할 텍스트의 최대 길이를 지정합니다. 기본값 0은 엔진 자체의 제한을 의미합니다: 무료 DeepL 계정 서비스의 경우 API(**--xlate**)는 128K, 클립보드 인터페이스(**--xlate-labor**)는 5000입니다. Pro 서비스를 사용 중이라면 이 값을 변경할 수 있습니다.

- **--xlate-maxline**=_n_ (Default: 0)

    한 번에 API로 전송할 텍스트의 최대 줄 수를 지정합니다.

    한 줄씩 번역하려면 이 값을 1로 설정하십시오. 이 옵션은 `--xlate-maxlen` 옵션보다 우선합니다.

- **--xlate-prompt**=_text_

    번역 엔진에 보낼 사용자 지정 프롬프트를 지정합니다. 이 옵션은 LLM 엔진(`gpt3`, `gpt4o`, `gpt5`)에서 사용할 수 있지만 DeepL에서는 사용할 수 없습니다. AI 모델에 특정 지시사항을 제공하여 번역 동작을 사용자 지정할 수 있습니다. 프롬프트에 `%s`가 포함되어 있으면 대상 언어 이름으로 대체됩니다.

- **--xlate-context**=_text_

    번역 엔진으로 전송할 추가 컨텍스트 정보를 지정합니다. 이 옵션은 여러 번 사용하여 여러 컨텍스트 문자열을 제공할 수 있습니다. 컨텍스트 정보는 번역 엔진이 배경을 이해하고 더 정확한 번역을 생성하는 데 도움이 됩니다.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    변경된 블록을 다시 번역할 때 참조 컨텍스트로 전달할 주변 번역 블록 수(기본값 2)를 지정합니다. 컨텍스트에는 변경된 영역 주변의 원시 소스 텍스트(제목, 목록 구조, 캡션)도 포함되며, 사용 가능한 경우 캐시에서 복원한 변경된 텍스트의 이전 버전도 포함되어 변경되지 않은 표현이 보존됩니다. 컨텍스트 인식 번역을 완전히 비활성화하려면 0으로 설정합니다. 각 변경 영역은 자체 API 호출로 번역되며 컨텍스트는 시스템 프롬프트에 최대 약 8000자를 추가할 수 있으므로, 컨텍스트 인식 번역은 일관성을 위해 약간의 추가 비용을 감수한다는 점에 유의하십시오.

- **--xlate-cache-seed**=_file_

    새 문서의 캐시를 다른 문서의 캐시 파일로 초기화합니다. 정기 보고서에 유용합니다. 새 호의 캐시에 이전 호의 캐시를 시드하여 변경되지 않은 단락은 다시 번역하지 않고 편집된 단락은 이전 호의 표현을 유지하도록 합니다. 시드는 대상 캐시가 비어 있을 때만 사용되며, 그렇지 않으면 경고와 함께 무시됩니다. 기본 `--xlate-cache=auto`에서는 시드를 지정하면 새 문서의 캐시 파일 생성도 암시합니다.

- **--xlate-anonymize**=_file_

    민감한 문자열이 번역 API로 전송되기 전에 익명화하고 출력에서 복원합니다. 사전 파일은 항목당 하나의 엔트리를 제공합니다: JSON(정규 형식, 기계 생성 가능)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    또는 단순한 줄 형식(`category pattern`, regex의 경우 `/.../`)입니다. 각 항목은 `<person id=1 />`와 같은 범주 태그로 대체됩니다. 동일한 문자열은 항상 동일한 태그를 받으므로 모델은 누가 누구인지 추적할 수 있습니다. 알 수 없는 JSON 필드는 무시되므로 생성기(예: 엔티티를 추출하는 로컬 LLM)는 자체 주석을 추가할 수 있습니다. 범주 `lit`는 예약되어 있습니다. 로컬 캐시 파일은 여전히 복원된 일반 텍스트를 저장합니다. 은닉 대상은 API 전송에만 한정됩니다.

    사전은 외부 도구로 생성할 수 있습니다. 예를 들어 민감한 엔티티를 추출하는 로컬 모델이 있습니다:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    파일의 UTF-8 BOM은 허용됩니다. front matter 줄 형식의 값은 값 뒤가 아니라 별도의 줄에만 후행 주석을 가질 수 있습니다.

- **--xlate-anonymize-mark**\[=_regex_\]

    문서 자체의 인라인 표시에서 익명화 엔트리를 수집합니다. 첫 번째 출현을 `{{ person("山田太郎") }}`처럼 표시하면 문서 전체에서 해당 문자열의 모든 출현이 익명화됩니다. 표시 자체는 소스와 번역에 그대로 남으므로, 문서는 Jinja2 스타일 매크로 프로세서로도 처리할 수 있습니다(`person` 매크로를 정의하여 이름을 출력하거나 편집 처리하십시오). 사용자 지정 _regex_에는 `(?<category>...)` 및 `(?<text>...)` 명명 캡처가 포함되어야 합니다.

    이와 같은 선택적 값 옵션에서는 뒤따르는 파일 인수가 값으로 간주된다는 점에 유의하십시오. 기본 표기법을 사용할 때는 `--xlate-anonymize-mark=`(뒤에 `=` 포함)라고 작성하십시오.

    대체 표기법을 구성할 수 있습니다. 예를 들어 `@@person:NAME@@` 스타일 표시에는 `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'`를, 렌더링된 Markdown에서 보이지 않는 HTML 주석 형식을 사용할 수 있습니다. 표시 규칙은 문서별로 수집됩니다. 한 입력 파일에 표시된 문자열은 같은 실행의 다른 파일에서는 은닉되지 않습니다(파일 간에 누적되는 front matter 값과는 다릅니다).

- **--xlate-template**\[=_regex_\]

    템플릿 표현식(기본값: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`)을 불투명한 플레이스홀더로 취급합니다. 모델에 이를 변경하지 않고 복사하도록 지시하고, 블록별로 응답에 정확히 동일한 표현식이 각각 동일한 횟수만큼 포함되어 있는지 검증합니다. 번역에서는 대상 언어의 어순에 맞추기 위해 이를 합법적으로 재정렬할 수 있으므로 순서는 바뀔 수 있습니다. 손상된 표현식이 있으면 실행이 중단됩니다. 캐시는 체크포인트되고 고정되므로 비용이 지불된 것은 손실되지 않습니다.

    이와 같은 선택적 값 옵션에서는 뒤따르는 파일 인수가 값으로 간주된다는 점에 유의하십시오. 기본 표기법을 사용할 때는 `--xlate-template=`(뒤에 `=`를 붙여서)라고 작성하십시오.

- **--xlate-frontmatter**

    선행 `---` ... `---` 블록을 YAML 프런트 매터로 취급합니다. 이를 번역 및 phase-2 컨텍스트 슬라이스에서 제외하고, 안전망으로 그 평면 `key: value` 값들을 익명화 규칙(범주 `var`)에 추가합니다. 입력 파일이 여러 개인 경우 수집된 값은 누적됩니다(은폐 쪽으로 치우쳐 처리).

    항상 닫는 `---` 뒤에 빈 줄을 남겨 두십시오. 문단 스타일의 일치 패턴에서는 본문 텍스트로 바로 이어지는 프런트 매터가 제외로 억제할 수 없는 걸친 블록 하나를 형성합니다(이 경우 경고가 출력됩니다). 값들은 여전히 익명화되지만, 프런트 매터 자체는 번역 대상으로 전송됩니다.

- **--xlate-glossary**=_glossary_

    번역에 사용할 용어집 ID를 지정합니다. 이 옵션은 DeepL 엔진을 사용할 때만 제공됩니다. 용어집 ID는 DeepL 계정에서 얻어야 하며 특정 용어의 일관된 번역을 보장합니다.

- **--xlate-dryrun**

    번역 API를 호출하지 말고, 대신 진행률 표시를 통해 각 페이로드를 전송될 그대로(익명화 및 마스킹 후) 표시합니다. 머신을 떠나는 내용을 확인하고 실행 비용을 추정하는 데 유용합니다.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 출력에서 번역 결과를 실시간으로 확인합니다. `From` 페이로드는 익명화 및 마스킹 후 전송된 그대로 표시됩니다.

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

`xlate` 명령은 `--to-lang`, `--from-lang`, `--engine`, `--file`와 같은 GNU 스타일의 롱 옵션을 지원합니다. 사용 가능한 모든 옵션을 보려면 `xlate -h`을(를) 사용하십시오.

`xlate` 명령은 Docker 환경과 연동되므로, 로컬에 아무것도 설치되어 있지 않아도 Docker만 사용할 수 있다면 사용할 수 있습니다. `-D` 또는 `-C` 옵션을 사용하십시오.

Docker 작업은 [App::dozo](https://metacpan.org/pod/App%3A%3Adozo)에 의해 처리되며, 이는 독립 실행형 명령으로도 사용할 수 있습니다. `dozo` 명령은 지속적인 컨테이너 설정을 위해 `.dozorc` 구성 파일을 지원합니다.

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

    레거시 **gpty** 엔진에서 사용하는 OpenAI 인증 키. `llm` 기반 **gpt5** 엔진도 이 변수를 읽지만, `llm keys set openai`로 저장된 키도 작동합니다.

- GREPLE\_XLATE\_CACHE

    기본 캐시 전략을 설정하십시오(["CACHE OPTIONS"](#cache-options) 참조).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

사용하는 엔진용 명령줄 도구를 설치하십시오: **gpt5** 엔진에는 `llm`, DeepL에는 `deepl`, 레거시 GPT 엔진에는 `gpty`.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - 컨테이너 작업을 위해 xlate에서 사용하는 범용 Docker 실행기

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    **greple** 매뉴얼에서 대상 텍스트 패턴에 대한 자세한 내용을 확인하십시오. 일치 범위를 제한하려면 **--inside**, **--outside**, **--include**, **--exclude** 옵션을 사용하십시오.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple** 명령 결과로 파일을 수정하려면 `-Mupdate` 모듈을 사용할 수 있습니다.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V** 옵션과 함께 **sdif**을 사용하여 충돌 마커 형식을 나란히 표시하십시오.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** 모듈은 **--xlate-stripe** 옵션으로 사용합니다.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker 컨테이너 이미지.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` 라이브러리는 `xlate` 스크립트와 [App::dozo](https://metacpan.org/pod/App%3A%3Adozo)에서 옵션 파싱에 사용됩니다.

- [https://llm.datasette.io/](https://llm.datasette.io/)

    **gpt5** 엔진이 LLM 모델에 액세스하는 데 사용하는 `llm` 명령.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python 라이브러리와 CLI 명령.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 라이브러리

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 명령줄 인터페이스

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

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
