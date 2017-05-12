package Continuus;

$VERSION = '0.1';

=head1 NAME

  Continuus - Perl interface to Continuus CM

=head1 SYNOPSIS

  use Continuus;

  Check out a file:

  use Continuus;

  $ccm = new Continuus;

  $ccm->start(database => '/proj/Continuus4/rig',
              host => 'stoxserv01');

  $ccm->checkOut(file => 'main.c',
		 version => '2');

  $ccm->stop();


=head1 DESCRIPTION

  The Continuus perl module is a interface to the most common Continuus functions.

=cut

=head1 CHANGE HISTORY

  0.1    Created.

=cut

use strict;

=head1 METHODS

=over 4

=cut

################################################################################

=item new:

  The new method creates a new Continuus object.

=cut

sub new() {
  my $self  = {};

  $self->{DEBUG} = 0;

  bless($self);      

  return $self;  
};

################################################################################

=item start:

  The start method starts a new Continuus session.

  Parameters:
   database: Database to open.
   
   host: Hostname to start the engine on.

   iniFile: Ini file to read.

  Example:
   $ccm->start(database => "/proj/Continuus0/rig/", host => "stoccm01");

=cut

sub start() {
  my $self = shift;
  my %args = @_;
  my ($command);

  $command = "ccm start -m -q -nogui $args{'database'} $args{'host'} $args{'iniFile'} 2>&1";

  $self->printDebug("$command");

  my $CCM_ADDR = `$command`;

  if ($? ne 0) {
    # Continuus startup failed
    warn "$CCM_ADDR\n";
    delete $ENV{CCM_DATETIME_FMT};
    delete $ENV{CCM_INI_FILE};
    return 0;
  }
  
  $ENV{CCM_ADDR} = "$CCM_ADDR";
  
  return 1;
};

################################################################################

=item command:

  The command method acts as a interface to all other Continuus functions
  not implemented in the Continuus module.

  Parameters:
   command: The command to be executed by Continuus

  Example:
  $ccm->command('status');

=cut

sub command() {
  my $self = shift;
  my $command = shift;
  my $result;
  
  printDebug($command);
  $result = `ccm $command`;

  print "$result\n";
};

################################################################################  

=item stop:

  The stop command quits the current Continuus session.

  Parameters:
   None.

=cut

sub stop() {
  my $StopMessage = `ccm stop 2>&1`;
  if ($? ne 0) {
    # Continuus stop failed
    warn "Continuus stop failed.\n$StopMessage\n";
    return 0;
  }
  
  return 1;
};
	    
#################################################################################

=item query:

  The query command is a interface to the Continuus query command.

  Parameters:
   query: The query string
   flags: Flags to pass to Continuus.
   Format: Formatting options.

  Example:
   $ccm->query(query => "status='released'", flags => "-u", format => "%objectname");

=cut

sub query() {
  my $self = shift;
  my %args = @_;
  
  my ($output,$command,@list);
 
  $command = "ccm query \"$args{'query'}\" $args{'flags'} -f \"$args{'format'}\" 2>&1";
  $self->printDebug($command);

  $output = `$command`;
  $self->printDebug($output);

  @list = split('/\r?\n/', $output);
  $self->printDebug($#list);

  for (@$output) { 
    $_ = untaint($_) 
  };
  
  if ($? ne 0) {
    if (@$output >= 1) {
      # One or more lines returned, can only be warnings.
      warn "ccm query failed to execute: @$output";
      return 0;
    }
    else {
      # This is NOT an error situation!
      # If no objects versions found ccm also returns 1.
      return 1;
    }
  }
  
  return 1;
};

################################################################################

=item checkOut:

  Checks out a file.

  Parameters:
   file: The file to check out.
   version: The version to set on the new file.

  Example:
   $ccm->checkOut(file => "main.c", version => "1.1");

=cut

sub checkOut() {
  my $self = shift;
  my %args = @_;
  my ($result, $command);

  if (defined $args{'version'}) {
    $args{'version'} = "-to $args{'version'}";
  }

  $command = "ccm co $args{'version'} $args{'file'}";
  $result = `$command`;
  
  return $?;
}

################################################################################

=item checkIn:

  Checks in a file.

  Parameters:
   file: The file to check out.
   comment: The comment to set on the new file.

  Example:
   $ccm->checkIn(file => "main.c", comment => "Created");

=cut

sub checkIn() {
  my $self = shift;
  my %args = @_;
  my ($result, $command);

  if (defined $args{'comment'}) {
    $args{'comment'} = "-c $args{'comment'}";
  }
  else {
    $args{'comment'} = "-nc";
  }

  $command = "ccm ci $args{'comment'} $args{'file'}";
  $result = `$command`;
  
  return $?;
}

################################################################################

=item reconfigure:

  Reconfigure command

  Parameters:
   project: The project to reconfigure.
   parameters: Other parameters to pass to the reconfigure command.

  Example:
   $ccm->checkOut(file => "main.c", version => "1.1");

=cut

sub reconfigure() {
  my $self = shift;
  my %args = @_;
  my ($result, $command);

  $command = "ccm reconf -p $args{'project'} $args{'parameter'}";
  $result = `$command`;

  return $?;  
}

################################################################################
sub printDebug() {
  my $self = shift;
  my $tString = shift;

  if($self->{DEBUG} == 1) {
    print "DEBUG: $tString\n";
  }
};

################################################################################

=item debugOn:

  Sets the debugging information on.

=cut

sub debugOn() {
  my $self = shift;

  $self->{DEBUG} = 1;
}

################################################################################

=item debugOff:

  Sets the debugging information off.

=cut

sub debugOff() {
  my $self = shift;

  $self->{DEBUG} = 0;
}

################################################################################
sub untaint($) {	
  my $ToUntaint = shift();

  if ($ToUntaint =~ /(.+)/ms) { $ToUntaint = $1; }
  return $ToUntaint;
};

	    
################################################################################

=head1 AUTHOR

Henrik Jönsson henrik7205@hotmail.com

=cut

	    




1;
