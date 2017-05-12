package CohortExplorer::Application;

use strict;
use warnings;

our $VERSION = 0.14;

use base qw(CLI::Framework::Application);
use Carp;
use CLI::Framework::Exceptions qw ( :all);
use CohortExplorer::Datasource;
use Exception::Class::TryCatch;
use Term::ReadKey;

#-------
sub usage_text {
 q{
      CohortExplorer

      OPTIONS
         -d  --datasource  : provide datasource
         -u  --username    : provide username
         -p  --password    : provide password

         -v  --verbose     : show with verbosity
         -h  --help        : show usage message and exit
                            

      COMMANDS
          help      - show application or command-specific help
          menu      - show menu of available commands
          console   - start a command console for the application
          describe  - show datasource description including the entity count 
          find      - find variables using keywords 
          search    - search entities with/without conditions on variables
          compare   - compare entities across visits (valid to longitudinal datasources with data on at least 2 visits)
          history   - show saved commands
            
   };
}

sub option_spec {

 # Username, password and datasource name are mandatory options
 # Password may or may not be provided at start
 [],
 [ 'datasource|d:s' => 'provide datasource' ],
 [ 'username|u:s'   => 'provide username' ],
 [ 'password|p:s'   => 'provide password' ],
 [],
 [ 'verbose|v' => 'show with verbosity' ],
 [ 'help|h'    => 'show usage message and exit' ],
 [];
}

sub validate_options {
 my ( $app, $opts ) = @_;

 # Show help and exit
 if ( $opts->{help} || keys %$opts == 0 ) {
  $app->render( $app->get_default_usage );
  exit;
 } else {

  # Throw exception if mandatory options are missing
  if (    !$opts->{datasource}
       || !$opts->{username}
       || !exists $opts->{password} )
  {
   throw_app_opts_validation_exception(
                         error => "All mandatory parameters must be provided" );
  }
 }
}

sub command_map {
 console    => 'CLI::Framework::Command::Console',
   help     => 'CohortExplorer::Command::Help',
   menu     => 'CohortExplorer::Command::Menu',
   describe => 'CohortExplorer::Command::Describe',
   history  => 'CohortExplorer::Command::History',
   find     => 'CohortExplorer::Command::Find',
   search   => 'CohortExplorer::Command::Query::Search',
   compare  => 'CohortExplorer::Command::Query::Compare';
}

sub command_alias {
 h      => 'help',
   m    => 'menu',
   s    => 'search',
   c    => 'compare',
   d    => 'describe',
   hist => 'history',
   f    => 'find',
   sh   => 'console';
}

sub noninteractive_commands {
 my ($app) = @_;
 my $ds = $app->cache->get('cache')->{datasource};

 # May or may not be preloaded
 eval 'require ' . ref $ds;

 # Menu and console commands are invalid under interactive mode
 push my @noninteractive_command, qw/menu console/;

 # search, compare and history commands are invalid if the user
 # does not have access to any variable
 if ( keys %{ $ds->variable_info } == 0 ) {
  push @noninteractive_command, qw/search history compare/;
 }

 # Compare command is invalid only if
 # visit variables are defined
 if ( !$ds->visit_variables ) {
  push @noninteractive_command, 'compare';
 }
 return @noninteractive_command;
}

