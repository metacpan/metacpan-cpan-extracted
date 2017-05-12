package CohortExplorer::Command::History;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw(CLI::Framework::Command);
use CLI::Framework::Exceptions qw( :all );
use CohortExplorer::Command::Query qw($COMMAND_HISTORY);

#-------
sub usage_text {
 q{
    history [--show|s] [--clear|c] : show saved commands
  };
}

sub option_spec {
 (
   [],
   [ 'show|s'  => 'show command history' ],
   [ 'clear|c' => 'clear command history' ], 
   []
 );
}

sub validate {
 my ( $self, $opts, @args ) = @_;
 if (@args) {
  throw_cmd_validation_exception(
                     error => 'No arguments are required to run this command' );
 }
 if ( $opts->{show} && $opts->{clear} ) {
  throw_cmd_validation_exception( error =>
         'Mutually exclusive options (show and clear) are specified together' );
 }
}

sub run {
 my ( $self, $opts, @args ) = @_;
 my ( $ds_name, $verbose ) = @{ $self->cache->get('cache') }{qw/datasource_name verbose/};
 my @saved_commands = sort { $a <=> $b } keys %{ $COMMAND_HISTORY->{datasource}{$ds_name} };

 # Show all saved commands for the current datasource along with datetime
 if ( $opts->{show} && @saved_commands ) {
  push my @rows, [qw/command_no datetime command/];
  for (@saved_commands) {
   push @rows,
     [
       $_,
       @{ $COMMAND_HISTORY->{datasource}{$ds_name}{$_} }{qw/datetime command/}
     ];
  }
  
  print STDERR "\nRendering command history ...\n\n" if $verbose;
  
  return {
           headingText => 'command history',
           rows        => \@rows
  };
 }

 # Clears the command history for the current datasource
 delete $COMMAND_HISTORY->{datasource}{$ds_name} if $opts->{clear};
 return;
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Command::History - CohortExplorer class to print command history

=head1 SYNOPSIS

B<history [OPTIONS]>

B<hist [OPTIONS]>

=head1 DESCRIPTION

This class is inherited from L<CLI::Framework::Command> and overrides the following methods:

=head2 usage_text()

This method returns the usage information for the command.

=head2 option_spec() 

  (  
     [ 'show|s'  => 'show command history'  ],
     [ 'clear|c' => 'clear command history' ] 
  )

=head2 validate( $opts, @args )

This method throws C<throw_cmd_validation_exception> exception imported from L<CLI::Framework::Exceptions> if

=over

=item *

arguments are supplied to this command because this command does not accept any arguments, or

=item *

mutually exclusive options (i.e. show and clear) are specified together

=back

=head2 run( $opts, @args )

This method performs option specific processing.

This class imports the variable C<$COMMAND_HISTORY> from L<CohortExplorer::Command::Query> to load user's saved commands. The history command enables the user to keep track of previously saved commands and use the information such as options and arguments to build new commands.

=head1 OPTIONS

=over

=item B<-s>, B<--show>

Show history

=item B<-c>, B<--clear>

Clear history

=back

=head1 DEPENDENCIES

L<CLI::Framework::Command>

L<CLI::Framework::Exceptions>

L<Exception::Class::TryCatch>

=head1 SEE ALSO

L<CohortExplorer>

L<CohortExplorer::Datasource>

L<CohortExplorer::Command::Describe>

L<CohortExplorer::Command::Find>

L<CohortExplorer::Command::Query::Search>

L<CohortExplorer::Command::Query::Compare>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2014 Abhishek Dixit (adixit@cpan.org). All rights reserved.

This program is free software: you can redistribute it and/or modify it under the terms of either:

=over

=item *
the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version, or

=item *
the "Artistic Licence".

=back

=head1 AUTHOR

Abhishek Dixit

=cut
