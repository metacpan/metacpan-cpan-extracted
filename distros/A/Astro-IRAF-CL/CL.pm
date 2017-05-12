package Astro::IRAF::CL;
use strict;
use warnings;

$SIG{INT} = sub {die}; # Without this DESTROY() does not get called 
		       # when ctrl-c is used for some reason.

use Carp;
use vars qw($VERSION $AUTOLOAD $TIMEOUT);

$VERSION = '0.2.0';

use Fcntl qw(:DEFAULT);

use Cwd;
use Expect 1.15;
use Env qw(IRAF_START);

my $DEBUG = 0;

$Expect::Debug=$DEBUG;
$Expect::Exp_Internal=$DEBUG;
$Expect::Log_Stdout=$DEBUG;

$TIMEOUT = 10; # Time out for internal commands (seconds).

sub new{
  my ($class,%params) = @_;

  my $self = bless {}, $class;

  $self->{'start_params'}    = \%params; #Need this to allow restart post-crash

  $self->{'iraf_start'}      = $params{'iraf_start'}||$self->_get_iraf_start();

  $self->{'debug'}           = $params{'debug'}           || 0;
  $self->{'work_dir'}        = $params{'work_dir'}        || cwd;
  $self->{'log'}             = $params{'log'}             || *STDERR;
  $self->{'display_startup'} = $params{'display_startup'} || 0;

  $self->{'cl_prompt'}       = qr/^cl>\s+/;
  $self->{'continue_prompt'} = qr/>>>\s+/;

  $self->{'packages'}        = []; # For loading/unloading packages.
  $self->{'command_history'} = [];
  $self->{'dead'}            = 1; # It is dead until the CL is running.

  $self->{'session'} = $self->_startup;

  $self->_get_available_commands_and_packages('main');

  if (exists $params{'packages'}){
    foreach my $package (@{$params{'packages'}}){
      $self->load_package($package);
    }
  }

  if (exists $params{'set'}){
    $self->set(%{$params{'set'}});
  }

  return $self;
}

sub _get_iraf_start{
  my $self = shift @_;

  my $startdir;

  if (defined $IRAF_START){	# If a user has an odd place for their IRAF
    $startdir = $IRAF_START;	# base directory then they should use this
				# environment variable to say so.
  }
  else{

    # Make educated guesses as to where the IRAF login.cl might be hiding.

    # If you have any other alternatives you could add them in here
    # This is only really for general places rather than unique odd places
    # though, use IRAF_START or the uparm parameter for those.

    my $found = 0;

    use Env qw(USER HOME);

    my $username = getlogin() || getpwuid($<) || $USER || `whoami`;

    foreach ($HOME,"$HOME/iraf","/home/$username/iraf","/home/$username") {

      if (-e "$_/login.cl" && -d "$_/uparm/"){
	$startdir = $_;
	$found = 1;
	last;
      }
    }

    croak "Do not know where to start IRAF from" if !$found;
  }

  return $startdir;
}

sub _lock_startdir{
  my $self = shift @_;

  sysopen(STARTDIR,"$self->{'iraf_start'}/Astro-IRAF-CL.LOCK",O_WRONLY|O_CREAT|O_EXCL) or croak "\nERROR: Could not get a lock on $self->{'iraf_start'}: $!\n\nThis IRAF start directory is already in use by another Astro::IRAF::CL object,\nyou must specify a different starting position via the iraf_start parameter.\n\nDied";

  $self->{'STARTDIR_FH'} = *STARTDIR;

}

sub _unlock_startdir{
  my $self = shift @_;

  close ($self->{'STARTDIR_FH'}) or croak "could not close lock FH";
  unlink "$self->{'iraf_start'}/Astro-IRAF-CL.LOCK";

}

sub _startup{
  my $self = shift @_;

  $self->_lock_startdir;

  chdir $self->{'iraf_start'} ||croak "Could not cd to $self->{'iraf_start'}";

  my $t = Expect->spawn('cl') || croak "Cannot spawn CL: $!";

  $t->expect(30,'-re',$self->{'cl_prompt'});
  croak "Did not get CL prompt after starting up" if $t->error;

  $self->{'dead'} = 0; # It is now alive.

  my $output = $t->before();
  my @output = split /\n/,$output;
  if ($self->{'display_startup'}){
    for (@output){print STDOUT $_ . "\n"}
  }

  chdir $self->{'work_dir'} || croak "Could not cd to $self->{'work_dir'}";

  $t->print("cd $self->{'work_dir'}\r");
  $t->expect($TIMEOUT,"cd $self->{'work_dir'}\r\n");
  $t->expect($TIMEOUT,'-re',$self->{'cl_prompt'});
  croak "Did not get CL prompt back after trying to cd to $self->{'cl_prompt'}"
    if $t->error;

  return $t;
}