sub render {
 my ( $app, $output ) = @_;

 # All commands except help return hash where key is headingText (table heading)
 # and value is ref to array of arrays containing column values
 if ( ref $output eq 'HASH' ) {
  require Text::ASCIITable;
  my $t = Text::ASCIITable->new(
                                 {
                                   hide_Lastline => 1,
                                   reportErrors  => 0,
                                   drawRowLine   => 1,
                                   headingText   => $output->{headingText}
                                 }
  );
  my @col = @{ shift @{ $output->{rows} } };
  my $colWidth = $output->{headingText} eq 'command history' ? 1000 : 30;
  $t->setCols(@col);
  for (@col) {
   $t->setColWidth( $_, $colWidth );
  }

  # Prevent truncation by inserting space at every $colWidth character
  for my $r ( @{ $output->{rows} } ) {
   my @row = map {
    substr( $_, ( $colWidth - 1 ), 0 ) = ' '
      if ( $_ && $_ =~ /^[^\n]+$/ && length $_ >= $colWidth );
    $_
   } @$r;
   $t->addRow(@row);
  }
  (
    my $table = $t->draw(
                          [ '', '', '', '' ],
                          [ '', '', '' ],
                          [ '', '', '', '' ],
                          [ '', '', '' ],
                          [ '', '', '', '' ],
                          [ '', '', '', '' ]
    )
  ) =~ s/\|//g;
  if ( $^O eq 'linux' ) {
   delete @ENV{qw(PATH)};
   $ENV{PATH} = "/usr/bin:/bin";
   my $path = $ENV{'PATH'};
   open( my $less, '|-', $ENV{PAGER} || 'less', '-e' )
     or croak "Failed to pipe to pager: $!\n";
   print $less "\n" . $table . "\n";
   close($less);
  } else {
   print "\n" . $table . "\n";
  }
 } else {
  print STDERR $output;
 }
 return;
}

sub handle_exception {
 my ( $app, $e ) = @_;
 my $cache = $app->cache->get('cache');
 if (   !$cache
      || $e->isa('CLI::Framework::Exception::CmdValidationException') )
 {

  # Print command validation errors for the users
  $app->render( $e->description . "\n\n" . $e->error . "\n\n" );
 } else {

  # Print application initialization related errors (source CohortExplorer::Datasource)
  $app->render( $e->description . "\n\n" );
 }

 # Log all other errors
 if ($cache) {
  $cache->{logger}->error( $e->error . ' [ User: ', $cache->{user} . ' ]' );
 }
 return;
}

sub pre_dispatch {
 my ( $app, $command ) = @_;
 my $cache = $app->cache->get('cache');
 my @invalid_command =
   grep ( /^(search|compare|history)$/, $app->noninteractive_commands );
 my $current_command = $app->get_current_command;

 # Don't allow invalid commands to dispatch
 if ( grep( $_ eq $current_command, @invalid_command ) ) {
  throw_invalid_cmd_exception(
                       error => "Invalid command: " . $current_command . "\n" );
 }

 # Log user activity
 $cache->{logger}
   ->info( "Command '$current_command' is run by " . $cache->{user} );
}

sub read_cmd {
 my ($app) = @_;
 require Text::ParseWords;

 # Retrieve or cache Term::ReadLine object (this is necessary to save
 # command-line history in persistent object)
 my $term = $app->{_readline};
 if ( !$term ) {
  require Term::ReadLine;
  $term = Term::ReadLine->new('CohortExplorer');
  select $term->OUT;
  $app->{_readline} = $term;

  # Arrange for command-line completion
  my $attribs = $term->Attribs;
  $term->ornaments(0);
  $attribs->{completion_function} = $app->_cmd_request_completions;
 }

 # Prompt for the name of a command and read input from STDIN
 # Store the individual tokens that are read in @ARGV
 my $command_request =
   $term->readline( $app->cache->get('cache')->{user} . '# ' );
 if ( !defined $command_request ) {

  # Interpret CTRL-D (EOF) as a quit signal
  @ARGV = $app->quit_signals;
  print "\n";    # since EOF character is rendered as ''
 } else {

  # Prepare command for usual parsing
  @ARGV = Text::ParseWords::shellwords($command_request);
  $term->addhistory($command_request)
    if ( $command_request =~ /\S/ and !$term->Features->{autohistory} );
 }
 return 1;
}

