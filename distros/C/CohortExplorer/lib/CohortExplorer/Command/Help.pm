package CohortExplorer::Command::Help;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw( CLI::Framework::Command::Meta );


#-------
sub usage_text {
 q{
     help [command]: application or command specific usage
  };
}

sub run {
 my ( $self, $opts, @args ) = @_;

 # Metacommand is app-aware
 my $app = $self->get_app;
 my $usage;
 my $command_name = shift @args;

 # Recognise help requests that refer to the target command by an alias
 my %alias = $app->command_alias;
 $command_name = $alias{$command_name} if $command_name && exists $alias{$command_name};
 my $h = $app->command_map_hashref;

 # First, attempt to get command-specific usage
 if ($command_name) {

  # (do not show command-specific usage message for non-interactive
  # commands when in interactive mode)
  $usage = $app->usage( $command_name, @args )
    unless ( $app->get_interactivity_mode
             && !$app->is_interactive_command($command_name) );
 }
 my $app_usage = $app->usage;

 # Remove usage of invalid/noninteractive commands from application help
 for ( $app->noninteractive_commands ) {
  if (
      (
       $_ =~ /^(?:search|compare|history)$/ && !$app->is_interactive_command($_)
      )
      || ( $_ =~ /^(?:menu|console)$/ && $app->get_interactivity_mode )
    )
  {
   $app_usage =~ s/\n\s+$_\s+\-[^\n]+//;
  }
 }

 # Fall back to application usage message
 $usage ||= $app_usage;
 return $usage;
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Command::Help - CohortExplorer class to print application or command specific usage

=head1 DESCRIPTION

This class is inherited from L<CLI::Framework::Command::Meta> and overrides the methods below:

=head2 usage_text()

This method returns the usage information for the help command.

=head2 run( $opts, @args )

The method returns application or command specific usage. Only a small modification has been made to the original code so the application usage only includes the usage information on valid commands.

=cut
