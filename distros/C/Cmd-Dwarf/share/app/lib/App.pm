package App;
use Dwarf::Pragma;
use parent 'Dwarf';
use Class::Method::Modifiers;
use App::Constant;

sub setup {
	my $self = shift;

	umask 002;

	$self->load_plugins(
		'MultiConfig' => {
			production  => 'Production',
			development => [
				'Development' => '<APP_NAME>',
				'DevYoshizu'  => 'seagirl|yoshizu|tak|sb106|sb245|sb191',
			],
		},
 	);

	$self->load_plugins(
		'Teng'          => undef,
		'Log::Dispatch' => undef,
	);

	$self->load_plugins(
		'URL'     => undef,
		'Now'     => { time_zone => 'Asia/Tokyo' },
		'Runtime' => {
			cli    => 0,
			ignore => 'Production'
		},
	);
}

# デフォルトのルーティングに追加したい場合はルーティングを記述する
before add_routes => sub {
	my $self = shift;
# 	# eg) name notation を使いたい場合の書き方 (パラメータ user_id に値が渡る)
# 	# $self->router->connect("/images/detail/:user_id", { controller => "Web::Images::Detail" });
};

1;