sub _cmd_request_completions {
 my ($app) = @_;

 # Valid only when the application is running in console/interactive mode
 return sub {
  my ( $text, $line, $start ) = @_;
  my $ds      = $app->cache->get('cache')->{datasource};
  my $ds_type = $ds->type;

  # Listen to search/compare commands
  if ( $line =~ /^\s*(search|compare|find|history|[scf]|hist)\s+/ ) {
   my $cmd = $1;

   # Make completion work with command aliases
   $cmd = 'search'  if ( $cmd eq 's' );
   $cmd = 'compare' if ( $cmd eq 'c' );
   $cmd = 'find'    if ( $cmd eq 'f' );
   $cmd = 'history' if ( $cmd eq 'hist' );

   # Ensure search/compare/history/find are valid commands
   if ( $app->is_interactive_command($cmd) ) {

    # Listen to options
    if ( $text =~ /^\s*\-/ ) {
     return qw(--show --clear) if ( $cmd eq 'history' );
     return qw(--fuzzy --ignore-case --and)
       if ( $cmd eq 'find' );
     return qw(--out --cond --save-command --stats --export --export-all)
       if ( $cmd =~ /^(search|compare)$/ );
    }
    if ( $cmd =~ /^(?:search|compare)$/
         && substr( $line, 0, $start - 1 ) =~ /(\-o|\-\-out)\s*$/ )
    {
     return File::HomeDir->my_home;
    }
    if ( $cmd =~ /^(?:search|compare)$/
         && substr( $line, 0, $start - 1 ) =~ /(\-e|\-\-export)\s*$/ )
    {
     return keys %{ $ds->table_info };
    }
    if ( $cmd eq 'search'
         && substr( $line, 0, $start - 1 ) =~ /(\-c|\-\-cond)\s*$/ )
    {
     return map { $_ . "='opr, val'" } (
                                         $ds_type eq 'standard'
                                         ? qw(entity_id)
                                         : qw(entity_id visit)
       ),
       keys %{ $ds->variable_info };
    }
    if ( $cmd eq 'compare'
         && substr( $line, 0, $start - 1 ) =~ /(\-c|\-\-cond)\s*$/ )
    {
     return map { $_ . "='opr, val'" } (
                                         qw(entity_id),
                                         keys %{ $ds->variable_info },
                                         @{ $ds->visit_variables || [] }
     );
    }

    # Listen to arguments
    else {
     if ( $cmd eq 'search' ) {
      return keys %{ $ds->variable_info };
     } elsif ( $cmd eq 'find' ) {
      return keys %{ $ds->table_info };
     } elsif ( $cmd eq 'compare' ) {
      return ( keys %{ $ds->variable_info }, @{ $ds->visit_variables || [] } );
     } else {
      return;
     }
    }
   }
  }

  # help command
  return $app->get_interactive_commands if ( $line =~ /^\s*help/ );

  # describe command
  return if $line =~ /^\s*describe/;

  # default
  return $app->get_interactive_commands if ( $line =~ /^\s*/ );
   }
}

sub init {
 my ( $app, $opts ) = @_;
 require Log::Log4perl;
 require File::Spec;
 require File::HomeDir;

 # Path to log configuration file
 my $log_config_file =
   File::Spec->catfile( File::Spec->rootdir, 'etc',
                        'CohortExplorer',    'log-config.properties' );

 # initialize logger
 eval { Log::Log4perl::init($log_config_file); };
 if ( catch my $e ) {
  throw_app_init_exception( error => $e );
 }
 my $logger = Log::Log4perl->get_logger;

 # Check command history file exists and is readable and writable
 my $command_history_file =
   File::Spec->catfile( File::HomeDir->my_home, ".CohortExplorer_History" );
 if ( !-r $command_history_file || !-w $command_history_file ) {
  throw_app_init_exception( error =>
"'$command_history_file' must exist with RW enabled (i.e. chmod 766) for CohortExplorer"
  );
 }

 # Prompt for password if not provided at command line
 if ( !$opts->{password} ) {
  $app->render("Enter password: ");
  ReadMode 'noecho';
  $opts->{password} = ReadLine(300);
  ReadMode 'normal';
  $app->render("\n");
  if ( !$opts->{password} ) {
   $app->render("timeout\n");
   exit;
  }
 }
 chomp $opts->{password};

 # Path to datasource configuration file
 my $ds_config_file =
   File::Spec->catfile( File::Spec->rootdir, 'etc',
                        'CohortExplorer',    'datasource-config.properties' );
 require Text::CSV_XS;

 # Initialize the datasource and store the datasource object along with other bits
 # in cache for further use
 $app->cache->set(
            cache => {
             datasource =>
               CohortExplorer::Datasource->initialize( $opts, $ds_config_file ),
             datasource_name => $opts->{datasource},
             verbose         => $opts->{verbose},
             user            => $opts->{username} . '@' . $opts->{datasource},
             logger          => $logger,
             csv =>
               Text::CSV_XS->new(
                                  {
                                    'quote_char'  => '"',
                                    'escape_char' => '"',
                                    'sep_char'    => ',',
                                    'binary'      => 1,
                                    'auto_diag'   => 1,
                                    'eol'         => $/
                                  }
               )
            }
 );
 if ( $app->get_current_command eq 'console' ) {
  $app->render(
         "Welcome to the CohortExplorer version $VERSION console." . "\n\n"
       . "Type 'help <COMMAND>' for command specific help." . "\n"
       . "Use tab for command-line completion and ctrl + L to clear the screen."
       . "\n"
       . "Type q or exit to quit." );
 }
 return;
}

