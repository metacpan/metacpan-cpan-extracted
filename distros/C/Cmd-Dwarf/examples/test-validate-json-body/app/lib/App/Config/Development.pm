package App::Config::Development;
use Dwarf::Pragma;
use parent 'Dwarf::Config';

sub setup {
	my $self = shift;
	return (
		ssl => 1,
		url => {
			base     => 'http://test.s2factory.co.jp',
			ssl_base => 'https://test.s2factory.co.jp',
		},
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=test',
				username => 'www',
				password => '',
				opts     => { pg_enable_utf8 => 1 },
			},
		},
		session => {
			store => {
				table => 'sessions',
			},
			state => {
				name  => 'test_sid',
			},
		},
		filestore => {
			private => {
				dir => $self->c->base_dir . "/filestore",
				uri => "/filestore",
			},
			public  => {
				dir => $self->c->base_dir . "/../htdocs/filestore",
				uri => "/filestore",
			},
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

