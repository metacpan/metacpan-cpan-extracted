package App::JESP::Cmd::Command::deploy;
$App::JESP::Cmd::Command::deploy::VERSION = '0.008';
use base qw/App::JESP::Cmd::CommandJESP/;
use strict; use warnings;
use Log::Any qw/$log/;

=head1 NAME

App::JESP::Cmd::Command::deploy - Deploy Database patches in the DB

=cut

=head2 options

See superclass L<App::JESP::Cmd::CommandJESP>

=head2 abstract

=head2 description

=head2 execute

See L<App::Cmd>

=cut

sub options{
    my ($class, $app) = @_;
    return (
        [ 'force' => 'For application of patches' ],
        [ 'logonly' => 'Only log patches deployment. Do not execute them' ],
        [ 'patches=s@' => 'Only apply these patche in the order defined. Example: --patches mypatch1 --patches mypatch2' ]
    );
}


sub abstract { "Deploy patches from <home>/plan.json in the DB" }
sub description { "Deploys patches from <home>/plan.json in the DB and records their applications in the Meta tables" }
sub execute {
    my ($self, $opts, $args) = @_;
    $self->jesp->deploy( $opts );
}

1;
