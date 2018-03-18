package App::Config::DevDocker;
use Dwarf::Pragma;
use parent 'App::Config::Development';

sub setup {
	my $self = shift;
	return (
		$self->SUPER::setup,
		ssl => 0,
		url => {
			base     => 'http://localhost:5000',
			ssl_base => 'https://localhost:5000',
		},
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=postgres; host=db; port=5432',
				username => 'postgres',
				password => 'postgres',
				opts     => { pg_enable_utf8 => 1 },
			},
		},
	);
}

1;

