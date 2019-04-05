# NAME

Dwarf - Web Application Framework (Perl5)

# SYNOPSIS

        package App::Controller::Web;
        use Dwarf::Pragma;
        use parent 'App::Controller::WebBase';
        use Dwarf::DSL;

        sub get {
                render 'index.html';
        }

        1;

# DESCRIPTION

Dwarf は小規模グループ（1〜5人）向け Plack ベースのウェブアプリケーションフレームワークです。<br />

- ある程度の作業単位 (モジュール単位) で分業がし易い
- 設計の美しさより、簡潔性と利便性を重視

といった特徴があります。<br />
<br />
Catalyst に比べるとかなり軽量。多くの Sinatraish な WAF と発想や規模は近いがスタイルが異なります。

## プロジェクト初期化

        % dwarf hello_world

もしくは

        % dir=${dwarf_cloned_dir}
        % mkdir hello_world
        % perl ${dir}/bin/dwarf --share_dir=${dir}/share --output=. hello_world
        created ./hello_world/app
        created ./hello_world/htdocs

## 起動

デフォルトでは plackup で起動します。<br />
オプション -m に production と指定することで starman で起動します。<br />
この起動スクリプトは自由に編集して使われることを想定しています。

        % cd hello_world/app
        % ./script/start_searver.sh

## プロジェクト構造

Dwarf は「プロジェクト毎に使い捨てる」という思想で作られています。<br />
よってフレームワーク本体もローカルに置かれるのが特徴です。

        app/
                app.psgi                   ... PSGI ファイル
                cli.psgi                   ... コマンドラインツール用 PSGI ファイル
                cpanfile                   ... cpanfile
                Makefile                   ... Make ファイル
            lib/                           ... プログラム本体
                App.pm                     ... アプリケーションクラス
                App/
                        Config/            ... 設定ファイル
                        Constant.pm        ... 定数定義
                        DB.pm              ... Teng のサブクラス
                        DB/
                                Schema.pm  ... スキーマクラス
                        Controller/        ... コントローラ
                                Api/       ... JSON や XML を返す API 用コントローラ
                                ApiBase.pm ... API 用コントローラのベースクラス
                                Cli/       ... コマンドラインツール用コントローラ
                                CliBase.pm ... コマンドラインツール用コントローラのベースクラス
                                Web/       ... HTML を返す Web ページ用コントローラ
                                WebBase.pm ... Web ページ用コントローラのベースクラス
                        Model/             ... モデル
                        Test.pm            ... テストクラス
                        Util/              ... ユーティリティクラス
                Dwarf.pm                   ... Dwarf 本体
                Dwarf/
            script/                        ... コマンドラインツール
            sql/                           ... SQL
            t/                             ... テスト
            tmpl/                          ... HTML のテンプレート
        htdocs/                            ... ドキュメントルート

## 設定ファイル

設定ファイルは Perl オブジェクトで記述します。<br />
デフォルトで記述されている項目以外については自由に編集することが出来ます。<br />

        package App::Config::Production;
        use Dwarf::Pragma;
        use parent 'Dwarf::Config';

        sub setup {
                my $self = shift;
                return (
                        db => {
                                master => {
                                        dsn      => 'dbi:Pg:dbname=hello_world',
                                        username => 'www',
                                        password => '',
                                        opts     => { pg_enable_utf8 => 1 },
                                },
                        },
                        ssl => 1, # SSL をサポートするかどうか
                        url => {
                                base     => 'http://hello_world.com',
                                ssl_base => 'https://hello_world.com',
                        },
                        dir => {
                        },
                        filestore => {
                                private_dir => $self->c->base_dir . "/../data",
                                public_dir  => $self->c->base_dir . "/../htdocs/data",
                                public_uri  => "/data",
                        },
                        app => {
                                facebook => {
                                        id     => '',
                                        secret => '',
                                },
                                twitter  => {
                                        id     => '',
                                        secret => '',
                                }
                        },
                );
        }

        1;

## ルーティング

Dwarf は Router::Simple を使ってルーティングを実装しています。

デフォルトのルーティングは Dwarf.pm に実装されています。

        sub add_routes {
                my $self = shift;
                $self->router->connect("/api/*", { controller => "Api" });
                $self->router->connect("/cli/*", { controller => "Cli" });
                $self->router->connect("*", { controller => "Web" });
        }

