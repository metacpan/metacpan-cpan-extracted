package App::Controller::Cli::Ping;
use Dwarf::Pragma;
use parent 'App::Controller::CliBase';
use Dwarf::DSL;

sub any {
	return 'It works on ' . c->hostname . ':' . c->base_dir . ' (' . c->config_name. ')';
}

1;

