use App::Test;
use utf8;

my $t = App::Test->new;
my $c = $t->context;
my $m = $t->context->model('Email');

# render メソッドが必要
$c->load_plugin('Text::Xslate', {
	path => $c->base_dir,
});

# テストの度にメールが飛ばないようにする
my $transport = 'DevNull';

subtest "send" => sub {
	ok !$m->send({
		transport    => $transport,
		from         => 'yoshizu+dwarf@s2factory.co.jp',
		envelop_from => 'yoshizu+dwarf@s2factory.co.jp',
		reply_to     => 'yoshizu+dwarf@s2factory.co.jp',
		to           => 'yoshizu+dwarf1@s2factory.co.jp, yoshizu+dwarf2@s2factory.co.jp',
		subject      => 'Dwarf テストメール',
		body         => "Dwarf メールのテストです。\n\nほげほげ。\n",
	});
};

subtest "send dot" => sub {
	ok !$m->send({
		transport    => $transport,
		from         => 'yoshizu+dwarf@s2factory.co.jp',
		envelop_from => 'yoshizu+dwarf@s2factory.co.jp',
		reply_to     => 'yoshizu+dwarf@s2factory.co.jp',
		to           => 'yoshizu+dwarf1...@s2factory.co.jp',
		subject      => 'Dwarf テストメール',
		body         => "Dwarf メールのテストです。\n\nほげほげ。\n",
	});
};

subtest "send_file" => sub {
	ok !$m->send_file(
		{
			transport    => $transport,
			from         => 'yoshizu+dwarf@s2factory.co.jp',
			envelop_from => 'yoshizu+dwarf@s2factory.co.jp',
			reply_to     => 'yoshizu+dwarf@s2factory.co.jp',
			to           => 'yoshizu+dwarf1@s2factory.co.jp, yoshizu+dwarf2@s2factory.co.jp',
			subject      => 'Dwarf テストメール',
		},
		"t/02_model/file/email.txt",
		{
			hoge => "ほげほげ",
		}
	);
};

done_testing;