sub restart{
  my $self = shift @_;

# Kill the session if it isn't already dead.

  $self->end() if !$self->{'dead'};

# Reset various parameters so everything works nicely.

  $self->{'dead'} = 0;
  $self->{'cl_prompt'} = qr/^cl>\s+/;

  $self->{'session'} = $self->_startup;

  $self->_get_available_commands_and_packages('main');

# Get the list of previously loaded packages then reset the list.

  my @prev_loaded_packages = @{$self->{'packages'}};
  $self->{'packages'} = [];

# Load packages that were originally specified at start time.

  if (exists $self->{'start_params'}{'packages'}){
    foreach my $package (@{$self->{'start_params'}{'packages'}}){
      $self->load_package($package);
    }
  }

# Set definitions that were originally specified.

  if (exists $self->{'start_params'}{'set'}){
    $self->set(%{$self->{'start_params'}{'set'}});
  }

# Load any other packages that were subsequently loaded.

  foreach my $package (@prev_loaded_packages){
    $self->load_package($package) if !$self->package_is_loaded($package);
  }

}


sub _internal_command{
  my ($self,$command) = @_;

  my $session = $self->{'session'};

  $session->print("$command\r");
  $session->expect($TIMEOUT,"$command\r\n");
  $session->expect($TIMEOUT,'-re',$self->{'cl_prompt'});

  my $output = $session->before();
  $output =~ s/(\r\n)*$//;

  return $output;
}

## IRAF package management.

sub package_is_loaded{
  my ($self,$package) = @_;

  my $loaded = grep {$_ eq $package} @{$self->{'packages'}};

  return $loaded;
}

sub package_exists{
  my ($self,$package) = @_;

  my $defined = $self->_internal_command("print deftask\(\"$package\"\)");

  my $result = $defined eq 'yes' ? 1 : 0;

  return $result;
}


sub load_package{
  my ($self,$package) = @_;

  if (!$self->package_exists($package)){
    croak "Error: Trying to load a package ($package) that does not exist";
  }

  $self->_register_package($package);

  my $output = $self->_internal_command("$package");
  $self->_add_to_command_history($package);

  my @output = $output ? split(/\n/,$output) : ();

  $self->_get_available_commands_and_packages($package);

  return @output;
}

sub _register_package{
  my ($self,$package) = @_;

  my $new_prompt = $self->_get_package_prompt($package);

  $self->_set_cl_prompt($new_prompt);

  unshift @{$self->{'packages'}},$package;

}

sub _get_package_prompt{
  my ($self,$package) = @_;

  my $new_prompt = substr($package,0,2);
  $new_prompt = qr/^$new_prompt>\s+/;

  return $new_prompt;
}

sub _deregister_package{
  my ($self,$package) =  @_;

  my $current_package = $self->get_current_package();

  $package ||= $current_package;

  croak "Unloading packages in wrong order, current package is $current_package, you are trying to unload $package" if $package ne $current_package;

  shift @{$self->{'packages'}};

  my $next_package = $self->get_current_package() || 'cl';

  my $new_prompt = $self->_get_package_prompt($next_package);

  $self->_set_cl_prompt($new_prompt);

}

sub unload_package{
  my ($self,$package) =  @_;

  $self->_deregister_package($package);

  my $output = $self->_internal_command('bye');
  $self->_add_to_command_history('bye');

  my @output = $output ? split(/\n/,$output) : ();

  delete ${$self->{'available_commands'}}{'package'};
  delete ${$self->{'available_packages'}}{'package'};

  return @output;
}

sub get_current_package{
  my $self = shift @_;

  my $current_package = ${$self->{'packages'}}[0];

  return $current_package;

}

sub unload_all_packages{
  my $self = shift @_;

  while (defined (my $current_package = $self->get_current_package)){
    $self->unload_package($current_package);
  }

}

##

## History manipulation routines.

sub _add_to_command_history{
  my ($self,$command) = @_;

  push @{$self->{'command_history'}},$command;

  if ($self->{'debug'}){
    my $log = $self->{'log'};
    print $log 'CL: ' . $command . "\n";
  }

}

sub get_from_command_history{
  my ($self,$position) = @_;

  return ${$self->{'command_history'}}[$position];

}

