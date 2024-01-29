# NAME

subst - 텍스트 검색 및 대체를 위한 Greple 모듈

# VERSION

Version 2.3304

# SYNOPSIS

greple -Msubst --dict _사전_ \[ 옵션 \]을 입력하세요.

    Dictionary:
      --dict      dictionary file
      --dictdata  dictionary data

    Check:
      --check=[ng,ok,any,outstand,all,none]
      --select=N
      --linefold
      --stat
      --with-stat
      --stat-style=[default,dict]
      --stat-item={match,expect,number,ok,ng,dict}=[0,1]
      --subst
      --[no-]warn-overlap
      --[no-]warn-include

    File Update:
      --diff
      --diffcmd command
      --create
      --replace
      --overwrite

# DESCRIPTION

이 **greple** 모듈은 사전 데이터를 기반으로 텍스트 파일의 확인 및 치환을 지원합니다.

사전 파일은 **--dict** 옵션으로 지정되며 각 줄에는 일치하는 패턴과 예상 문자열 쌍이 포함됩니다.

    greple -Msubst --dict DICT

사전 파일에 다음과 같은 데이터가 포함되어 있다면

    colou?r      color
    cent(er|re)  center

위의 명령은 두 번째 문자열과 일치하지 않는 첫 번째 패턴, 즉 이 경우 "색상"과 "가운데"를 찾습니다.

사전 데이터의 필드 `//`는 무시되므로 이 파일은 다음과 같이 작성할 수 있습니다:

    colou?r      //  color
    cent(er|re)  //  center

**greple**의 **-f** 옵션으로 동일한 파일을 사용할 수 있으며, 이 경우 `//` 뒤의 문자열은 주석으로 무시됩니다.

    greple -f DICT ...

옵션 **--dictdata**는 명령줄에서 사전 데이터를 제공하는 데 사용할 수 있습니다.

    greple --dictdata $'colou?r color\ncent(er|re) center\n'

날카로운 기호(`#`)로 시작하는 사전 항목은 주석이며 무시됩니다.

## Overlapped pattern

일치하는 문자열이 다른 패턴으로 이전에 일치한 문자열과 같거나 더 짧으면 무시됩니다(기본적으로 **--no-warn-include**). 따라서 충돌하는 패턴을 선언해야 하는 경우 더 긴 패턴을 더 앞에 배치하세요.

일치된 문자열이 이전에 일치된 문자열과 겹치면 경고(기본적으로 **--warn-overlap**)가 표시되고 무시됩니다.

## Terminal color

이 버전은 [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor) 모듈을 사용합니다. 이 모듈은 명령이 실행되는 터미널에 따라 옵션 **--밝은 화면** 또는 **--어두운 화면** 또는 **TERM\_BGCOLOR** 환경 변수를 설정합니다.

일부 터미널(예: "Apple\_Terminal" 또는 "iTerm")은 자동으로 감지되므로 별도의 조치가 필요하지 않습니다. 그렇지 않으면 단말기 배경색에 따라 **TERM\_BGCOLOR** 환경을 #000000(검은색) ~ #FFFFFF(흰색) 숫자로 설정합니다.

# OPTIONS

- **--dict**=_file_

    사전 파일을 지정합니다.

- **--dictdata**=_data_

    사전 데이터를 텍스트로 지정합니다.

- **--check**=`outstand`|`ng`|`ok`|`any`|`all`|`none`

    옵션 **--check**는 `ng`, `ok`, `any`, `outstand`, `all`, `none`에서 인수를 받습니다.

    기본값 `outstand`를 사용하면 명령은 동일한 파일에서 예기치 않은 단어가 발견된 경우에만 예상 단어와 예기치 않은 단어에 대한 정보를 모두 표시합니다.

    `ng` 값을 사용하면 명령은 예기치 않은 단어에 대한 정보를 표시합니다. `ok` 값을 사용하면 예상 단어에 대한 정보를 얻을 수 있습니다. 둘 다 `any` 값을 사용합니다.

    `모두` 및 `없음` 값은 **--stat** 옵션과 함께 사용할 때만 의미가 있으며 일치하지 않는 패턴에 대한 정보를 표시합니다.

- **--select**=_N_

    사전에서 _N_번째 항목을 선택합니다. 인자는 [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers) 모듈에 의해 해석됩니다. 범위는 **--선택**=`1:3,7:9`처럼 정의할 수 있습니다. **--stat** 옵션으로 숫자를 가져올 수 있습니다.

- **--linefold**

    대상 데이터가 텍스트 중간에 접혀있는 경우 **--linefold** 옵션을 사용합니다. 줄에 걸쳐 펼쳐진 문자열과 일치하는 정규식 패턴을 생성합니다. 하지만 대체된 텍스트에는 개행이 포함되지 않습니다. 정규식 동작에 다소 혼란을 줄 수 있으므로 가급적 사용하지 마세요.

- **--stat**
- **--with-stat**

    통계 정보를 인쇄합니다. **--체크** 옵션과 함께 작동합니다.

    **--with-stat** 옵션은 일반 출력 후 통계를 인쇄하고, **--stat**은 통계만 인쇄합니다.

- **--stat-style**=`default`|`dict`

    **--stat-style=dict** 옵션을 **--stat** 및 **--check=any**와 함께 사용하면 작업 문서에 대한 사전 스타일 출력을 얻을 수 있습니다.

- **--stat-item** _item_=\[0,1\]

    통계 정보에 표시할 항목을 지정합니다. 기본값은 다음과 같습니다:

        match=1
        expect=1
        number=1
        ng=1
        ok=1
        dict=0

    패턴 필드를 볼 필요가 없는 경우 다음과 같이 사용하세요:

        --stat-item match=0

    한 번에 여러 매개변수를 설정할 수 있습니다:

        --stat-item match=number=0,ng=1,ok=1

