# dozo - 汎用 Docker Runner

## 概要

`xlate` コマンドの Docker runner 部分（`-C`, `-D`, `-L` オプション関連）を
独立したコマンド `dozo` として切り出した。

Docker の長いオプション（ボリュームマウント、環境変数、作業ディレクトリ、
インタラクティブ設定など）を自動的に設定してくれるので、実行したいコマンド
に集中できる。

## 目的

- **関心の分離**: xlate は翻訳に専念、Docker 実行は dozo に委譲
- **再利用性**: dozo は他のプロジェクトでも利用可能な汎用ツールになる
- **保守性向上**: Docker 関連のコードが一箇所に集約される

## 使用方法

```bash
# 直接使用
dozo -I ubuntu:latest echo hello    # コンテナ内でコマンド実行
dozo -I myimage:v1 -L               # ライブコンテナにアタッチ
dozo -I myimage:v1 bash             # 特定イメージでシェル起動
dozo -I myimage:v1 -KL              # コンテナを再作成してアタッチ

# xlate からの内部呼び出し
xlate -D ...  →  dozo -I tecolicom/xlate:version -- xlate ...
xlate -C ...  →  dozo -I tecolicom/xlate:version -- ...
xlate -L      →  dozo -I tecolicom/xlate:version -L -- ...
```

## dozo のオプション

| オプション | 説明 |
|-----------|------|
| `-I image` | Docker イメージ指定（必須、`.dozorc` で設定可） |
| `-E name[=value]` | 環境変数の継承（複数指定可） |
| `-W` | カレントディレクトリをマウント |
| `-H` | ホームディレクトリをマウント |
| `-V from:to` | 追加ボリュームのマウント（複数指定可） |
| `-U` | マウントしない |
| `--mount-mode` | マウントモード（rw または ro、デフォルト: rw） |
| `-R` | 読み取り専用でマウント（`--mount-mode=ro` のショートカット） |
| `-B` | バッチモード（非インタラクティブ） |
| `-N name` | ライブコンテナ名を明示指定 |
| `-K` | 既存コンテナを kill & remove |
| `-L` | ライブコンテナ（永続コンテナ）を使用 |
| `-P port` | ポートマッピング（複数指定可） |
| `-O option` | その他の docker オプション（複数指定可） |
| `-d` | デバッグモード |
| `-q` | 静粛モード |

## ユーティリティ関数

dozo に実装された関数：

- `git_topdir()` - git トップディレクトリの自動検出
- `container_name()` - イメージ名+ボリュームからコンテナ名を自動生成
- `docker_find()` - コンテナの検索
- `docker_status()` - コンテナの状態確認
- `get_ip()` - IP アドレス取得（DISPLAY 用）

## 自動継承する環境変数（デフォルト）

```bash
LANG TZ
HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
TERM_PROGRAM TERM_BGCOLOR COLORTERM
DEEPL_AUTH_KEY OPENAI_API_KEY ANTHROPIC_API_KEY LLM_PERPLEXITY_KEY
```

## 特徴的な機能

1. **Git フレンドリー**: git リポジトリ内なら自動的に git トップディレクトリをマウント
2. **ライブコンテナ**: `-L` で永続コンテナを作成・再利用、コンテナ名は自動生成
3. **環境変数の自動継承**: LANG, TZ, プロキシ設定, AI/LLM API キーなどを自動継承
4. **柔軟なマウント**: カレント(`-W`)、ホーム(`-H`)、追加ボリューム(`-V`)、読み取り専用(`-R`)
5. **X11 サポート**: DISPLAY が設定されていればホスト IP を自動検出してコンテナに渡す
6. **設定ファイル**: `.dozorc` でデフォルトオプションを設定可能
7. **スタンドアロン動作**: `App::Greple::xlate` モジュールがインストールされていれば、モジュールに同梱された `getoptlong.sh` を使用。インストールされていなければ PATH から検索

## xlate の実装

xlate は getoptlong.sh のコールバック機能とパススルー機能を使って Docker オプションを dozo に委譲する。

### オプション定義

