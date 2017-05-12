package CohortExplorer::Command::Menu;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw( CLI::Framework::Command::Menu );

#-------
sub menu_txt {
 my ($self) = @_;
 my $app = $self->get_app;
 my ( @cmd, $txt );

 # Get all valid commands
 for my $c ( $app->get_interactive_commands ) {
  if ( grep ( $_ ne $c, $app->noninteractive_commands ) ) {
   push @cmd, $c;
  }
 }
 my %aliases = reverse $app->command_alias;

 # Create menu txt which contains all valid commands with their aliases
 for (@cmd) {
  $txt .= sprintf( "%-5s%2s%10s\n", $aliases{$_}, '-', $_ );
 }
 return "\n\n" . $txt . "\n\n";
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Command::Menu - CohortExplorer class to show a command menu including the commands that are available to the running application

=head1 DESCRIPTION

This class is inherited from L<CLI::Framework::Command::Menu> and overrides C<menu_txt()>.

=head2 menu_txt()

This method creates a command menu including the commands that are available to the running application. Only a small modification has been made to the original code so the menu includes command aliases with command names.

=cut