- **--subst**

    예상치 못한 일치 패턴을 예상 문자열로 대체합니다. 일치하는 문자열의 개행 문자는 무시됩니다. 대체 문자열이 없는 패턴은 변경되지 않습니다.

- **--\[no-\]warn-overlap**

    중복된 패턴 경고. 기본값은 켜짐입니다.

- **--\[no-\]warn-include**

    포함된 패턴 경고. 기본값은 꺼짐입니다.

## FILE UPDATE OPTIONS

- **--diff**
- **--diffcmd**=_command_

    옵션 **--diff**는 원본 텍스트와 변환된 텍스트의 diff 출력을 생성합니다.

    **--diff** 옵션에서 사용할 diff 명령 이름을 지정합니다. 기본값은 "diff -u"입니다.

- **--create**

    새 파일을 생성하고 결과를 씁니다. 원본 파일 이름에 접미사 ".new"가 추가됩니다.

- **--replace**

    대상 파일을 변환된 결과로 바꿉니다. 원본 파일에 접미사 ".bak"이 붙은 백업 이름으로 이름이 바뀝니다.

- **--overwrite**

    백업 없이 변환된 결과로 대상 파일을 덮어씁니다.

# DICTIONARY

이 모듈에는 예제 딕셔너리가 포함되어 있습니다. 예제 사전은 공유 디렉터리에 설치되며 **--exdict** 옵션으로 액세스합니다.

    greple -Msubst --exdict jtca-katakana-guide-3.dict

- **--exdict** _dictionary_

    배포에서 _사전_ 플라이를 사전 파일로 사용합니다.

- **--exdictdir**

    사전 디렉토리를 표시합니다.

- **--exdict** jtca-katakana-guide-3.dict
- **--jtca-katakana-guide**

    다음 가이드라인 문서에서 생성합니다.

        外来語（カタカナ）表記ガイドライン 第3版
        制定：2015年8月
        発行：2015年9月
        一般財団法人テクニカルコミュニケーター協会 
        Japan Technical Communicators Association
        https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

- **--jtca**

    사용자 지정 **--jtca-katakana-guide**. 원본 사전은 게시된 데이터에서 자동으로 생성됩니다. 이 사전은 실제 사용을 위해 사용자 정의됩니다.

- **--exdict** jtf-style-guide-3.dict
- **--jtf-style-guide**

    다음 가이드라인 문서에서 생성합니다.

        JTF日本語標準スタイルガイド（翻訳用）
        第3.0版
        2019年8月20日
        一般社団法人 日本翻訳連盟（JTF）
        翻訳品質委員会
        https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

- **--jtf**

    사용자 정의 **--jtf-style-guide**. 게시된 데이터에서 원본 사전이 자동으로 생성됩니다. 이 사전은 실제 사용에 맞게 사용자 정의됩니다.

- **--exdict** sccc2.dict
- **--sccc2**

    2014년에 출간된 "C/C++ セキュアコーディング 第2版"에 사용된 사전입니다.

        https://www.jpcert.or.jp/securecoding_book_2nd.html

- **--exdict** ms-style-guide.dict
- **--ms-style-guide**

    Microsoft 로컬라이제이션 스타일 가이드에서 생성된 사전입니다.

        https://www.microsoft.com/ja-jp/language/styleguides

    이 문서에서 데이터를 생성합니다:

        https://www.atmarkit.co.jp/news/200807/25/microsoft.html

- **--microsoft**

    사용자 지정 **--ms-style-guide**. 원본 사전은 게시된 데이터에서 자동으로 생성됩니다. 이 사전은 실제 사용을 위해 사용자 지정되었습니다.

    수정 사전은 [여기](https://github.com/kaz-utashiro/greple-subst/blob/master/share/ms-amend.dict)에서 찾을 수 있습니다. 업데이트 요청이 있는 경우 이슈를 제기하거나 풀 리퀘스트를 보내주세요.

# JAPANESE

이 모듈은 원래 일본어 텍스트 편집 지원을 위해 만들어졌습니다.

## KATAKANA

일본어 가타카나 단어는 같은 단어를 설명하는 변형이 많기 때문에 통일이 중요하지만 상당히 번거로운 작업입니다. 다음 예제에서는

    イ[エー]ハトー?([ヴブボ]ォ?)  //  イーハトーヴォ

왼쪽 패턴은 다음의 모든 단어와 일치합니다.

    イエハトブ
    イーハトヴ
    イーハトーヴ
    イーハトーヴォ
    イーハトーボ
    イーハトーブ

이 모듈은 이를 감지하고 수정하는 데 도움이 됩니다.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::subst

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-subst](https://github.com/kaz-utashiro/greple-subst)

[https://github.com/kaz-utashiro/greple-update](https://github.com/kaz-utashiro/greple-update)

[https://www.jtca.org/standardization/katakana\_guide\_3\_20171222.pdf](https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf)

[https://www.jtf.jp/jp/style\_guide/styleguide\_top.html](https://www.jtf.jp/jp/style_guide/styleguide_top.html), [https://www.jtf.jp/jp/style\_guide/pdf/jtf\_style\_guide.pdf](https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf)

[https://www.microsoft.com/ja-jp/language/styleguides](https://www.microsoft.com/ja-jp/language/styleguides), [https://www.atmarkit.co.jp/news/200807/25/microsoft.html](https://www.atmarkit.co.jp/news/200807/25/microsoft.html)

[文化庁 国語施策・日本語教育 国語施策情報 内閣告示・内閣訓令 外来語の表記](https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/gairai/index.html)

[https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415](https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415)

[イーハトーブ](https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%BC%E3%83%8F%E3%83%88%E3%83%BC%E3%83%96)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2017-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