```bash
declare -A OPTS=(
    [&USAGE]="$USAGE"
    # 翻訳オプション
    [    debug | d     # debug mode                      ]=
    [    quiet | q     # quiet mode                      ]=
    [      api | a     # use API                         ]=
    [   engine | e :   # translation engine              ]=
    [  tgt-lang| t :   # target language                 ]=
    # ... その他のオプション ...
    # Docker パススルーオプション（>dozo_opts で配列に追加）
    [    image | I :!  # Docker image                    ]=
    [      env | E @>dozo_opts # environment variable    ]=
    [mount-cwd | W  >dozo_opts # mount cwd               ]=
    [mount-home| H  >dozo_opts # mount home              ]=
    [   volume | V @>dozo_opts # additional volume       ]=
    [  unmount | U  >dozo_opts # do not mount            ]=
    [ mount-ro | R  >dozo_opts # mount read-only         ]=
    [    batch | B  >dozo_opts # batch mode              ]=
    [     name | N :>dozo_opts # container name          ]=
    [     port | P @>dozo_opts # port mapping            ]=
    [    other | O @>dozo_opts # additional docker option]=
    # Docker アクションオプション（! でコールバック関数を呼び出す）
    [     kill | K  !  # kill container                  ]=
    [   docker | D  !  # run xlate on Docker             ]=
    [  command | C  !  # run command on Docker           ]=
    [     live | L  !  # use live container              ]=
)
```

### コールバック関数

```bash
# -I コールバック: :version 形式の処理
image() {
    local opt="$1" val="$2"
    if [[ $val =~ ^:(.+)$ ]]; then
        version="${BASH_REMATCH[1]}"
    else
        image="$val"
    fi
}

# Docker アクションコールバック: -D, -C, -L, -K
docker_action() {
    [[ ${XLATE_RUNNING_ON_DOCKER:-} ]] && return
    [[ ${quiet:-} ]] && dozo_opts+=(-q)
    local opt="$1"
    case $opt in
        kill)
            if [[ ${PARSE_ARGS[$((OPTIND-1))]:-} =~ ^-.*L ]]; then
                dozo_opts+=(-K)  # -KL: -K だけ追加、-L に処理を委ねる
                return
            else
                set_default_image
                dozo_opts+=(-I "$image" -K)
                exec "$DOZO" "${dozo_opts[@]}"
            fi
            ;;
        live)
            dozo_opts+=(-L)
            ;;
    esac
    set_default_image
    dozo_opts+=(-I "$image")
    local -a cmd=("${PARSE_ARGS[@]:$((OPTIND-1))}")
    [[ $opt == docker ]] && cmd=(xlate "${cmd[@]}")
    exec "$DOZO" "${dozo_opts[@]}" -- "${cmd[@]}"
}
docker()  { docker_action "$@"; }
command() { docker_action "$@"; }
live()    { docker_action "$@"; }
kill()    { docker_action "$@"; }
```