変更や追加も出来ます。App.pm に実装します。

        before add_routes => sub {
                my $self = shift;
                $self->router->connect("/images/{id:-?[0-9]+}", { controller => "Web::Images::Detail" });
        };

### splat について

Router::Simple の match メソッドによって得られたオブジェクトの要素に splat が存在する場合、Dwarf は Controller 名の末尾に splat を追加します。

例) /api/ping へのリクエスト

App::Controller::Api::Ping へルーティングされます。

```
{ controller => 'Api', splat => ['ping'] }
```

## コントローラ

Dwarf のコントローラはディスパッチされてきたリクエストに呼応するためのロジックを実装するクラスです。<br />
一般的な MVC フレームワークのようにモデルやビューを操作することに終止するクラスとは少し違います。<br />
<br />
例えば、WEB ページを表示するコントローラの場合、DB から情報を取ってきて加工する操作やビューに渡すデータの加工などのロジックは全てコントローラに実装します。<br />

### 作成

/login でアクセスされる WEB ページ用のコントローラを作成する

        % ./script/generate.pl Controller::Web::Login

### 実装

GET でログインフォームを表示し、POST で認証ロジックを実装する

        package App::Controller::Web::Login;
        use Dwarf::Pragma;
        use parent 'App::Controller::WebBase';
        use Dwarf::DSL;
        use Class::Method::Modifiers;

        # バリデーションの実装例。validate は何度でも呼べる。
        # will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
        after will_dispatch => sub {
            if (method eq 'POST') {
                self->validate(
                    username => [qw/NOT_NULL/],
                    password => [qw/NOT_NULL/],
                );
            }
        };

        sub get {
            render 'login.html';
        }

        sub post {
                model('Auth')->authenticate(param('username'), param('password'))
                    or unauthorized;
                redirect '/';
        }

### REST 的なリクエストの置き場所

単なる習慣であってルールではありません。

`Resources` コントローラには以下を配置。

```
GET /api/resources => 一覧
POST /api/resources => 作成
```

`Resoures::Detail` コントローラには以下を配置。

```
GET /api/resources/{id} => 詳細
PUT /api/resources/{id} => 置き換え
PATCH /api/resources/{id} => 部分置き換え
DELETE /api/resources/{id} => 削除
```

`App.pm` にルーティングを追加する

```
before add_routes => sub {
    my $self = shift;
    $self->router->connect("/api/resources/{id:[0-9]+}", { controller => "Api::Resources::Detail" });
};
```

## モデル

Dwarf のモデルは複数のコントローラで共用されるようなロジックを汎用化して実装するためのクラスです。

### 作成

model('Auth') で呼ばれるモデルを作成する

        % ./script/generate.pl Model::Auth

