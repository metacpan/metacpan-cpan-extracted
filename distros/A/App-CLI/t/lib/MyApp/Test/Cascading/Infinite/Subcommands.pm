package MyApp::Test::Cascading::Infinite::Subcommands;
use base qw(App::CLI::Command);
use CLITest;

use constant options => (
    "h|help" => "help",
    "name=s" => "name",
);

sub run {
  my $self = shift;
  cliack($self->{name}, $self->{help} ? "help" : "");
}


1;
