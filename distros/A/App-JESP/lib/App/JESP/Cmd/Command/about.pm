package App::JESP::Cmd::Command::about;
$App::JESP::Cmd::Command::about::VERSION = '0.010';
use base qw/App::JESP::Cmd::Command/;
use strict; use warnings;
use Log::Any qw/$log/;

=head1 NAME

App::JESP::Cmd::Command::about - Simple about command

=cut

=head2 abstract

=head2 description

=head2 execute

See L<App::Cmd>

=cut

sub abstract { "About this software" }
sub description { "About this software" }
sub execute {
    my ($self, $opt, $args) = @_;
    $log->info("This is App::JESP version ". ( $App::JESP::Cmd::VERSION || '-DEVELOPMENT-' ) );
    $log->info("Project homepage: https://github.com/jeteve/App-JESP");
}

1;
