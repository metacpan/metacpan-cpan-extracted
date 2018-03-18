package App::Config::DevYoshizu;
use Dwarf::Pragma;
use parent 'App::Config::Development';

sub setup {
	my $self = shift;
	return (
		$self->SUPER::setup,
		ssl => 0,
		url => {
			base     => 'http://example.seagirl.local',
			ssl_base => 'https://example.seagirl.local',
		},
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=example; host=localhost; port=5432',
				username => 'www',
				password => '',
				opts     => { pg_enable_utf8 => 1 },
			},
		},
	);
}

1;

