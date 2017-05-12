package App::JESP::Cmd::Command::install;
$App::JESP::Cmd::Command::install::VERSION = '0.008';
use base qw/App::JESP::Cmd::CommandJESP/;
use strict; use warnings;
use Log::Any qw/$log/;

=head1 NAME

App::JESP::Cmd::Command::install - Install jesp meta data tables in the target database.

=cut

=head2 abstract

=head2 description

=head2 execute

See L<App::Cmd>

=cut

sub abstract { "Install jesp in DB" }
sub description { "Install jesp's metadata tables in the target database" }
sub execute {
    my ($self, $opt, $args) = @_;
    $self->jesp->install();
}

1;