### dozo の発見と実行

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOZO="${SCRIPT_DIR}/dozo"
[[ -x "$DOZO" ]] || DOZO="dozo"
```

## 設定ファイル

### .dozorc

`.dozorc` を以下の順序で検索し、すべてのオプションを収集：
1. ホームディレクトリ（最低優先度）
2. git トップディレクトリ（異なる場合）
3. カレントディレクトリ
4. コマンドライン引数（最高優先度）

収集したオプションはコマンドライン引数の前に追加され、getoptlong で
一括パースされる。後のオプションが優先されるため、コマンドラインが勝つ。

サポートする形式（コマンドラインと同じ）：
```bash
# コメント
-I tecolicom/xlate:latest
-L
-E CUSTOM_VAR=value
-V /host/path:/container/path
```

## 関連ファイル

- `script/xlate` - 翻訳 CLI（Docker オプションを dozo に委譲）
- `script/dozo` - 汎用 Docker runner
- `share/getoptlong/` - getoptlong.sh サブモジュール（https://github.com/tecolicom/getoptlong）

## getoptlong.sh の使用

dozo では `getoptlong.sh` を使ってオプション解析を行う。

### 実際の実装

```bash
declare -A OPTS=(
    [&USAGE]="$USAGE" [&PERMUTE]=
    [     debug | d   # enable debug mode               ]=
    [     quiet | q   # quiet mode                      ]=
    [     image | I : # Docker image                    ]=
    [       env | E @ # environment variable to inherit ]=
    [ mount-cwd | W   # mount current working directory ]=
    [mount-home | H   # mount home directory            ]=
    [    volume | V @ # additional volume to mount      ]=
    [   unmount | U   # do not mount                    ]=
    [mount-mode     : # mount mode (rw or ro)           ]=rw
    [  mount-ro | R   # mount read-only                 ]=
    [     batch | B   # batch mode (non-interactive)    ]=
    [      name | N : # live container name             ]=
    [      kill | K   # kill existing container         ]=
    [      live | L   # use live container              ]=
    [      port | P @ # port mapping                    ]=
    [     other | O @ # additional docker option        ]=
)

# .dozorc からオプションを収集
for dir in "${rcpath[@]}"; do
    rc="$dir/.dozorc"
    [[ -r $rc ]] || continue
    while IFS= read -r line; do
        [[ $line =~ ^# ]] && continue
        [[ -z $line ]] && continue
        rc_opts+=($line)
    done < "$rc"
done

# .dozorc オプション + コマンドライン引数を一括パース（ワンライナー形式）
. getoptlong.sh OPTS "${rc_opts[@]}" "$@" || die "getoptlong.sh not found"
```

### getoptlong.sh の主な機能

| 記号 | 意味 |
|-----|------|
| `:` | 引数必須 |
| `?` | 引数オプション |
| `+` | フラグ（デフォルト） |
| `@` | 配列（複数指定可） |
| `%` | ハッシュ |
| `#` | コメント（ヘルプ表示用） |
| `]=value` | デフォルト値 |
| `!` | コールバック関数を呼び出す |
| `>array` | 値を指定配列に追加（パススルー） |

### 利点

1. **宣言的な定義**: オプションを連想配列で定義
2. **自動ヘルプ生成**: `getoptlong help` でヘルプを表示
3. **エイリアス**: `image|I` で長短オプションを同時定義
4. **配列サポート**: `-E` を複数回指定すると配列に追加
5. **コメント**: `#` 以降がヘルプメッセージになる
6. **デフォルト値**: `]=value` で初期値を設定
7. **コールバック**: `!` でオプション名と同じ名前の関数を呼び出す
8. **パススルー**: `>dozo_opts` で値を別の配列に追加
9. **ワンライナー呼び出し**: `. getoptlong.sh OPTS "$@"` で初期化からパースまで一度に実行

## getoptlong.sh の検索

dozo は `App::Greple::xlate` モジュールに同梱された `getoptlong.sh` を使用する。
モジュールがインストールされていない場合は PATH から検索する。

```bash
# Set PATH for getoptlong.sh
dist_dir() {
    local mod=$1
    perl -M$mod -MFile::Share=:all -E "say dist_dir '${mod//::/-}'" 2>/dev/null || true
}
share=$(dist_dir App::Greple::xlate)
PATH="${share:+$share:}$PATH"
```

`dist_dir` 関数は `File::Share` モジュールを使って、Perl モジュールの共有ディレクトリを
取得する。開発環境でもインストール環境でも正しいパスを返す。

モジュールがインストールされていない場合は `perl` コマンドが失敗するが、
`|| true` により `set -e` 環境でもスクリプトは継続し、PATH から `getoptlong.sh` を検索する。

## 実装メモ

- xlate の `-D` は「xlate を Docker で実行」、`-C` は「任意コマンドを Docker で実行」
- dozo はイメージ指定が必須（`-I` オプション）
- xlate は自動的にデフォルトイメージ（`tecolicom/xlate:version`）を設定
- dozo と コマンドの間には `--` セパレータを使用してオプションの混同を防ぐ
- `-K` 単独で使用するとコンテナを削除して終了、`-KL` で再作成
- 中間変数を排除し、オプション変数を直接使用（`${batch:-}`, `${unmount:-}`, `${live:-}`）

## ライセンス

dozo は MIT ライセンスで公開されている。