sub exec_from_history{
  my ($self,$position,%params) = @_;

  my $command = $self->get_from_command_history($position);

  my @output = $self->exec(command => $command,
			   %params);

  if (wantarray){
    return @output;
  }
  elsif(defined wantarray){
    return $output[0];
  }

}

## Set parameter routines

sub _set_cl_prompt{
  my ($self,$prompt) = @_;

  $self->{'cl_prompt'} = $prompt;

}

sub set_log{
  my ($self,$log) = @_;

  $self->{'log'} = $log;
}

## Error handlers.

sub cl_warning_handler{
  my ($self,$command,$handler) = @_;

  my $session = $self->{'session'};
  $session->expect($TIMEOUT,'-re',$self->{'cl_prompt'});

  my $error = $session->before();

  print STDERR "The command $command encountered a CL Warning:\n\n$error\n";

  if (defined $handler){
    print STDERR "Passing off to warning handler\n";
    $handler->($self);
  }

  return;
}

sub cl_error_handler{
  my ($self,$command,$handler) = @_;

  my $session = $self->{'session'};
  $session->expect($TIMEOUT,'-re',$self->{'cl_prompt'});

  my $error = $session->before();

  print STDERR "The command $command encountered a CL ERROR:\n\n$error\n";

  if (defined $handler){
    print STDERR "Passing off to error handler\n";
    $handler->($self);
  }
  else{
    die;
  }

  return;
}

sub eof_handler{
  my ($self,$command,$handler) = @_;

  print STDERR "The command $command suffered an eof error\n";

  if (defined $handler){
    print STDERR "Passing off to death handler\n";
    $handler->($self);
  }
  else{
    die;
  }

  return;
}

sub timeout_handler{
  my ($self,$command,$timeout,$handler) = @_;

  my $session = $self->{'session'};

  $session->print("\cc"); # Send the command a control-c to stop it
  $session->expect($TIMEOUT,'-re',$self->{'cl_prompt'},
		   [eof => sub{&eof_handler($self,"control-c to $command")}]);

  print STDERR "The command \"$command\" timed out after $timeout seconds\n";

  if (defined $handler){
    print STDERR "Passing off to timeout handler\n";
    $handler->($self);
  }
  else{
    die;
  }

  return;
}

## IRAF session variable management.

sub set{
  my ($self,%params) = @_;

  my @output;
  foreach my $key (keys %params){
    my $value = $params{$key};

    my $output;
    if ($self->exists($key)){
      $output = $self->_internal_command("reset $key = $value");
      $self->_add_to_command_history("reset $key = $value");
    }
    else{
      $output = $self->_internal_command("set $key = $value");
      $self->_add_to_command_history("set $key = $value");
    }

    push @output,$output;
  }

  return @output;
}

sub show{
  my ($self,$key) = @_;

  my $output = '';
  if ($self->exists($key)){
    $output = $self->_internal_command("show $key");
    $self->_add_to_command_history("show $key");
  }

  return $output;

}

sub exists{
  my ($self,$key) = @_;

  my $output = $self->_internal_command("print (defvar (\"$key\"))");

  if ($output eq 'yes'){
    return 1;
  }
  else{
    return 0;
  }
}

sub _get_available_commands_and_packages{
  my ($self,$package) = @_;

  my $list = $self->_internal_command('?');

  my @list = split /\n/,$list;

  my @commands;
  my @packages;
  foreach my $line (@list){
    chomp $line;
    $line =~ s/^\s+//;
    my @foo = split /\s+/,$line;

    for (@foo){
      if (m/^([^.]+)\.$/){
	push @packages,$1;
      }
      else{
	push @commands,$_;
      }
    }

  }

  $self->{'available_commands'}{$package} = [@commands];
  $self->{'available_packages'}{$package} = [@packages];

}

sub list_available_commands{
  my ($self,$package) = @_;

  if (!$package){
    foreach my $package (keys %{$self->{'available_commands'}}){

      print STDOUT 'Package: ' . $package . "\n";

      foreach my $command (@{$self->{'available_commands'}{$package}}){

	print STDOUT "\t" . $command . "\n";

      }
    }
  }
  else{

    print STDOUT 'Package: ' . $package . "\n";

    foreach my $command (@{$self->{'available_commands'}{$package}}){

      print STDOUT "\t" . $command . "\n";

    }
  }
}

sub list_available_packages{
  my ($self,$package) = @_;

  if (!$package){
    foreach my $package (keys %{$self->{'available_packages'}}){

      print STDOUT 'Package: ' . $package . "\n";

      foreach my $command (@{$self->{'available_packages'}{$package}}){

	print STDOUT "\t" . $command . "\n";

      }
    }
  }
  else{

    print STDOUT 'Package: ' . $package . "\n";

    foreach my $command (@{$self->{'available_packages'}{$package}}){

      print STDOUT "\t" . $command . "\n";

    }
  }
}

