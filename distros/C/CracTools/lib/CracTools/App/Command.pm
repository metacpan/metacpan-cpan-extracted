package CracTools::App::Command;

{
  $CracTools::App::Command::DIST = 'CracTools';
}
# ABSTRACT: base class for cractools commands
$CracTools::App::Command::VERSION = '1.251';
use App::Cmd::Setup -command;

#sub opt_spec {
#  my ( $class, $app ) = @_;
#  return (
#    [ 'help' => "this usage screen" ],
#    $class->options($app),
#  )
#}
#
#sub validate_args {
#  my ( $self, $opt, $args ) = @_;
#  if ( $opt->{help} ) {
#    my ($command) = $self->command_names;
#    $self->app->execute_command(
#      $self->app->prepare_command("help", $command)
#    );
#    exit;
#  }
#  $self->validate( $opt, $args );
#}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::App::Command - base class for cractools commands

=head1 VERSION

version 1.251

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
