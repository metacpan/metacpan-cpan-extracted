package App::Config::Production;
use Dwarf::Pragma;
use parent 'Dwarf::Config';

sub setup {
	my $self = shift;
	return (
		ssl => 1,
		url => {
			base      => 'http://<APP_NAME>.com',
			ssl_base  => 'https://<APP_NAME>.com',
		},
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=<APP_NAME>',
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
				name  => '<APP_NAME>_sid',
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