sub package_is_available{
  my ($self,$package_wanted) = @_;

  foreach my $package_is_loaded (@{$self->{'packages'}},'main'){

    foreach my $package (@{$self->{'available_packages'}{$package_is_loaded}}){

      return 1 if $package eq $package_wanted;
    }
  }

  return 0;
}

sub command_is_available{
  my ($self,$command_wanted) = @_;

  foreach my $package_is_loaded (@{$self->{'packages'}},'main'){

    foreach my $command (@{$self->{'available_commands'}{$package_is_loaded}}){

      return 1 if $command eq $command_wanted;
    }
  }

  return 0;
}

sub exec{
  my ($self,%params) = @_;

  my $t = $self->{'session'};

  my @commands;

  if (exists $params{'command'}){
    @commands = split /\;/,$params{'command'};
    map {s/^\s+//} @commands;
  }
  else{
    croak 'You must specify an IRAF command to execute';
  }

  my $timeout = defined $params{'timeout'} ? $params{'timeout'} : undef;
  my $error_handler   = $params{'error_handler'}   || undef;
  my $warning_handler = $params{'warning_handler'} || undef;
  my $death_handler   = $params{'death_handler'}   || undef;
  my $timeout_handler = $params{'timeout_handler'} || undef;

  my ($q_timeout,$q_eof,$q_error,$q_warning,$not_available) = (0,0,0,0,0);

  my @output;

  foreach my $command (@commands){

    $self->_add_to_command_history($command);

    if (length($command) > 2047){
      my $length = length($command);
      croak "The length of the command $command is $length, this exceeds the maximum allowed CL command buffer size of 2047";
    }

    my ($helpfile,$helpname) = (0,'');
    if ($command =~ m/^help\s+(.+)/){
      $helpname = $1;
      $command = "help $helpname | type dev=text";
      $helpfile = 1;
    }

    if (length($command) > 72){

      my @strings = &_break_into_strings(string => $command,
					 max_length => 72);

      my $command_part;
      for my $k (0..($#strings-1)){
	$command_part = $strings[$k];

	$t->print("$command_part \\\r");
	$t->expect($TIMEOUT,'-ex',"$command_part \\\r\n");
	$t->expect($TIMEOUT,'-re',$self->{'continue_prompt'});
      }
      $command_part = $strings[$#strings];

      $t->print("$command_part\r");
      $t->expect($TIMEOUT,'-ex',"$command_part\r\n");
    }
    else{

      $t->print("$command\r");
      $t->expect($TIMEOUT,
		 [timeout => sub {&timeout_handler($self,$command,$TIMEOUT,
						   $timeout_handler);
				  $q_timeout = 1}],
		 '-ex',"$command\r\n");
    }

## Package management.

    my $possible_prompt = '#THIS SHOULD NEVER BE MATCHED#'; # Unless changed.

    if ($command =~ m/^\s*bye\s*$/){ # Removing the current package.
      $self->_deregister_package();
    }
    elsif ($command =~ m/^\s*\w+\s*$/){ # Possibly loading new package.
      if ($self->package_is_available($command)){
	$possible_prompt = $self->_get_package_prompt($command);
      }
    }
##

    $t->expect($timeout,
	       [timeout => sub {&timeout_handler($self,$command,$timeout,
						 $timeout_handler);
				$q_timeout = 1; exp_continue}],
	       [eof     => sub {&eof_handler($self,$command,
					     $death_handler);
				$q_eof = 1; exp_continue}],
	       '-re','^Warning:',sub {&cl_warning_handler($self,$command,
							  $warning_handler);
				    $q_warning = 1; exp_continue},
	       '-re','^ERROR:',sub {&cl_error_handler($self,$command,
						      $error_handler);
				    $q_error = 1; exp_continue},
	       '-ex','No help available for',sub{print STDERR "No help available for $helpname\n";
						 $not_available = 1;
					       },
	       '-re',$possible_prompt,sub{$self->_register_package($command)},
	       '-re',$self->{'cl_prompt'});

    next if ($q_timeout || $q_error || $q_eof || $not_available);

    my $output =  $t->exp_before();
    my @lines = split /\n/,$output;

    foreach my $line (@lines){
      chomp $line;
      $line =~ s/[\000-\037\x80-\xff]//g; # Remove any crud from the output.
      push @output,$line if ($helpfile || $line =~ m/(\d|\w)/);
    }

  }

  if (wantarray){
    return @output;
  }
  elsif(defined wantarray){
    return $output[0];
  }

}

sub load_task{
  my ($self,%params) = @_;

  my $name = $params{'name'} || croak 'Need a name for the task';
  my $file = $params{'file'} || croak "Need a filename for the task $name";
  my $task = $params{'task'} || '';
  my $par_file = $params{'par_file'} || 0; # Is there a param file or not?

  if ($task){
    open(FH,">$file");
    print FH $task . "\n";
    close(FH);
  }
  else{
    croak "You must give either a task command or a file containing the command for task $name" if !-e $file;
  }

# Check whether or not the task has been previously defined,
# the answer will be 'yes' or 'no'.

  my $defined_task = $self->_internal_command("print deftask\(\"$name\"\)");

# If there is not a parameter file to go with this script then we need to
# put a $ in front of the task name.

  $name = "\$" . $name if !$par_file;

# Load the task depending on whether or not it is previously defined.

  if ($defined_task eq 'no'){
    $self->_internal_command("task $name = $file");
    $self->_add_to_command_history("task $name = $file");
  }
  else{
    $self->_internal_command("redefine $name = $file");
    $self->_add_to_command_history("redefine $name = $file");
  }

}

sub _run_command{
  my ($self,$command,@pieces) = @_;

  my $class = ref $self;
  $command =~ s/^$class\:\://;

  foreach my $piece (@pieces){
    if (ref($piece) eq 'HASH'){

      foreach my $key (keys %{$piece}){
	my $value = ${$piece}{$key};
	$command = join ' ',$command,$key;
	$command = join '=',$command,$value if defined $value;
      }
    }
    else{
      $command = join ' ',$command,$piece;
    }
  }

  my @output = $self->exec(command => $command);

  return @output;
}

sub end{
  my $self = shift @_;

  return if $self->{'dead'};	# Ensure end() is not called more than once.

  $self->unload_all_packages;

  my $t = $self->{'session'};

  $t->print("\r");
  $t->expect($TIMEOUT,'-re',$self->{'cl_prompt'});

  $t->print("logout\r");
  $t->expect($TIMEOUT,"logout\r\n");

  $t->soft_close();

  $self->_unlock_startdir;

  $self->{'dead'} = 1;
}

sub DESTROY{
  my $self = shift @_;

  $self->end();

}

sub AUTOLOAD{
  no strict 'refs';
  my $self = shift @_;

  if ($AUTOLOAD =~ /.*::get_(\w+)/ && exists $self->{$1}){
    my $attr_name = $1;

    *{$AUTOLOAD} = sub { return $_[0]->{$attr_name}};

    return $self->{$attr_name};
  }
  else{
    my @output = _run_command($self,$AUTOLOAD,@_);
    if (wantarray){
      return @output;
    }
    elsif (defined wantarray){
      return $output[0];
    }
  }

}

# Description of subroutine _break_into_strings():
#
# This is a subroutine to take a long string and break it, on white
# space, into sub-strings that are less than or equal to some,
# user-specified maximum length.
#
# It must not break the string in the middle of an assignment context,
# e.g. foo = bar, this can only be broken before the foo or after the
# bar.
#
# Anything that is single or double-quoted in an assignment context
# must not be broken either. So, foo = "bar baz quux igwop" can only
# break before the foo or after the closing double-quote following the
# igwop. 
#
# Single-quotes must be allowed inside double-quotes and vice-versa,
# escaping of quote signs must also be allowed, e.g. foo = "a'b",
# foo = "a\"b", foo = 'a"b', foo = 'a\'b'
#
# The routine takes in two parameters, the long string to be broken
# and the maximum allowed length of the returned strings. Possibly, a
# parameter controlling the string separator to split the input string
# on could be added. This would also be used for joining the strings
# again after tokenisation.
#
# The routine returns the list of correct length strings upon
# completion.
#
# Currently, single over-length strings are allowed where a long
# assignment occurs. A warning is given but possibly an error should
# be thrown but for my case the maximum length I will set will be much
# lower than the real maximum allowed length.
#

sub _break_into_strings{
  my %params = @_;

  my $long_string = $params{'string'}     || croak 'Need an input string';
  my $max_length  = $params{'max_length'} || 75;

  my @tokens = split /\s+/,$long_string;
  my @tokens2;

# Variables for storing current state.

  my ($in_assign,$equals,$in_squote,$in_dquote) = (0,0,0,0);

  my $posn = 0;
  for my $token (@tokens){

    if ($token eq '=') {
      $in_assign = 1;
      $equals = 1;
    }

    if ($in_assign){

      if ($equals){

	# Append that equals sign along with the necessary whitespace.

	$tokens2[-1] .= ' =';

	# Look ahead to see what's coming and see if we are going to start
	# a section of double or single quotes and change state if so.

	if ($tokens[$posn+1] =~ m/^\"/){
	  $in_dquote = 1;
	}
	elsif ($tokens[$posn+1] =~ m/^\'/){
	  $in_squote = 1;
	}
      }
      else{

	# Append the token plus necessary whitespace.

	$tokens2[-1] = $tokens2[-1] . ' ' . $token;

	# Work out if we need to close this assignment section yet.

	if (!$in_squote && !$in_dquote){ # Single value to append so stop.
	  $in_assign = 0;
	}
	elsif ($in_dquote && $token =~ m/(\\*)\"$/){
	  my $num = length $1;
	  if (!$num || (($num % 2) == 0)){ # Even num, thus not escaped.
	    $in_dquote = 0;
	    $in_assign = 0;
	  }
	}
	elsif ($in_squote && $token =~ m/(\\*)\'$/){
	  my $num = length $1;
	  if (!$num || (($num % 2) == 0)){ # Even num, thus not escaped.
	    $in_squote = 0;
	    $in_assign = 0;
	  }
	}

      }

      $equals = 0; # Always turn off the equals state.
    }
    else{
      push @tokens2,$token; # Nowt special here just add token to output stack.
    }

    ++$posn; # Keeping track of position in input stack.
  }

  # Build final stack of output strings with correct maximum length.
  # Note that if a single string is longer than the allowed maximum
  # length it will still be pushed on, thus best to ensure max_length
  # is a bit less than the real maximum allowed length. I think it's
  # better this way for my situation than to lose strings or keep
  # breaking.

  my @output;
  my $i = 0;
  $output[$i] = shift @tokens2;

  while (defined (my $line = shift @tokens2)){

    if ((length($output[$i]) + length($line) + 1) <= $max_length){
      $output[$i] = $output[$i] . ' ' . $line;
    }
    else{
      ++$i;

      my $length = length($line);
      if ($length > $max_length){
	carp "WARNING: Single assignment length ($length) is longer than maximum allowed string length ($max_length) in call to subroutine _break_into_strings(), will use anyway";
      }

      $output[$i] = $line;

    }
  }

  return @output;
}


1;
__END__

=head1 NAME

Astro::IRAF::CL - Perl interface to the IRAF CL interactive session.

=head1 VERSION

0.1

=head1 SYNOPSIS

 use Astro::IRAF::CL;

 my $iraf = Astro::IRAF::CL->new();

 my $output1 = $iraf->exec(command => 'print "hello world"',
                           timeout => 10);

 my $output2 = $iraf->print('"hello world"');

=head1 DESCRIPTION

This is a Perl module that provides an object-orientated interface to the IRAF CL interactive session, it is built on top of the Perl Expect module. You can script almost anything through this module that you can do in a normal interactive CL session.

This module provides several improved, and more Perl-like, interfaces to various IRAF systems, such as session variables, the management of loading/unloading IRAF packages and the session history. It also provides the ability to specify maximum run times for commands, and the clean handling of these time outs and other types of errors and exceptions. All functions are called in an object-orientated fashion allowing several concurrent interpreter sessions if desired.

=head2 Beginning an IRAF CL session

The IRAF CL session is started by creating an object via the new() call, for example:

  my $iraf = Astro::IRAF::CL->new();

Various input parameters can be specified: iraf_start, debug, work_dir, display_startup, log, packages (ARRAY), set (HASH), for example:

  my $iraf = Astro::IRAF::CL->new(debug => 1,
                                  log => *FH,
                                  set => {foo => 1,
                                          bar => 2},
                                  packages => ['mscred','cfh12k']);


=over 4

=item

B<debug> controls how much output is sent to the stderr, this is generally just the command that was actually executed within the IRAF session, its default is zero, i.e. no extra output.

=item

B<work_dir> is where any commands should be executed, its default is the current directory.

=item

B<display_startup> controls whether or not to show all the information (e.g. motd) from the IRAF startup, not much use in a script so off (zero) by default.

=item

B<log> is the filehandle to which logging information should be sent, the default is STDERR.

=item

B<set> is a list of variables to setup when the IRAF session is started.

=item

B<packages> is list of IRAF packages to load on startup.

=back

As with a normal IRAF CL session when a CL object is created it has to be done from the place where the uparm directory and login.cl file are located. If you have not created these files it is done using mkiraf(1). This place can be specified via the B<iraf_start> parameter passed in through the new() routine call or set via the IRAF_START environment variable (iraf_start has precedence over IRAF_START). Otherwise this place is chosen automatically by the module based on a number of criteria. These are in order of priority:

=over 4

=item 1.

$HOME

=item 2.

$HOME/iraf

=item 3.

/home/$username/iraf

=item 4.

/home/$username

=back

the script uses the first directory where it finds the file F<login.cl> and the directory F<uparm>. $HOME is the environment variable of that name. The variable $username is found by the script using getlogin(3C), getpwuid(3C), the environment variable $USER or the command whoami(1), in that order of preference.

=head2 Loading/Unloading IRAF packages

=over 4

=item *

load_package($package) - load an IRAF package, will check to make sure the package exists and will die if it does not.

=item *

package_is_loaded($package) - Returns 1 if package is loaded, else 0, useful for ensuring a package is not loaded twice (this isn't fatal).

=item *

package_exists($package) - Checks if an IRAF package is available for loading, (via the IRAF command "deftask") returns 1, if true, else 0.

=item *

unload_package($package) - Unload a package (the same as typing "bye" in CL). Note that you must unload in the correct order (last in - first out) or the script will die as it would not be able to keep a correct track of the current package and its associated cl prompt.

=item *

unload_all_packages - Unload all packages that have been loaded in the current session, this is called automatically when the script ends or the object goes out of scope in anyway.

=item *

get_current_package - Returns the name of the current package, if none is loaded you get an undefined string.

=item *

list_available_packages - List all the currently available packages.

=item *

list_available_commands - List all the currently available commands.

=item *

package_is_available($package) - Slightly different from package_exists(), as it is less rigorous. It purely checks whether the package should exist, not whether it is actually defined.

=item *

command_is_available($command) - Similar to package_is_available() but for commands.

=back

=head2 Setting/Reading IRAF variables

These are similar in style to shell environment variables and last for the full length of the IRAF CL session. I have effectively overloaded a couple of the functions and added the exists() command.

=over 4

=item *

set(key1 => $value1, key2 => $value2, key3 => $value3) - set any number of variables to their associated values.

=item *

show($key) - returns the value of the variable.

=item *

exists($key) - checks for the existence of the variable, returns 1 or 0.

=back

=head2 Executing commands

There are two ways in which to execute IRAF CL commands, the full featured way provides error handling and time out capabilities, as seen below:

  $iraf->exec(command => 'print "hello world"',
         timeout => 10,
         timeout_handler => \&timeout_sub,
         death_handler => \&death_sub,
         error_handler => \&error_sub);

The second method I have named B<"direct invocation">, this is a much simpler method of calling an IRAF command, for example:

  $iraf->print('"hello world"')

Note here that strings where double-quotes are needed in IRAF should be protected from Perl with single-quotes. There are various ways to ensure the continued existence of quotes, see the perl documentation for examples.

The direct invocation method does not provide any system for defining exception handlers this may change in the future. There is, however, something to be said for keeping this simple method and the complex exec method for more explicitly defining commands.

Note that some IRAF commands are overloaded in this module, for example, set() and show(). This allows the commands to be extended or made more Perl like, in general overloading commands may be a bad idea but for simple things like variable control it is very useful.

=head2 Error/Exception handling

As can be seen from the exec() example above references to subroutines can be passed in to deal with any problems that are encountered on execution of the command. A maximum run time (timeout) can be specified and a handler to deal with the timeout, although this isn't required. If the handlers are not specified the script will die on encountering any of the exceptions. It is hoped that in the future the code will be able to deal with non-fatal warnings and possibly and generic event to allow for a fully event-driven system to be developed.

=over 4

=item *

B<Timeout handling>

By default a script will die upon timeout, this can be modified in anyway you like to keep the script going and handle the exception cleanly, an example of a handler is:

  my $timed_out = 0;
  $iraf->exec(command => 'print "hello"',
              timeout => 2,
              timeout_handler => sub {print $command . " timed out\n"; $timed_out = 1});

The script can then see from the $timed_out variable that the timeout has occured and can clean up accordingly and move on. Here i have used an anonymous subroutine instead of a reference to a subroutine as it is fairly small.

=item *

B<EOF/Death handling>

This is the situation when the whole CL interpreter has died, this is a not uncommon occurence with IRAF as some packages are not quite as robust as they should and the CL is quite fragile in certain situations. If have a large number of jobs to do you do not want to find the program has died fairly early on so you should nominate a handler. In this case the handler will need to call the restart() routine and will also need to change to the correct directory, (this will probably be automated at some point). The restart routine will reload any previously loaded packages. restart will begin a new session with all the parameters that were specified when the object was created. 

  $iraf->cd($workdir);
  $iraf->exec(command => 'print "hello"',
              death_handler => sub {$iraf->restart(); $iraf->cd($workdir)});

=item *

B<CL error handling>

A CL error is encountered when the command executed returns with the ERROR code and a message as to what happened. This is dealt with in the same way as the timeout handler above:

  my $error = 0;
  $iraf->exec(command => 'print "hello"',
              error_handler => sub {print "error occurred\n"; $error = 1});

=item *

B<CL warning handling>

There is currently no way to handle CL warnings, it is my intention to implement this feature at some point in the future.

=back

=head2 Ending and restarting

The CL object will automatically unload all packages and cleanly shut down the IRAF CL interpreter when your script ends or the object goes out of scope. You can force it to end by calling the end() function, i've never found this to be necessary though. The CL interpreter can be restarted using the restart() function, this is most useful, as demonstrated above, when the CL session has died.

=head2 Loading Tasks

  load_task(name => $name,         # Required
            task => $task,         # Not required
            file => $filename,     # Required
            parfile => $yes_or_no) # Defaults to no (zero)

If the task parameter is defined it is considered to contain the full text of the task and if the filename is also specified then the task is written into that file. If the task parameter is not specified the task is considered to be already contained in the file and that is loaded. An IRAF task may or may not have an associated parameter file, the syntax for loading a task is dependent on whether there is a parameter file. Once the task has been loaded it can be called using exec() or the direct invocation method, for example:

  $iraf->load_task(name => 'hello_world',
                   task => 'print "hello world"',
                   file => 'hello_world.cl');

  $iraf->hello_world();

If you call the load_task command more than once with the same name then it will correctly redefine the task.

=head2 Logging the session

By default the session is logged to STDERR, you can change this to any file handle you like via:

  set_log(*FILEHANDLE)

=head2 Session history

Every command that you execute in the interpreter is stored in the Perl object and can be recalled and executed, the module often executes IRAF commands 'behind-the-scenes' these are not logged to avoid confusion. The commands available are:

=over 4

=item *

get_from_command_history($position) - returns the command as a string.

=item *

exec_from_history($position,%params) - returns any output from the command that has been executed.

=back

The position in the list is based on them being pushed onto a Perl array, so the most recent command is 0 (zero). The %params is the same as the hash passed into the exec() function.

=head1 NOTES

You can create as many concurrent IRAF objects as you want (or your system can manage anyway). You should note that each one really needs its own uparm directoctory from which to work to avoid parameter value collisions which could cause chaos. This is not a bug of this Perl module but a problem with the IRAF CL session not knowing when param files are already in use and how to cope with this issue.

Some IRAF programs may need more persuasion than others to believe that they are being used in a non-interactive mode (well non-graphical anyway). If you have problems with this, you could try using the IRAF command "stty xterm", this has worked for me in the past for problems with the nmisc package not co-operating.

The script will convert long commands into lots of shorter strings and enter each into the CL interpreter followed by a line continuation. This allows much longer commands to be entered than by just sending it all in one go. The routine tries to break the string into lengths of 75 characters, as a standard terminal is 80 characters wide - 4 are required for the prompt and 1 for the continuation "\" character. A string may not be broken inside an assignment, (i.e. foo = 1), and also a continuous long string (i.e. no spaces) must not be broken so occasionally the rule of 75 characters must be ignored, in this case you will get a warning printed to STDERR, this is not a problem, it's just good to know about it.

=head1 BUGS

These are not so much bugs as short-comings with the current code.

There is no way to specify a time out length, or any error/exception handlers when executing the command directly rather than via the exec() call.

There is currently no way when executing a command from the history to also recall any previously specified time out or error/exception handlers. This can be thought of as both a bug and a feature.

Any bugs, modifications or suggestions for improvements should be sent to the email address given below.

=head1 COPYRIGHT

Copyright (C) 1999-2002 Stephen Quinney. All Rights Reserved.

This program was written as part of the NOAO Fundamental Plane project whilst Stephen Quinney was funded by a grant from PPARC and is free software; you can redistribute it and/or modify it under the terms of the GNU Public License. This software comes with absolutely no warranty and the author accepts no responsibility for any unpleasant outcomes from its usage. If this code eats your data it is not my fault... ;-)

=head1 AUTHOR

S.J.Quinney, <irafperl@jadevine.org.uk>

=head1 SEE ALSO

perl(1). cl(1). mkiraf(1).

=cut