### 実装

        package App::Model::Auth;
        use Dwarf::Pragma;
        use parent 'Dwarf::Module';
        use Dwarf::DSL;
        use App::Constant;

        use Dwarf::Accessor qw/member/;

        sub is_login {
                session->param('member') or return false;
                return true;
        }

        sub authenticate {
                my ($self, $username, $password) = @_;
                if (my $member = db->single('members', { username => $username, password => $password }) {
                        self->member($member);
                        self->login;
                        return TRUE;
                }
            return false;
        }

        sub login {
                c->refresh_session;
                session->param(member => {
                        id           => self->member->id,
                        email        => self->member->email,
                        nickname     => self->member->nickname,
                });
                session->flush;
        }

        sub logout {
                session->param(member => {});
                session->flush;
                return true;
        }

        1;

## アプリケーションクラス

App (based on Dwarf) = アプリケーションクラス + コンテキストクラス + ディスパッチャークラス<br />
<br />
コントローラやモデルに渡される $c はコンテキストオブジェクトであるが、Dwarf の場合はアプリケーションクラスでもある。設計的にはあまり美しくないが、フレームワークの実装をシンプルにするためにこのようになっている。<br />

### 設定ファイルの読み込み

手元の開発環境で動かす場合など複数の環境で動かすことを想定して、環境毎に違う設定ファイルを読み込むことが出来ます。<br />

- production というキーに本番用の設定ファイル名を渡します。
- development というキーに開発用の設定ついての配列リファレンスを渡します。
- 配列リファレンスには、設定ファイル名をキーに、環境の定義を値にしたハッシュを渡します。
- 上から順に操作していき、最初にマッチした環境の設定ファイルが適用されます。

環境の定義にはホスト名にマッチさせたい文字列か、環境を定義したハッシュリファレンスを指定します。<br />

        $self->load_plugins(
                'MultiConfig' => {
                        production  => 'Production',
                        development => [
                                'Staging'     => {
                                        host => 'hello_world.s2factory.co.jp', # ホスト名
                                        dir  => '/proj/www/hello_world_stg'    # アプリケーションディレクトリの位置
                                },
                                'Development' => 'hello_world.s2factory.co.jp',
                                'Seagirl'     => 'seagirl.local',
                        ],
                },
        );

### 処理の流れ

- 1. BEFORE\_DISPATCH トリガーの実行 (Dwarf はなにもしない)
- 2. Router::Simple を使ってコントローラとメソッドを探索
- 3. コントローラの生成
- 4. メソッドを実行
- 5. AFTER\_DISPATCH トリガーの実行 (decode\_json などが行われる)
- 6. ファイナライズ処理 ($self->response->finalize)

### プロパティ

        ro => [qw/namespace base_dir env config error request response router handler handler_class models state is_production is_cli/],
        rw => [qw/stash request_handler_prefix request_handler_method/],

### ショートカット

        param  (= $self->request->param)
        conf   (= $self->config->get / $self->config->set)
        req    (= $self->request)
        method (= $self->request->method)
        res    (= $self->response)
        status (= $self->response->status)
        type   (= $self->response->content_type)
        body   (= $self->response->body)

### メソッド

#### dump

Data::Dumper->Dump([@_]) のラッパー

#### to\_psgi

PSGI アプリケーションを返します。

#### finish ($self, $body)

直ちにレスポンスを返します。

#### redirect

直ちにリダイレクトします。

#### not\_found

直ちに 404 Not Found を返します。

#### unauthorized

直ちに 401 UNAUTHORIZED を返します。

#### load\_plugins ($self, %args)

プラグインを読み込みます。

## リクエストとレスポンス

### Dwarf::Request

Dwarf::Request は Plack::Request のラッパーです。<br/>
Plack::Request との違いは以下の通りです。

- リストコンテキストで param メソッドを呼んでも必ずスカラー値が返る
- 全てのパラメータが decode_utf8 される
- 配列型のサポート (param メソッドが配列リファレンスを返す)

### 配列型のサポート

\[\] を使ったパラメーター名を用いることで、配列型をサポートすることが出来ます。

    # hoge[]=1&hoge[]=2&hoge[]=3
    my $array = param('hoge[]'); # $array is [1, 2, 3]

### Dwarf::Response

Dwarf::Response は Plack::Response のラッパーです。

## フォームバリデーション

Dwarf::Validator は FormValidator::Lite に似たモジュールです。<br />
FormValidator::Lite との違いは以下の通りです。

- エラーメッセージ周りの機能を削除
- NOT_NULL と NOT_BLANK の差別化
- フィルター機能の強化

### エラーメッセージ周りの機能を削除

Dwarf ではエラーメッセージは HTML テンプレートに埋め込むスタイルを取るため、エラーメッセージ関連の機能はありません。

### NOT_NULL と NOT_BLANK の差別化

- NOT_NULL … undef のみ不可 (空文字を許可)
- NOT_BLANK … undef も空文字も不可

### フィルター機能の強化

デフォルトで以下のフィルターが実装されています。

- DEFAULT
- TRIM
- DECODE_UTF8
- ENCODE_UTF8
- NLE (Normalize Line Encodings)

```
self->validate(
    'offset' => [[DEFAULT => 0], qw/NOT_NULL UINT/],
    'limit'  => [[DEFAULT => 100], qw/NOT_NULL UINT/, [qw/BETWEEN 0 5000/]],
);

db->search(‘posts’, {}, { offset => param(‘offset’), limit => param(‘limit') });
```

また、FormValidator::Lite::Constraints の rule 関数と同じ感じで filter 関数を使って簡単にカスタムフィルターを定義出来ます。

    filter DEFAULT => sub {
        my ($value, $args, $opts) = @_;
        unless ($value) {
            $value = $args->[0];
        }
        $value;
    };

## メソッドの引数バリデーション

Dwarf::Module では Data::Validator を使った引数のバリデーションを簡単に記述することができます。
Data::Validator の書式に加え、文字列で型を書くスタイルもサポートされます。

文字列      | バリデーションルール
---------- | --------------------------------------------------
'Str'      | { isa => 'Str' }
'Int? = 0' | { isa => 'Int', optional => 1, default => '0' }

```
sub create_member {
    my $args = args {
        name   => 'Str',
        age    => 'Int',
        gender => 'Int? = 0'
    }, @_;

    ...
}

self->create_member({ name => 'Taro Yamada', age => 35 });
```

## JSON バリデーション

validate_json_body を使って POST された JSON データのバリデーションが行えます。
バリデーションルールの定義の仕方はメソッドの引数バリデーションと同じです。

```
after will_dispatch => sub {
    self->validate(
        id => [qw/NOT_BLANK UINT/],
    );

    self->validate_json_body(
        name => 'Str',
        tel  => 'JTel',
    );
};
```

#### 複雑なオブジェクトをバリデーションする例

rules というキーにルールを渡すことで、HashRef や ArrayRef[HashRef] に関するバリデーションルールを記述することができます。
これによって、複雑なオブジェクトをバリデーションすることが出来ます。

```
sub ITEM_TYPE {
    return {
        id        => 'Int',
        code      => 'Int',
        name      => 'Str',
        name_kana => 'Str',
    };
}

sub ITEM_TYPE_TYPE {
    return {
        id     => 'Int',
        name   => 'Str',
        gender => 'Int',
    };
}

sub TEXTURE_TYPE {
    return {
        id              => 'Int',
        code            => 'Str',
        maker           => 'Int',
        price1          => 'Int?',
        price2          => 'Int?',
        price3          => 'Int?',
    };
}

sub ORDER_ITEM_TYPE {
    return {
        id        => 'Int',
        quantity  => 'Int',
        item      => { isa => 'HashRef', rules => ITEM_TYPE() },
        item_type => { isa => 'HashRef', rules => ITEM_TYPE_TYPE() },
        texture   => { isa => 'HashRef', rules => TEXTURE_TYPE() },
    };
}

after will_dispatch => sub {
    self->validate_json_body(
        order_items => { isa => 'ArrayRef[HashRef]', rules => ORDER_ITEM_TYPE() }
    );
};
```

#### 独自型の実装例は Dwarf::Plugin::MouseX::Types::Common

```
subtype URL
    => as 'Str'
    => where { $_ =~ /($RE{URI}{HTTP}{-scheme =>'(https|http)'})/o };

subtype Email
    => as 'Str'
    => where { Email::Valid::Loose->address(encode_utf8 $_) };
```

## モジュール

Dwarf::Module はコントローラやモデルの根底クラス。<br />
<br />
Dwarf ではモジュール単位で作業を切り分けるという方針で設計されている。またモジュールを実装することが即ちアプリケーションを実装することになるので、コントローラであろうがモデルであろうがモジュールからは全て同じやり方でフレームワークの情報を参照出来るようになっている。

### プロパティ

#### context

App.pm のインスタンス

### ショートカット

        self          (= $self)
        app           (= $self->context)
        c             (= $self->context)
        m             (= $self->model)
        conf          (= $self->context->config->get / $self->context->config->set)
        db            (= $self->context->db)
        error         (= $self->context->error)
        e             (= $self->context->error)
        env           (= $self->content->env)
        log           (= $self->context->log)
        debug         (= $self->context->log->debug)
        session       (= $self->context->session)
        param         (= $self->context->param)
        parameters    (= $self->context->request->parameters)
        request       (= $self->context->request)
        req           (= $self->context->request)
        method        (= $self->context->request->method)
        response      (= $self->context->response)
        res           (= $self->context->response)
        status        (= $self->context->response->status)
        type          (= $self->context->response->content_type)
        header        (= $self->context->response->header)
        headers       (= $self->context->response->headers)
        body          (= $self->context->response->body)
        not_found     (= $self->context->not_found)
        unauthorized  (= $self->context->unauthorized)
        finish        (= $self->context->finish)
        redirect      (= $self->context->redirect)
        is_cli        (= $self->context->is_cli)
        is_production (= $self->context->is_production)
        load_plugin   (= $self->context->load_plugin)
        load_plugins  (= $self->context->load_plugins)
        render        (= $self->context->render)
        dump          (= $self->context->dump)

use Dwarf::DSL することで上記のシンタックスシュガーを DSL として呼ぶことができます。

### メソッド

#### init ($self, $c)

モジュール作成時に呼び出される初期処理用のテンプレートメソッド

#### model ($self, $package, @\_)

$self->c->models にインスタンスが存在しなければ create\_model を呼んでモデルインスタンスを作成します。

#### create\_model ($self, $package, @\_)

モデルのインスタンスを作成し、モデルクラスの init メソッドを呼びます。
残りの引数はモデルクラスの new に渡されます。
返り値には作成したインスタンスが返ります。

## Dwarf モジュール

### Dwarf::Module::APIBase

API 用のコントローラを実装するためのベースクラス

- validate
- will\_dispatch
- will\_render
- did\_render
- receive\_error
- receive\_server\_error

### Dwarf::Module::HTMLBase

Web ページ用のコントローラを実装するためのベースクラス

- validate
- will\_dispatch
- will\_render
- did\_render
- receive\_error
- receive\_server\_error

### Dwarf::Module::CLIBase

CLI 用のコントローラを実装するためのベースクラス

- receive\_error
- receive\_server\_error

### Dwarf::Module::SocialMedia::Twitter

### Dwarf::Module::SocialMedia::Faceboo

### Dwarf::Module::SocialMedia::Mixi

### Dwarf::Module::SocialMedia::Weibo

Twitter/Facebook/Mixi/Weibo 各種 API を扱うためのクラス

## テスト

App::Test を使ってコントローラーのテストを書くことが出来ます。

```
use App::Test;

my $t = App::Test->new(will_decode_content => 1);
my $c = $t->context;

my ($req, $res);

($req, $res) = $t->req_ok(GET => "http://localhost/api/posts");

($req, $res) = $t->req_ok(POST => "http://localhost/api/posts", {
    name => "Takuho Yoshizu",
});

($req, $res) = $t->req_ok( 
    POST         => "http://localhost/api/images", 
    Content_Type => 'form-data',
    Content      => {
        'image[]' => [ $c->base_dir . '/t/03_app/file/image.jpg' ]
    }
);
```

## エラー

Dwarf では 2 種類のエラーを扱うことが出来ます。

- Dwarf のエラー (ERROR)
- Perl のエラー (SERVER\_ERROR)

## Dwarf::Error

Dwarf::Error は Dwarf のエラーを取り扱うためのクラスです。
Dwarf::Error は複数の Dwarf::Message::Error を保持することが出来ます。

### プロパティ

#### autoflush

このフラグを true にすると throw が呼ばれた時に自動的に flush が呼ばれます。
デフォルトは false。

#### messages

Dwarf::Message::Error オブジェクトの配列です。

### メソッド

#### throw

エラーメッセージを作成し、エラーを送出します。
autoflush が true な場合は、flush を呼び出します。

#### flush

送出されたエラーメッセージを実際にフレームワークに出力します。

## Dwarf::Message::Error

Dwarf のエラー個々の内容を示すクラスです。

### プロパティ

#### data

エラーデータを格納する配列リファレンスです。
Dwarf::Error の flush メソッドに渡された引数がそのまま data に渡されます。

        my $m = Dwarf::Message::Error->new;
        $m->data([@_]);

## エラーの送出

Dwarf のエラーを出力するには、Error クラスの throw メソッドを使用します。

        $c->error->throw(400,  "Something wrong.");

Dwarf::Plubin::Error を読み込むことでエラークラスにショートカットを作成することが出来ます。

        $c->load_plugins(
                'Error' => {
                        LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
                        INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
                        NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
                        SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
                        SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
                        ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
                }
        );

モジュールの中で実際に呼び出す場合には、書きのようになります。

        e->LACK_OF_PARAM('user_id'); # $c->error->LACK_OF_PARAM('user_id');

## エラーハンドリング

二つのエラーに対応するトリガーを登録することでをエラーをハンドリングすることが出来ます。

        $c->add_trigger(ERROR => sub { warn @_ });
        $c->add_trigger(SERVER_ERROR => sub { warn @_ };

トリガーが一つも登録されていない場合は、Dwarf.pm の receive\_error メソッドおよび receive\_server\_error メソッドが呼び出されます。

        sub receive_error { die $_[1] }
        sub receive_server_error { die $_[1] }

## APIBase.pm のバリデーションとエラーハンドリング

APIBase の validate メソッドは FormValidator::Lite の check メソッドのラッパーになっており、バリデーションエラーを検知した場合に Dwarf のエラーを送出します。また、APIBase では Dwarf::Error の autoflush を true にセットするため、エラーが送出されるとただちに receive\_error メソッドに処理が移ります。

        sub validate {
                my ($self, @rules) = @_;
                return unless @rules;

                my $validator = S2Factory::Validator->new($self->c->req)->check(@rules);
                if ($validator->has_error) {
                        while (my ($param, $detail) = each %{ $validator->errors }) {
                                $self->c->error->LACK_OF_PARAM($param) if $detail->{NOT_NULL};
                                $self->c->error->INVALID_PARAM($param);
                        }
                }
        }

APIBase ではエラーハンドリング用のトリガーがあらかじめ登録されています。サブクラスで下記のメソッドをオーバライドすることで振る舞いを変えることが出来ます。

        # 400 系のエラー
        sub receive_error {
                my ($self, $c, $error) = @_;
                my (@codes, @messages);

                for my $m (@{ $error->messages }) {
                        warn sprintf "API Error: code = %s, message = %s", $m->data->[0], $m->data->[1];
                        push @codes, $m->data->[0];
                        push @messages, $m->data->[1];
                }

                my $data = {
                        error_code    => @codes == 1 ? $codes[0] : \@codes,
                        error_message => @messages == 1 ? $messages[0] : \@messages,
                };

                return $data;
        }

        # 500 系のエラー
        sub receive_server_error {
                my ($self, $c, $error) = @_;

                $error ||= 'Internal Server Error';

                my $data = {
                        error_code    => 500,
                        error_message => $error,
                };

                return $data;
        }

## HTMLBase.pm のバリデーションとエラーハンドリング

HTMLBase の validate メソッドは FormValidator::Lite の check メソッドのラッパーになっており、バリデーションエラーを検知した場合に Dwarf のエラーを送出します。また、HTMLBase では Dwarf::Error の autoflush を false にセットするため、エラーが送出されても flush メソッドが呼ばれるまで receive\_error メソッドに処理が移りません。HTMLBase では will\_dispatch メソッドの実行後に flush メソッドを呼び出します。そのため、コントローラの実装時には will\_dispatch メソッドの中でバリデーションを行います。

        sub validate {
                my ($self, @rules) = @_;
                return unless @rules;
                my $validator = S2Factory::Validator->new($self->req)->check(@rules);
                if ($validator->has_error) {
                        while (my ($param, $detail) = each %{ $validator->errors }) {
                                $self->error->LACK_OF_PARAM($param, $detail) if $detail->{NOT_NULL};
                                $self->error->INVALID_PARAM($param, $detail);
                        }
                }
        }

HTMLBase ではエラーハンドリング用のトリガーがあらかじめ登録されています。サブクラスで下記のメソッドをオーバライドすることで振る舞いを変えることが出来ます。

        # 400 系のエラー
        sub receive_error {
                my ($self, $c, $error) = @_;

                $self->{error_template} ||= '400.html';
                $self->{error_vars}     ||= $self->req->parameters->as_hashref;

                for my $message (@{ $error->messages }) {
                        my $code   = $message->data->[0];
                        my $param  = $message->data->[1];
                        my $detail = $message->data->[2];

                        $self->{error_vars}->{error}->{$param} = merge_hash(
                                $self->{error_vars}->{error}->{$param},
                                $detail
                        );
                }

                return $c->render($self->error_template, $self->error_vars);
        }

        # 500 系のエラー
        sub receive_server_error {
                my ($self, $c, $error) = @_;
                $self->{server_error_template}    ||= '500.html';
                $self->{server_error_vars} ||= { error => $error };
                return $c->render($self->server_error_template, $self->server_error_vars);
        }

WEB ページ実装時のバリデーションとエラーハンドリングの例

        package App::Controller::Web::Login;
        use Dwarf::Pragma;
        use parent 'App::Controller::WebBase';
        use Dwarf::DSL;
        use Class::Method::Modifiers;

        # バリデーションの実装例。validate は何度でも呼べる。
        # will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
        sub will_dispatch  {
                if (method eq 'POST') {
                        self->validate(
                                user_id  => [qw/NOT_NULL UINT/, [qw/BETWEEN 1 8/]],
                                password => [qw/NOT_NULL UINT/, [qw/BETWEEN 1 8/]],
                        );
                }
        };

        # バリデーションがエラーになった時に呼び出される（定義元: Dwarf::Module::HTMLBase）
        # エラー表示に使うテンプレートと値を変更したい時はこのメソッドで実装する
        # バリデーションのエラー理由は、self->error_vars->{error}->{PARAM_NAME} にハッシュリファレンスで格納される
        before receive_error => sub {
                self->{error_template} = 'login.html';
                self->{error_vars} = parameters->as_hashref;
        };

        sub get {
                render('login.html');
        }

        sub post {
                my $user_id = param('user_id');
                my $password = param('password')

                if (model('Auth')->authenticate($user_id, $password)) {
                        model('Auth')->login;
                        redirect '/';
                }

                e->INVALID_PARAM(user_id => "INVALID");
                e->INVALID_PARAM(password => "INVALID");
                e->flush;
        }

        1;

エラー画面の例

    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>400 Bad Request</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="description" content="">
        <meta name="author" content="">

        <!-- Le styles -->
        <link href="/dwarf/bootstrap/css/bootstrap.css" rel="stylesheet">
        <style>
            body {
            padding-top: 60px; /* 60px to make the container go all the way to the bottom of the topbar */
            }
        </style>
        <link href="/dwarf/bootstrap/css/bootstrap-responsive.css" rel="stylesheet">
    </head>

    <body>
        <div class="container">

        <h1>400 Bad Request</h1>
    : if $error {
        <!-- error messages -->
        <dl class="alert">
            <dt>入力内容に不備がありました。</dt>
            <dd>
                <ul>
    : if $error.category.UINT {
                    <li>種別は必須項目です。選択してください。</li>
    : }
    : if $error.name.NOT_NULL {
                    <li>商品名・邸名は必須項目です。入力してください。</li>
    : }
    : if $error.introduction.NOT_NULL {
                    <li>紹介文は必須項目です。入力してください。</li>
    : }
                </ul>
            </dd>
        </dl>
    : }

        </div> <!-- /container -->
    </body>
    </html>

## Dwarf::Pragma

use すると基本的なプラグマをまとめてセットするショートカットの役割をするクラスです。

        use strict;
        use warnings;
        use utf8;
        use feature '5.10';
        use boolean;

オプションで utf8 と feature の挙動は変更することが出来ます。

        sub import {
                my ($class, %args) = @_;

                $utf8 = 1 unless defined $args{utf8};
                $feature = "5.10" unless defined $args{feature};

                warnings->import;
                strict->import;
                boolean->import;
                boolean->export_to_level(1);

                if ($utf8) {
                        utf8->import;
                }

                if ($feature ne 'legacy') {
                        require 'feature.pm';
                        feature->import(":" . $feature);
                }
        }

## Dwarf::Accessor

アクセサを作成するためのクラスです。

### Lazy Initialization

「\_build\_ + プロパティ名」というメソッドを実装することで、初期値を遅延生成することが出来ます。

        use Dwarf::Accessor qw/json/;

        sub _build_json {
                my $json = JSON->new();
                $json->pretty(1);
                $json->utf8;
                return $json;
        }

## Dwarf::Message

ディスパッチ処理の中で送出可能なメッセージクラス。主にフレームワークがエラーハンドリングなどに利用している。not\_found メソッドや redirect メソッドが利用している finish メソッドの実装にもディスパッチパッチを直ちに終了する目的で使われている。

## Dwarf::Trigger

トリガークラス。Dwarf が提供しているトリガーは BEFORE\_DISPATCH / AFTER\_DISPATCH / ERROR / SERVER\_ERROR の四種類。また、Dwarf::Plugin::Text::Xslate などのプラグインは読み込まれると BEFORE\_RENDER / AFTER\_RENDER の二種類のトリガーを提供する。APIBase.pm や HTMLBase.pm はこれらのトリガーを実装するためのメソッドをあらかじめ用意してあり、サブクラスで実際にメソッドが実装されるとコールされる仕組みになっている。

        $c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
        $c->add_trigger(AFTER_RENDER => $self->can('did_render'));
        $c->add_trigger(ERROR => $self->can('receive_error'));
        $c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

## Dwarf::Util

ユーティリティクラス。以下のメソッドが @EXPORT\_OK である。

### メソッド

#### add\_method

#### load\_class

#### installed

#### capitalize

#### shuffle\_array

#### filename

#### read\_file

#### write\_file

#### get\_suffix

#### safe\_join

#### merge\_hash

#### encode\_utf8

#### decode\_utf8

#### encode\_utf8\_recursively

#### decode\_utf8\_recursively

# LICENSE

Copyright (C) Takuho Yoshizu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuho Yoshizu <yoshizu@s2factory.co.jp>
