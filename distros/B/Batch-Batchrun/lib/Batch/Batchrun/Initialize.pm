package Batch::Batchrun::Initialize;

  use strict;
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


  require Exporter;

  @ISA     = qw(Exporter);

  @EXPORT  = qw( do_the_initialization 
                 initialize 
                 get_config 
                 get_the_options );

  $VERSION = '1.03';

  # Preloaded methods go here.
  use Cwd;
  use File::Basename;
  use Getopt::Mixed qw(getOptions);
  use Config;
  
sub initialize 
  {
   &do_the_initialization();
   &get_config();
   &get_the_options();
   &setup_the_control_variables();
   &initialize_commands();
  }

sub do_the_initialization
  {
   if ( $^O =~ /win/i )
     {
      $Batch::Batchrun::Opsys_user = $ENV{'USERNAME'};
      $Batch::Batchrun::UserHome = $ENV{'USERPROFILE'};
      $Batch::Batchrun::Hostname = $ENV{COMPUTERNAME};
     }
   else
     {
      $Batch::Batchrun::Opsys_user = $ENV{'USER'};
      $Batch::Batchrun::UserHome = $ENV{'HOME'};
      $Batch::Batchrun::Hostname = `/bin/uname -n`;
      chomp($Batch::Batchrun::Hostname);
     }
   #############################################
   #  Used so far variables
   #############################################


   $Batch::Batchrun::Application          = 'GENERAL';
   $Batch::Batchrun::Control{'FORMAT'}    = undef;
   $Batch::Batchrun::Counter              = 1;
   $Batch::Batchrun::DBHInternal          = 'IFWINTERNAL';
   $Batch::Batchrun::DBHTMM               = 'IFWTMM';
   $Batch::Batchrun::Error                = 0;
   $Batch::Batchrun::ErrorCode            = 1000;
   $Batch::Batchrun::FatalCode            = -1;
   $Batch::Batchrun::ErrorSeparator       = "*" x 57 . "\n";
   $Batch::Batchrun::EventSeparator       =  "=" x 77 . "\n";
   $Batch::Batchrun::False                = 0;
   $Batch::Batchrun::Msg                  = '';
   $Batch::Batchrun::NoErrors             = 0;
   $Batch::Batchrun::Step                 = 1;
   $Batch::Batchrun::True                 = 1;
   $Batch::Batchrun::TaskID               = '';
   $Batch::Batchrun::Version              = $Batch::Batchrun::VERSION;
   $Batch::Batchrun::WarningCode          = 1;
   @Batch::Batchrun::DoFetchArray         = ();
   @Batch::Batchrun::EndDoArray           = ();
   @Batch::Batchrun::KeepTrack            = ();
   @Batch::Batchrun::InALoop              = ();
   %{$Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASKPARAMPAIRS'}} = ();
   $SIG{'INT'}                  = \&SignalHandler;
   
   # Delete Pending
   #
   ##$Batch::Batchrun::LibraryTask          = $Batch::Batchrun::False;
   ##$Batch::Batchrun::TotalErrors          = 0;
   ##$Batch::Batchrun::TotalStepsCompleted  = 0;
   ##$Batch::Batchrun::TotalWarnings        = 0;
   ##@Batch::Batchrun::ErrorSteps           = ();
   ##@Batch::Batchrun::WarningSteps         = ();
   ##@Batch::Batchrun::dbh                  = ();
   ##@Batch::Batchrun::sth                  = ();
   
   #
   # Setup PerlTmp package which is used when performing evals
   #
   eval q{
          package PerlTmp;
          use Env;
          use Batch::Batchrun::Pwlookup;
          no strict;
          };
   die" Could not Eval setup of PerlTmp package:\n$@\n" if $@;

  }

sub SignalHandler
  {
   die;
  }

sub get_config
  {
  #--------------------------------------------------------
  #  br.config locations in order of precedence
  #           
  #  Current working directory 
  #  Location defined in the BR_CONFIG environment variable 
  #  Current user’s home directory 
  #  The directory where Batchrun.pm is installed 
  
  # Get installed directory
  
  $Batch::Batchrun::ConfigFile = dirname($INC{'Batchrun/Batchrun.pm'});
  $Batch::Batchrun::ConfigFile .= '/br.config';

  # If config in UserHome then use it
  
  if ( -s "$Batch::Batchrun::UserHome/br.config" )
   {
   $Batch::Batchrun::ConfigFile   = $Batch::Batchrun::UserHome.'/br.config';
   }

  # If ENV VAR specified then use it
  
  if ( defined($ENV{BR_CONFIG}) and -s $ENV{BR_CONFIG} )
   { 
   $Batch::Batchrun::ConfigFile   = $ENV{BR_CONFIG}; 
   }

  # If config in current directory then use it
  
  my $config_file = cwd();
  $config_file .= '/br.config';
  $Batch::Batchrun::ConfigFile = $config_file if ( -s $config_file);
  open(CONFIG,"<$Batch::Batchrun::ConfigFile") 
      or die("Could not open config file:$config_file $!\n");

  my $section_name;
  my $left; my $right;
  LOADCONFIG: while( <CONFIG> )
    {
   
    # Ignore comment and blank lines    
    next LOADCONFIG if /^\s*#/ or /^\s*$/;

    chop($_);
    if ( $_ =~ /\[.*\]/ )
      {
       $section_name = $_;
       $section_name =~ s/\[(.*)\]/$1/;
       next LOADCONFIG;
      }

    ( $left, $right ) = split ( /=/, $_ );

    if ( $section_name eq 'Global' )
      {
       $Batch::Batchrun::Control{'CONFIG'}{$left} = $right;
      }
    else
      {
       $Batch::Batchrun::Control{'CONFIG'}{$section_name}{$left} = $right;
      }
    }  #  End While Loop
  close(CONFIG);
  }  #  End Subroutine Load_config


sub get_the_options
  {
   #################################################################
   #   Order of doing things:
   #      1.  plug defaults for any settings that are not defined
   #      2.  get Config settings  ( done above in main section )
   #      3.  Load variables from Env Variables, if defined
   #      4.  Load variables from command line options, if defined
   #      5.  Test for necessary combinations, bail if not correct
   #
   #   List of global process control variables
   #        $Batch::Batchrun::User
   #        $Batch::Batchrun::Server
   #        $Batch::Batchrun::Secondary
   #        $Batch::Batchrun::Filename
   #        $Batch::Batchrun::Task
   #        $Batch::Batchrun::Database
   #        $Batch::Batchrun::Databasetype
   #        $Batch::Batchrun::Password
   #        $Batch::Batchrun::Parameters
   #        $Batch::Batchrun::Rerun
   #        $Batch::Batchrun::Load
   #        $Batch::Batchrun::Run
   #        $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'}
   #        $Batch::Batchrun::Stepon
   ##################################################################

   ######################################################
   #  Plug default values
   ######################################################
   if ( $^O =~ /win/i )
     { $Batch::Batchrun::User = $ENV{'USERNAME'}; }
   else
     { $Batch::Batchrun::User = $ENV{'USER'}; }
   $Batch::Batchrun::Databasetype = 'Oracle';
   $Batch::Batchrun::Database     = 'system_service';
   $Batch::Batchrun::Load         = $Batch::Batchrun::False;
   $Batch::Batchrun::CheckOnly    = $Batch::Batchrun::False;
   $Batch::Batchrun::Run          = $Batch::Batchrun::True;
   $Batch::Batchrun::Build        = $Batch::Batchrun::False;
   $Batch::Batchrun::BuildAll     = $Batch::Batchrun::False;
   $Batch::Batchrun::Rerun        = ''; 
   $Batch::Batchrun::Password     = 'lookup';   
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'}      = 150;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Stepon' }      = $Batch::Batchrun::False;
   $Batch::Batchrun::Output{$Batch::Batchrun::Counter} = $Batch::Batchrun::True;

   #############################################################
   #  Load some variables from Config variables now, if defined 
   #############################################################

   if ( defined ($Batch::Batchrun::Control{CONFIG}{BRPrimary}) )      { $Batch::Batchrun::Server = $Batch::Batchrun::Control{CONFIG}{BRPrimary}; }
   if ( defined ($Batch::Batchrun::Control{CONFIG}{BRSecondary}) )    { $Batch::Batchrun::Secondary = $Batch::Batchrun::Control{CONFIG}{BRSecondary}; }
   if ( defined ($Batch::Batchrun::Control{CONFIG}{BRUser}) )         { $Batch::Batchrun::User = $Batch::Batchrun::Control{CONFIG}{BRUser}; }
   if ( defined ($Batch::Batchrun::Control{CONFIG}{BRDatabase}) )     { $Batch::Batchrun::Database = $Batch::Batchrun::Control{CONFIG}{BRDatabase}; }
   if ( defined ($Batch::Batchrun::Control{CONFIG}{BRDatabasetype}) ) { $Batch::Batchrun::Databasetype = $Batch::Batchrun::Control{CONFIG}{BRDatabasetype}; }
   if ( defined ($Batch::Batchrun::Control{CONFIG}{BREncrypt}) ) { $Batch::Batchrun::BREncrypt = $Batch::Batchrun::Control{CONFIG}{BREncrypt}; }
   if ( defined ($Batch::Batchrun::Control{CONFIG}{BRDecrypt}) ) { $Batch::Batchrun::BRDecrypt = $Batch::Batchrun::Control{CONFIG}{BRDecrypt}; }

   ######################################################
   #  Load variables from Env variables first, if defined
   ######################################################
   if ( defined($ENV{BR_USER})      )    { $Batch::Batchrun::User         = $ENV{BR_USER}; }
   if ( defined($ENV{BR_PASSWORD})  )    { $Batch::Batchrun::Password     = $ENV{BR_PASSWORD}; }
   if ( defined($ENV{BR_SERVER})    )    { $Batch::Batchrun::Server       = $ENV{BR_SERVER}; }
   if ( defined($ENV{BR_SECONDARY}) )    { $Batch::Batchrun::Secondary    = $ENV{BR_SECONDARY}; }
   if ( defined($ENV{BR_TASK})      )    { $Batch::Batchrun::Task         = $ENV{BR_TASK}; }
   if ( defined($ENV{BR_DATABASE})  )    { $Batch::Batchrun::Database     = $ENV{BR_DATABASE}; }
   if ( defined($ENV{BR_DATABASETYPE}))  { $Batch::Batchrun::Databasetype = $ENV{BR_DATABASETYPE}; }
   if ( defined($ENV{BR_PARAMETERS})  )  { $Batch::Batchrun::Parameters   = $ENV{BR_PARAMETERS}; }
   if ( defined($ENV{BR_APPLICATION})  ) { $Batch::Batchrun::Application  = uc($ENV{BR_APPLICATION}); }
   if ( defined($ENV{BR_TASKSDIR})  )    { $Batch::Batchrun::Control{CONFIG}{TasksDirectory} = $ENV{BR_TASKSDIR}; }
   if ( defined($ENV{BR_ENCRYPT})  )     { $Batch::Batchrun::Encrypt      = uc($ENV{BR_ENCRYPT}); }
   if ( defined($ENV{BR_DECRYPT})  )     { $Batch::Batchrun::Decrypt      = uc($ENV{BR_DECRYPT}); }
   #**********************
   #   Get the options
   #**********************
   #       -U<user>
   #       -P<password|lookup|prompt>
   #       -S<server>
   #       -T<taskname>
   #       -D<database>
   #       -application       Note: default is 'GENERAL'
   #       -p<quoted space delimited parameters>
   #       -R<erun step_list> Note: command-delim list of steps to process, dash between stepnums allowed
   #       -t<database type>  Note: default 'oracle'
   #       -f<filename>       Note: required for load
   #       -v<erbose>         Note: default is no verbose
   #       -s<tepon>          Note: default is no stepon
   #       -l<oad>            Note: default is no load
   #       -r<run>            Note: default is run
   #       -b<build>          Note: default is no build
   #**************************************************************** 
   no strict 'vars';
   Getopt::Mixed::getOptions( "U=s P=s S=s T=s D=s p=s R=s t=s f=s v:s s l r c b B w:s a=s" );
  
   if (defined($opt_U)) { $Batch::Batchrun::User         = $opt_U; }
   if (defined($opt_P)) { $Batch::Batchrun::Password     = $opt_P; }
   if (defined($opt_S)) { $Batch::Batchrun::Server       = $opt_S; }
   if (defined($opt_T)) { $Batch::Batchrun::Task         = uc($opt_T); }
   if (defined($opt_a)) { $Batch::Batchrun::Application  = uc($opt_a); }
   if (defined($opt_D)) { $Batch::Batchrun::Database     = $opt_D; }
   if (defined($opt_p)) { $Batch::Batchrun::Parameters   = $opt_p; }
   if (defined($opt_t)) { $Batch::Batchrun::Databasetype = $opt_t; }
   if (defined($opt_R)) { $Batch::Batchrun::Rerun        = $opt_R; }
   if (defined($opt_l)) { $Batch::Batchrun::Load         = $Batch::Batchrun::True; }
   if (defined($opt_c)) { $Batch::Batchrun::CheckOnly    = $Batch::Batchrun::True; }
   if (defined($opt_r)) { $Batch::Batchrun::Run          = $Batch::Batchrun::True; }
   if (defined($opt_b)) { $Batch::Batchrun::Build        = $Batch::Batchrun::True; }
   if (defined($opt_B)) { $Batch::Batchrun::BuildAll     = $Batch::Batchrun::True; }
   if (defined($opt_v)) { $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'}   = $opt_v; }
   if (defined($opt_f)) { $Batch::Batchrun::Filename     = $opt_f; 
                          $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'} = $Batch::Batchrun::Control{'CONFIG'}{'FVerboseSw'}; }
   if (defined($opt_s)) { $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Stepon'}  = $Batch::Batchrun::True; }

   if (defined($opt_v))
     {
      if ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'} =~ /on/i )
        {
         $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'} = 150;
        }
      elsif ( $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'} =~ /off/i )
        {
         $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'} = 0;
        }
      else
        {
         $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'} = $opt_v;
        }
     }
      

   #*********************************************
   #  Check combinations
   #*********************************************
   if ( $Batch::Batchrun::Load and !$Batch::Batchrun::Filename )
     {
      &usage('Must pass a filename to do a Load');
     }
     
   if ( $Batch::Batchrun::Load and !$opt_r )
     {
      $Batch::Batchrun::Run = $Batch::Batchrun::False;
     } 

   my($connect) = $Batch::Batchrun::False;
   if (  $Batch::Batchrun::Server and
         $Batch::Batchrun::User   and
         $Batch::Batchrun::Database and
         $Batch::Batchrun::Databasetype) 
     {
      $connect = $Batch::Batchrun::True;
     }

   if ( $Batch::Batchrun::Run )
     {
     # If running then filename or connect is required
     if (!$Batch::Batchrun::Filename && !$connect)
       {
        &usage('Running from task/step tables require User, Server, DBtype, Task ');
       } 
     if (! $Batch::Batchrun::Filename )
       {
       # If no Filename then Database connect and Task is required
       if ($connect)
         {
         if ($Batch::Batchrun::BuildAll)
           {
            # Everything is fine, BuildAll requires $connect but not TASK
           }
         elsif (!$Batch::Batchrun::Task)
           {
            &usage('Running from task/step tables require User, Server, DBtype, Task ');
           }
         } 
       }
     } 
     
                 
   if ( $Batch::Batchrun::Load && !$Batch::Batchrun::Run && !$connect )
     {
      &usage('Loading to task/step tables require User, Server, DBtype, Filename ');
     } 

   if ( $Batch::Batchrun::Load or $Batch::Batchrun::Run or $Batch::Batchrun::BuildAll
        or $Batch::Batchrun::Build)
     {
     print "**************************************************************\n";
     print "***  Batchrun Version: $Batch::Batchrun::Version operating parameters\n";
     print "***  ---------------------------------------------------------\n";
     print "***  Repository User:     $Batch::Batchrun::User\n";
     print "***  Repository Server:   $Batch::Batchrun::Server\n";
     print "***  Repository Db:       $Batch::Batchrun::Database\n"   if ($Batch::Batchrun::Databasetype !~ /oracle/i);
     print "***  Repository DB type:  $Batch::Batchrun::Databasetype\n" if ($Batch::Batchrun::Databasetype !~ /oracle/i);;
     print "***  Runtime User:        $Batch::Batchrun::Opsys_user\n";
     print "***  Runtime Host:        $Batch::Batchrun::Hostname\n";
     print "***  Filename:            $Batch::Batchrun::Filename\n"   if ($Batch::Batchrun::Filename);
     print "***  Task:                $Batch::Batchrun::Task\n"       if ($Batch::Batchrun::Task);
     print "***  Application:         $Batch::Batchrun::Application\n" if ($Batch::Batchrun::Application !~ m/GENERAL/i);
     print "***  Tasks Directory:     $Batch::Batchrun::Control{CONFIG}{TasksDirectory}\n" if ($Batch::Batchrun::Control{CONFIG}{TasksDirectory});
     print "***  Password:            $Batch::Batchrun::Password\n"   if ($Batch::Batchrun::Debuglevel > 3 );
     print "***  Parameters:          $Batch::Batchrun::Parameters\n" if ($Batch::Batchrun::Parameters);
     print "***  Verbose:             $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'Verbose'}\n";
     print "***  Stepon:              $Batch::Batchrun::Stepon\n"     if ($Batch::Batchrun::Stepon);
     print "***  DebugLevel:          $Batch::Batchrun::DebugLevel\n" if ($Batch::Batchrun::DebugLevel > 0);
     print "***  Config File:         $Batch::Batchrun::ConfigFile\n";
     print "***  Process flags:       Load=$Batch::Batchrun::Load Run=$Batch::Batchrun::Run Rerun=$Batch::Batchrun::Rerun ",
                                        "CheckOnly=$Batch::Batchrun::CheckOnly Build=$Batch::Batchrun::Build\n";
     print "**************************************************************\n";
     }
  }

sub setup_the_control_variables
  {
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'TASK'} = $Batch::Batchrun::Task;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'PASSEDPARMS'} = $Batch::Batchrun::Parameters;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'APP'} = $Batch::Batchrun::Application;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'LibraryTask'} = $Batch::Batchrun::False;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'OnError'} = $Batch::Batchrun::False;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{'OnWarning'} = $Batch::Batchrun::False;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{1}{'LoopOutput'} = $Batch::Batchrun::False;
   $Batch::Batchrun::Control{$Batch::Batchrun::Counter}{Eval} = 0;
  }
  
