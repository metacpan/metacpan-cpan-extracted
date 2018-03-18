package Dwarf::Test::Config::Production;
use Dwarf::Pragma;
use parent 'Dwarf::Config';

sub setup {
	my $self = shift;
	return (
		ssl => 1,
		url => {
			base      => 'http://dwarf.com',
			ssl_base  => 'https://dwarf.com',
		},
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=dwarf',
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
				name  => 'dwarf_sid',
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

