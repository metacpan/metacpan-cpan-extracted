package App::Controller::Web;
use Dwarf::Pragma;
use parent 'App::Controller::WebBase';
use Dwarf::DSL;
use Class::Method::Modifiers;

# バリデーションの実装例。validate は何度でも呼べる。
# will_dispatch 終了時にエラーがあれば receive_error が呼び出される。
after will_dispatch => sub {
	self->validate(
		user_id  => [[DEFAULT => 1], qw/NOT_NULL UINT/, [qw/BETWEEN 1 8/]],
		password => [[DEFAULT => 2], qw/NOT_NULL UINT/, [qw/BETWEEN 1 8/]],
	);
};

# バリデーションがエラーになった時に呼び出される（定義元: Dwarf::Module::HTMLBase）
# エラー表示に使うテンプレートと値を変更したい時はこのメソッドで実装する
# バリデーションのエラー理由は、self->error_vars->{error}->{PARAM_NAME} にハッシュリファレンスで格納される
# before receive_error => sub {
#	self->{error_template} = 'index.html';
#	self->{error_vars} = parameters->as_hashref;
# };

sub get {
	return render('index.html');
}

1;