#-------
1;
__END__

=pod

=head1 NAME

CohortExplorer::Application - CohortExplorer superclass

=head1 SYNOPSIS

The class is inherited from L<CLI::Framework::Application> and overrides the following methods:

=head2 usage_text()

This method returns the application usage.

=head2 option_spec()

This method returns the application option specifications as expected by L<Getopt::Long::Descriptive>.

   ( 
     [ 'datasource|d:s' => 'provide datasource'           ],
     [ 'username|u:s'   => 'provide username'             ],
     [ 'password|p:s'   => 'provide password'             ],
     [ 'verbose|v'      => 'show with verbosity'          ],
     [ 'help|h'         => 'show usage message and exit'  ] 
   )

=head2 validate_options( $opts )

This method ensures the user has supplied all mandatory options such as datasource, username and password.

=head2 command_map()

This method returns the mapping between command names and command classes
 
  console  => 'CLI::Framework::Command::Console',
  help     => 'CohortExplorer::Command::Help',
  menu     => 'CohortExplorer::Command::Menu',
  describe => 'CohortExplorer::Command::Describe',
  history  => 'CohortExplorer::Command::History',
  find     => 'CohortExplorer::Command::Find',
  search   => 'CohortExplorer::Command::Query::Search',
  compare  => 'CohortExplorer::Command::Query::Compare'

=head2 command_alias()

This method returns mapping between command aliases and command names

  h    => 'help',
  m    => 'menu',
  s    => 'search',
  c    => 'compare',
  d    => 'describe',
  hist => 'history',
  f    => 'find',
  sh   => 'console'

=head2 pre_dispatch( $command )

This method ensures the invalid commands do not dispatch and logs all commands successfully dispatched.

=head2 noninteractive_commands()

The method returns a list of valid commands under interactive mode. The commands search, compare and history can be invalid because they are application dependent. These commands require the user to have access to at least one variable from the datasource and also depend on the datasource type. The compare command is only available to longitudinal datasources with data on at least 2 visits.
 
=head2 render( $output )

This method is responsible for the presentation of the command output. The output from all commands except help is organised into a table.

=head2 read_cmd( )

This method attempts to provide the autocompletion of options and arguments wherever applicable.

=head2 handle_exception( $e )

This method prints and logs exceptions.
 
=head2 init( $opts )

This method is responsible for the application initialization which includes prompting the user to enter password if not already supplied and initializing the logger and the datasource.

=head2 OPERATIONS

This class attempts to perform the following operations upon successful initialization of the datasource:

=over

=item 1

Prints a menu of available commands based on the datasource type.

=item 2

Provides autocompletion of command arguments/options (if applicable) for the user entered command.

=item 3

Dispatches the command object for command specific processing.

=item 4 

Logs exceptions (if any) thrown by the commands.

=item 5

In case of no exception, it captures the output returned by the command and displays in a table.

=back

=head1 ERROR HANDLING

All exceptions thrown within CohortExplorer are treated by C<handle_exception( $e )>. The exceptions are imported from L<CLI::Framework::Exceptions>.
 
=head1 DEPENDENCIES

L<Carp>

L<CLI::Framework::Application>

L<CLI::Framework::Exceptions>

L<Exception::Class::TryCatch>

L<File::HomeDir>

L<Log::Log4perl>

L<Term::ReadKey>

L<Text::ASCIITable>

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
