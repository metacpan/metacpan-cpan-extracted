package App::Config::DevYoshizu;
use Dwarf::Pragma;
use parent 'App::Config::Development';

sub setup {
	my $self = shift;
	return (
		$self->SUPER::setup,
		ssl => 0,
		url => {
			base     => 'http://<APP_NAME>.seagirl.local',
			ssl_base => 'https://<APP_NAME>.seagirl.local',
		},
	);
}

1;