sub initialize_commands
  {
  #------------------------------------------------------------------
  # This subroutine initializes a hash array describing the 
  # attributes of each command.  The structure exists as follows.
  # 'COMMAND' =>
  #   {
  #   Parms => 0 or 1                Does the command use the parameter section?
  #   Data => 0 or 1                 Does the command use the data section?
  #   Eval => 0 or 1                 Can the command support perl variables?
  #   Chkdata => 'Name,name,..'      List of allowed parameter names in data section.
  #   Chkparms => 'Name,name,..'     List of allowed parameter names in parameter section.
  #   Subroutine => 'command_subr',  Subroutine to call
  #   parameter_name => 0 or 1       Parameter: 1=required 0=optional
  #   Values=>'ON,OFF,ETC'           Values allowed for command without parameters
  #                                  (special case of NUMBER, ie, VERBOSE command )  
  #   }
  #------------------------------------------------------------------
    %Batch::Batchrun::Commands = (
      '%' => 
          { 
          Parms => 1, 
          Data => 0, 
          Subroutine => ''
          },
      'SHORT DESCRIPTION' =>
          { 
          Parms => 1, 
          Data => 0, 
          Subroutine => '' 
          },
      '#' => 
          { 
          Parms => 0, 
          Data => 1, 
          Subroutine => 'command_comment' 
          },
      'ABORT' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_abort' 
          },
      'AUTOCOMMIT' =>
          {
          Parms => 1,
          Data => 0,
          Eval =>1,
          Chkparms => 'HANDLE,STATE',
          Subroutine => 'command_autocommit',
          HANDLE=>1,
          STATE=>1
          },
      'BCP' => 
          { 
          Parms => 0, 
          Data => 1, 
          Eval =>1,
          Chkdata => 'TABLE,DIRECTION,DATA_FILE,USER,SERVER,PASSWORD,MODE,FORMAT_FILE,ERROR_FILE,FIELD_TERMINATOR,ROW_TERMINATOR,PACKETSIZE,BATCHSIZE,MAX_ERRORS,IGNORE_ERRORS,SHOW_ERRORS',
          Subroutine => 'command_bcp',
          SERVER=>1,
          USER=>1,
          DIRECTION=>1,
          MODE=>0,
          FORMAT_FILE=>0,
          TABLE=>1,
          DATA_FILE=>0,
          PASSWORD=>0,
          ERROR_FILE=>0,
          FIELD_TERMINATOR=>0,
          ROW_TERMINATOR=>0,
          PACKETSIZE=>0,
          BATCHSIZE=>0,
          MAX_ERRORS=>0,
          IGNORE_ERRORS=>0,
          SHOW_ERRORS=>0          
          },
      'BREAK' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_break' 
          },
      'COMMENT' => 
          { 
          Parms => 0, 
          Data => 1, 
          Subroutine => 'command_comment' 
          },
      'COMMIT' =>
          {
          Parms => 1,
          Data => 0,
          Eval =>1,
          Chkparms => 'HANDLE',
          Subroutine => 'command_commit',
          HANDLE=>1
          },
      'COPY FILE' => 
          { 
          Parms => 1, 
          Data => 0,
          Eval =>1,
          Chkparms => 'SRC,DEST',
          Subroutine => 'command_copy_file',     
          SRC=>1,
          DEST=>1 
          },        
      'DEBUG' => 
          { 
          Parms =>1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_debug',
          Values=>'ON,OFF'
          },
      'DELETE FILE' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Chkparms => 'FILE',
          FILE=>0,
          Subroutine => 'command_delete_file' 
          },         
      'DISPLAY' => 
          { 
          Parms => 0, 
          Eval =>1,
          Data => 1, 
          Subroutine => 'command_display' 
          },
      'DO SQL LOOP' => 
          { 
          Parms => 1, 
          Data => 1, 
          Eval =>1,
          Chkparms =>'HANDLE,BIND_VARS',
          Subroutine => 'command_do_sql_loop',
          HANDLE=>1,
          BIND_VARS=>1 
          },
      'ELSE IF' => 
          { 
          Parms => 1, 
          Data => 0, 
          Subroutine => 'command_else_if' 
          },
      'ELSE' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_else' 
          },
      'END DO' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_end_do' 
          },
      'END IF' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_end_if' 
          },
      'ERROR' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_error' 
          },
      'EVAL' => 
          { 
          Parms => 1, 
          Data => 0,
          Eval =>1,
          Subroutine => 'command_eval',
          Values=>'ON,OFF,PARMSONLY,DATAONLY'
          },
      'EXIT FAILURE' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_exit_failure' 
          },
      'EXIT SUCCESS' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_exit_success' 
          },
      'EXIT WARNING' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_exit_warning' 
          },
      'EXIT' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_exit' 
          },
      'FILE EXISTS' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Chkparms => 'FILE,EXISTS',
          Subroutine => 'command_file_exists',
          FILE=>1,
          EXISTS=>1 
          },
      'FORMAT' => 
          { 
          Parms => 0, 
          Data => 1, 
          Subroutine => 'command_format' 
          },
      'FTP' => 
          { 
          Parms => 1, 
          Data => 1,
          Eval =>1,
          Chkparms =>'HOST,USER,PASSWORD,PROXY,DEBUG',
          Subroutine => 'command_ftp',
          HOST=>1,
          USER=>1,
          PASSWORD=>0,
          PROXY=>0,
          DEBUG=>0
          },
      'GOSUB' => 
          { 
          Parms => 1,
          Data => 0, 
          Eval =>1,
          Chkparms => 'NAME,APP,PARMS',
          Subroutine => '',                      
          NAME=>1,
          APP=>0,
          PARMS=>0 
          },
      'GOTO' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_goto' 
          },
      'IF' => 
          { 
          Parms => 1, 
          Data => 0, 
          Subroutine => 'command_if' 
          },
      'ISQL' => 
          { 
          Parms => 0, 
          Data => 1,
          Eval =>1,
          Chkdata => 'SERVER,USER,SQL_FILE,OUTPUT_FILE,PASSWORD',
          Subroutine => 'command_isql',
          SERVER=>1,
          USER=>1,
          SQL_FILE=>1,
          OUTPUT_FILE=>1,
          PASSWORD=>0
          },
      'LABEL' => 
          { 
          Parms => 1, 
          Data => 0, 
          Subroutine => 'command_label' 
          },
      'LOGOFF' => 
          { 
          Parms => 1,
          Data => 0, 
          Eval =>1,
          Chkparms => 'HANDLE', 
          Subroutine => 'command_logoff',        
          HANDLE=>1 
          },
      'LOGON' => 
          { 
          Parms => 1, 
          Data => 0,
          Eval =>1,
          Chkparms =>'HANDLE,SERVER,SECONDARY,AUTOCOMMIT,DBTYPE,USER,PASSWORD,DATABASE',
          Subroutine => 'command_logon',         
          HANDLE=>1,
          SERVER=>1,
          SECONDARY=>0,
          AUTOCOMMIT=>0,
          DBTYPE=>0,
          USER=>0,
          PASSWORD=>0,
          DATABASE=>0 
          },
      'LOOP OUTPUT' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Values =>'ON,OFF',
          Subroutine => 'command_loop_output'   
          },
      'MAIL' => 
          { 
          Parms => 0, 
          Data => 1,
          Chkdata => 'ADDRESS,FROM,SUBJECT,MESSAGE,CC,PRIORITY,HTML,ATTACHMENTS',
          Subroutine => 'command_mail',   
          ADDRESS=>1,
          FROM=>1,
          SUBJECT=>0,
          MESSAGE=>0,
          CC=>0,
          PRIORITY=>0,
          HTML=>0,
          ATTACHMENTS=>0,
          },
      'NEXT' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_next' 
          },
      'ON ERROR' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_on_error' 
          },
      'ON WARNING' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_on_warning' 
          },
      'OUTPUT' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_output',
          Values=>'ON,OFF' 
          },
      'PERL' => 
          { 
          Parms => 0, 
          Data => 1, 
          Subroutine => 'command_perl' 
          },
      'RENAME FILE' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Chkparms => 'SRC,DEST',
          Subroutine => 'command_rename_file',   
          SRC=>1,
          DEST=>1 
          },
      'RETAIN FILE' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Chkparms => 'DIR,LIMIT,PREFIX,FILE,COMPRESS,DELETE,CHMOD,VERBOSE',
          Subroutine => 'command_retain_file',   
          DIR=>1,
          LIMIT=>0,
          FILE=>1,
          PREFIX=>0,
          CHMOD=>0,
          VERBOSE=>0,
          COMPRESS=>0,
          DELETE=>0 
          },          
      'ROLLBACK' =>
          {
          Parms => 1,
          Data => 0,
          Eval =>1,
          Chkparms => 'HANDLE',
          Subroutine => 'command_rollback',
          HANDLE=>1
          },
      'SET' => 
          { 
          Parms => 0, 
          Data => 1, 
          Eval => 1,
          Subroutine => 'command_set' 
          },
      'STEP' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_step',
          Values=>'ON,OFF' 
          },
      'SQL IMMEDIATE' => 
          { 
          Parms => 1, 
          Data => 1, 
          Eval =>1,
          Chkparms => 'HANDLE',
          Subroutine => 'command_sql_immediate', 
          HANDLE=>1 
          },
      'SQLLOADER' =>
          {
          Parms => 0,
          Data => 1,
          Eval =>1,
          Chkdata => 'CONTROL,DATA,USER,SERVER,PASSWORD,LOG,BAD,DATA,DISCARD,DISCARDMAX,SKIP,LOAD,ERRORS,ROWS,BINDSIZE,SILENT,DIRECT,PARFILE,PARALLEL,FILE,IGNORE_ERRORS,SHOW_ERRORS',
          Subroutine => 'command_sqlldr',
          CONTROL=>1,
          DATA=>1,
          USER=>1,
          SERVER=>1,
          PASSWORD=>0,
          BAD=>0,
          BINDSIZE=>0,  
          DATA=>0, 
          DIRECT=>0,  
          DISCARD=>0,   
          DISCARDMAX=>0,   
          ERRORS=>0,  
          FILE=>0,  
          LOAD=>0,  
          LOG=>0,
          PARALLEL=>0,  
          PARFILE=>0,  
          ROWS=>0,  
          SILENT=>0,  
          SKIP=>0,
          IGNORE_ERRORS=>0,
          SHOW_ERRORS=>0   
          },
      'SQLPLUS' => 
          { 
          Parms => 1, 
          Data => 1, 
          Eval =>1,
          Chkparms => 'SERVER,USER,PASSWORD,FILE',
          Subroutine => 'command_sqlplus',
          SERVER=>1,
          USER=>1,
          PASSWORD=>0,
          FILE=>0
          },     
      'SQL REPORT' => 
          { 
          Parms => 1, 
          Data => 1, 
          Eval =>1,
          Chkparms => 'HANDLE,FILE',
          Subroutine => 'command_sql_report',    
          HANDLE=>1,
          FILE=>0
          },     
      'SQL SELECT' => 
          { 
          Parms => 1, 
          Data => 1, 
          Eval =>1,
          Chkparms => 1,
          Subroutine => 'command_sql_select',    
          HANDLE=>1, 
          BIND_VARS=>1 
          },
      'SQR' => 
          { 
          Parms => 1, 
          Data => 1, 
          Eval =>1,
          Chkparms => 'SERVER,USER,PROGRAM,PASSWORD,ERRORS,LOG,OUTPUT,FLAGS,PARAMETERS,PARFILE,SHOW_ERRORS',
          Subroutine => 'command_sqr',
          SERVER=>1,
          USER=>1,
          PROGRAM=>1,
          PASSWORD=>0,
          ERRORS=>0,
          LOG=>0,
          OUTPUT=>0,
          FLAGS=>0,
          PARAMETERS=>0,
          SHOW_ERRORS=>0,
          PARFILE=>0
          },        
          'SYSTEM' => 
          { 
          Parms => 0, 
          Data => 1, 
          Eval =>1,
          Subroutine => 'command_system' 
          },
      'TABLE' => 
          { 
          Parms => 0, 
          Data => 1,
          Eval =>1,
          Chkdata => 'HANDLE,SERVER,ACTION,OBJECT_TYPE,TABLE_OWNER,TABLE_NAME,OBJECT_OWNER,OBJECT_NAME,GRANTEE',
          Subroutine => 'command_table',         
          HANDLE=>1,
          SERVER=>0,
          ACTION=>'CREATE,DROP',
          OBJECT_TYPE=>1,
          TABLE_OWNER=>1,
          TABLE_NAME=>0,
          OBJECT_OWNER=>0,
          OBJECT_NAME=>0,
          GRANTEE=>0
          },
       'TMM' =>
          {
          Parms => 0,
          Data => 1,
          Eval =>0,
          Chkdata => 'ACTION,OBJECT_TYPE,SERVER,TABLE_OWNER,TABLE_NAME,OBJECT_OWNER,OBJECT_NAME,CONSTRAINT_TYPE,GRANTEE,EXP_DATE,SQL_TEXT,ORDER_NUM',
          Subroutine => 'command_tmm',
          ACTION=>'INSERT,EXPIRE',
          OBJECT_TYPE=>0,
          SERVER=>1,
          TABLE_OWNER=>1,
          TABLE_NAME=>0,
          OBJECT_OWNER=>0,
          OBJECT_NAME=>0,
          CONSTRAINT_TYPE=>0,
          GRANTEE=>0,
          EXP_DATE=>0,
          SQL_TEXT=>0,
          ORDER_NUM=>0
          },
      'TASK:' => 
          { 
          Parms => 1, 
          Data => 1,
          Chkparms => 'NAME,APP,PARMS',
          Subroutine => '',                      
          NAME=>1,
          APP=>0,
          PARMS=>0
          },
      'UNSET' => 
          { 
          Parms => 0, 
          Data => 1,
          Eval => 1,
          Subroutine => 'command_unset'                      
          },
      'VERBOSE' => 
          { 
          Parms => 1, 
          Data => 0, 
          Eval =>1,
          Subroutine => 'command_verbose',       
          Values=>'ON,OFF,NUMBER' 
          },
      'WARNING' => 
          { 
          Parms => 0, 
          Data => 0, 
          Subroutine => 'command_warning' 
          },
    );
  }
sub usage
  {
  my ($msg) = @_;
  print STDERR <<EOFF;
  
  Batchrun (Version $Batch::Batchrun::Version) USAGE:
  
  batchrun.pl -Uuser -Sserver -ffile -l -ttype                  #Load a file 
  batchrun.pl -Uuser -Sserver -ffile -run -load -ttype [-pparm] #Load and run   
  batchrun.pl -ffile  [-pparm ]                                 #Run from file
  batchrun.pl -Uuser -Sserver -Ttask -ttype [-p"parm1,parm2"]   #Run from database
EOFF
  print STDERR "\n",$msg;
  die"\nRequired options not all passed!\n";
  
  }

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Batch::Batchrun::Initialize - Batchrun extension module.

=head1 SYNOPSIS

  No general usage.  Designed only as a submodule to Batchrun.

=head1 DESCRIPTION

Contains Batchrun subroutines.

=head1 AUTHOR

Daryl Anderson 

Louise Mitchell 

Email: batchrun@pnl.gov

=head1 SEE ALSO

batchrun(1).

=cut


