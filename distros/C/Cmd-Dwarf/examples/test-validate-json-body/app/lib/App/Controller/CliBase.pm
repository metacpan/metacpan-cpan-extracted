package App::Controller::CliBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::CLIBase';
use Dwarf::DSL;

# バリデーションエラー時に直ちにエラーを送出するかどうか
sub _build_autoflush_validation_error { 1 }

sub init_plugins {
	
}

sub will_dispatch {
}

1;

