####################################################
## Config::Framework.pm
## Andrew N. Hicox	<andrew@hicox.com>
##
## This package provides configuration info to
## homegrown modules.
###################################################


## Global Stuff ###################################
  package Config::Framework;
  use 5.6.0;
  use Carp;
  
  use Data::DumpXML;
  use Data::DumpXML::Parser;

  require Exporter;
  use AutoLoader qw(AUTOLOAD);
 
## Class Global Values ############################ 
our @ISA = qw(Exporter);
our $VERSION = '2.5';
our $errstr = ();
our @EXPORT_OK = ($VERSION, $errstr);
our @temp = split (/\//,$0);
our %GLOB_CONFIG = (
	#name of program running this code
	'program'		=> $temp[$#temp],
	#virtual root: everything lives under this
	'v_root'			=> "<pop>v_root</pop>",
	#global configuration files live in this subdirectory
	'config_loc'		=> "<pop>config_loc</pop>",
	#sybase home directory
	'SYBASE'			=> "<pop>SYBASE</pop>",
	#oracle home directory
	'ORACLE_HOME'		=> "<pop>ORACLE_HOME</pop>",
	#set this library path
	'LD_LIBRARY_PATH'	=> "<pop>LD_LIBRARY_PATH</pop>",
	#where sendmail resides
	'sendmail'			=> "<pop>sendmail</pop>",
	#someone to phone home to when things go really wrong
	'admin'				=> "<pop>admin</pop>",
	#export these keys from GLOB_CONFIG to the shell environment
	'EnvExportList'		=> [
		"SYBASE",
		"ORACLE_HOME",
		"ORACLE_SID",
		"ARTCPPORT",
		"LD_LIBRARY_PATH"
	],
	#we're using this encryption module
	'Crypt'				=> "<pop>Crypt</pop>",
	#it's under the virtual doormat
	'Key'				=> "<pop>Key</pop>",
	#automatically load child configs
	'LoadChildren'		=> 1
 );


## new ############################################
sub new {
	my $class = shift();
	my $self = bless ({@_}, $class);
	
	#insert default global config items unless overriden by user input
	foreach (keys %GLOB_CONFIG){ $self->{$_} = $GLOB_CONFIG{$_} unless exists($self->{$_}); }
	
	#export items in EnvExportList
	foreach (@{$self->{'EnvExportList'}}){ $main::ENV{$_} = $self->{$_} if exists($self->{$_}); }
	
	#export other user-defined export items
	foreach (keys %{$self->{'Export'}}){ $main::ENV{$_} = $self->{'Export'}->{$_}; }
	
	#set up a shortcut to the applications 'framework' directory
	$self->{'FrameworkDir'} = "$self->{'v_root'}/$self->{'config_loc'}/ApplicationFrameworks/$self->{'program'}";
	
	#fix string-specified files for multiple file compatibility
	if ((exists ($self->{'File'})) && (ref ($self->{'File'}) ne "ARRAY")){
		my $temp = $self->{'File'};
		delete($self->{'File'});
		push (@{$self->{'File'}}, $temp);
	}
	
	#load all of the specified configs
	foreach (@{$self->{'File'}}){
		$self->LoadConfig(File => $_) || do {
			$errstr = "new: ";
			$errstr.= $self->{'errstr'};
			return (undef);
		};
	}
	
	#load the secure config, if directed
	if ($self->{'GetSecure'}){
		$self->LoadConfig(
			File 			=> "$self->{'v_root'}/$self->{'config_loc'}/passwds.xml",
			configNamespace	=> "Secure"
		) || do {
			$errstr = "new: can't load secure config: $self->{'errstr'}";
			return (undef);
		};
	}
	
	#weed out descriptors under Secure namespace
	#ugly hack
	foreach (keys %{$self->{'Secure'}}){
		if (ref ($self->{'Secure'}->{$_}) eq "HASH"){
			if (exists($self->{'Secure'}->{$_}->{'content'})){
				$self->{'Secure'}->{$_} = $self->{'Secure'}->{$_}->{'content'};
			}
		}
	}
	
	#send back the constructed object
	return ($self);
}



## True for perl include ##########################
 1;
__END__
## AutoLoaded Methods 

## LoadXMLConfig ##################################
sub LoadXMLConfig {
	my ($self, %p) = @_;
	
	#File is a required option
	exists($p{'File'}) || do {
		$self->{'errstr'} = "LoadXMLConfig: 'File' is a required option";
		return (undef);
	};
	
	#check that the specified file exists
	(-e $p{'File'}) || do {
		$self->{'errstr'} = "LoadXMLConfig: specified file ($p{'File'}) does not exist";
		return (undef);
	};
	
	#open da file
	open (INFILE,"$p{File}") || do {
         $self->{'errstr'} = "LoadXMLConfig: can't open specified file ($p{'File'}) / $!";
         return (undef);
     };
     
     #flatten it into a big 'ol string
     my $data = join ('',<INFILE>);
     
     #at this point we're done with the filehandle
     close (INFILE);
     
     #if the file type was binary, we can presume it's encrypted
     if (-B $p{'File'}){
     	#use global key and crypt unless otherwise specified
		foreach ('Key','Crypt'){ $p{$_} = $self->{$_} unless exists($p{$_}); }
		#get the cipher
		require Crypt::CBC;
		my $cipher = new Crypt::CBC($p{'Key'},$p{'Crypt'});
		#decrypt the data
		$data = $cipher->decrypt($data);
	}
	
	#get a Data::DumpXML::Parser parser object unless we have one already
	exists($self->{'DDXMLParser'}) || do {
		$self->{'DDXMLParser'} = Data::DumpXML::Parser->new;
	};
	
	#parse it
	my $info = $self->{'DDXMLParser'}->parsestring($data) || do {
		$self->{'errstr'} = "LoadXMLConfig: failed to parse XML data from $p{'File'} / $!";
		return (undef);
	};
	
	#if there's only one element just return it
     if ($#{$info} == 0){
         return ($info->[0]);
     }else{
         return ($info);
     }
}


## LoadConfig #####################################
sub LoadConfig {
	my ($self, %p) = @_;
	
	#File is a required option
	exists($p{'File'}) || do {
		$self->{'errstr'} = "LoadConfig: 'File' is a required option";
		return (undef);
	};
	
	#find the file
	(-e $p{'File'}) || do {
		#if it exists under config_loc use that
		if (-e "$self->{'v_root'}/$self->{'config_loc'}/$p{'File'}"){
			$p{'File'} = "$self->{'v_root'}/$self->{'config_loc'}/$p{'File'}";
		#otherwise if it exists under the FrameworkDir, use that
		}elsif (-e "$self->{'FrameworkDir'}/$p{'File'}"){
			$p{'File'} = "$self->{'FrameworkDir'}/$p{'File'}";
		#other-otherwise if it exists in the user's home directory, use that
		}elsif (-e "$ENV{'HOME'}/$p{'File'}"){
			$p{'File'} = "$ENV{'HOME'}/$p{'File'}";
		#else there's a problem
		}else{
			$self->{'errstr'} = "LoadConfig: can't find the file $p{'File'}";
			return (undef);
		}
	};
	
	#load it up
	my $data = $self->LoadXMLConfig(%p) || do {
		$self->{'errstr'} = "LoadConfig: $self->{'errstr'}";
		return (undef);
	};
	
	#if the file dosen't define a config namespace ...
	exists($data->{'configNamespace'}) || do {
		#if there is a user-defined namespace, use that
		if (exists($p{'configNamespace'})){
			$data->{'configNamespace'} = $p{'configNamespace'};
		}else{
			$self->{'errstr'} = "LoadConfig: $p{'File'} does not define a 'configNamespace', and none has been ";
			$self->{'errstr'}.= "specified with this function call. I don't know where to put this data!";
			return (undef);
		}
	};
	
	#if theres a parent namespace specified, put it under there
	#otherwise stash it in the object under it's own namespace
	if (exists($p{'Parent'})){
		$self->{$p{'Parent'}}->{$data->{'configNamespace'}} = $data;
	}else{
		$self->{$data->{'configNamespace'}} = $data;
	}
	
	#keep a map so that WriteConfig can write by namespace instead of filename
	$self->{'_ConfigMap'}->{$data->{'configNamespace'}} = $p{'File'};
	
	#load any child configs
	if (($self->{'LoadChildren'}) && exists($data->{'children'})){
		foreach (@{$data->{'children'}}){
			$self->LoadConfig(
				File	=> $_,
				Parent	=> $data->{'configNamespace'}
			) || do {
				$self->{'errstr'} = "LoadConfig: failed to load child config ($_) for parent ($data->{'configNamespace'}) $self->{'errstr'}";
				return (undef);
			};
		}
	}
	
	#'tis all good
	return (1);
}


## WriteConfig ####################################
# store values under a given namespace to a file.
sub WriteConfig {
	my ($self, %p) = @_;
	
	#configNamespace is a required option
	exists($p{'configNamespace'}) || do {
		$self->{'errstr'} = "WriteConfig: 'configNamespace' is a required option.";
		return (undef);
	};
	
	#dump given namespace down to xml
	my $xml_data = Data::DumpXML::dump_xml($self->{$p{'configNamespace'}});
	
	#if 'File' is specified, use that, otherwise use the file in _ConfigMap
	exists($p{'File'}) || do {
		exists($self->{'_ConfigMap'}->{$p{'configNamespace'}}) || do {
			$self->{'errstr'} = "WriteConfig: 'File' is not specified, and I can't find a file in _ConfigMap! ";
			$self->{'errstr'}.= "I don't know where to write this data!";
			return (undef);
		};
		$p{'File'} = $self->{'_ConfigMap'}->{$p{'configNamespace'}};
	};
	
	#since (presumably) anything in _ConfigMap is garanteed to exist, then we can use
	#the same file precedence matching as LoadConfig!!! 'cept this time we're checking
	#for writeability.
	#find the file
	(-w $p{'File'}) || do {
		#if it exists under config_loc use that
		if (-w "$self->{'v_root'}/$self->{'config_loc'}/$p{'File'}"){
			$p{'File'} = "$self->{'v_root'}/ $self->{'config_loc'}/$p{'File'}";
		#otherwise if it exists under the FrameworkDir, use that
		}elsif (-w "$self->{'FrameworkDir'}/$p{'File'}"){
			$p{'File'} = "$self->{'FrameworkDir'}/$p{'File'}";
		#other-otherwise if it exists in the user's home directory, use that
		}elsif (-w "$ENV{'HOME'}/$p{'File'}"){
			$p{'File'} = "$ENV{'HOME'}/$p{'File'}";
		#not having a file at all isn't a problem here, it might be new!
		}
	};
	
	#ok check if the file is binary, if it is, or if the 'Encrypt' option is set
	#then we need to encrypt it before we write it.
	if ((-B $p{'File'}) || ($p{'Encrypt'})){
		#use global key and crypt unless otherwise specified
		foreach ('Key','Crypt'){ $p{$_} = $self->{$_} unless exists($p{$_}); }
		#get the cipher
		require Crypt::CBC;
		my $cipher = new Crypt::CBC($p{'Key'},$p{'Crypt'});
		$xml_data = $cipher->encrypt($xml_data);
	}
	
	#dump it down to the file
	open (OUTFILE, ">$p{'File'}") || do {
		$self->{'errstr'} = "WriteConfig: can't open file ($p{'File'}) for writing $!";
		return (undef);
	};
	print OUTFILE $xml_data ;
	close (OUTFILE);
	return (1);
}


## AlertAdmin #####################################
sub AlertAdmin {
	my ($self, %p) = @_;
	
	#Message is requred
	exists($p{'Message'}) || do {
		$self->{'errstr'} = "AlertAdmin: 'Message' is a required option";
		return (undef);
	};
	
	#default 'To' is the admin
	exists($p{'To'}) || do {
		push (@{$p{'To'}}, $self->{'admin'});
	};
	
	#fix stringy 'To''s to work with arrayified ones
	if ((exists($p{'To'})) && (ref($p{'To'}) ne "ARRAY")){
		my $temp = $p{'To'};
		delete($p{'To'});
		push(@{$p{'To'}}, $temp);
	}
	
	#if we're in debug mode, just print the message to stdout and be done
	if ($self->{'debug'}){
		print $p{'Message'}, "\n";
		return (1);
	}
	
	#open sendmail pipe
	open (SENDMAIL, "|$self->{sendmail} -oi -t -fnobody") || do {
		#can't open sendmail, spew message to v_root/var/last_resort.log
		open (LAST_RESORT, ">>$self->{'v_root'}/var/log/last_resort.log") || do {
			print "AlertAdmin: can't open sendmail or last_resort.log $p{'Message'}\n";
			return (undef);
		};
		my $time = time();
		print LAST_RESORT "[$time]: can't open sendmail! $p{'Message'}\n";
		close (LAST_RESORT);
	};
	
	#give sendmail the message
	print SENDMAIL "From: nobody ($self->{'program'})\n";
	print SENDMAIL "To: ", join (', ', @{$p{'To'}}), "\n";
	print SENDMAIL "Subject: Auto-generated Alert from: $self->{program}\n";
	print SENDMAIL "Reply-To: nobody\n";
    print SENDMAIL "Errors-To: nobody\n\n";
    print SENDMAIL "\n\n";
    print SENDMAIL $p{Message}, "\n";
    
    #spew the user's environment if specified
    if ($p{ENV}){
		print SENDMAIL "\n[ENV] --------------------------------------------\n";
        foreach (keys %ENV){ print SENDMAIL "[$_]: $ENV{$_}\n"; }
    }
    
    #send the message 
    close (SENDMAIL);
    
    #if specified, log the message as well
    if ($p{'Log'}){ $self->Log(%p); }
    
    #if specified, die as well
    if ($p{'Die'}){ die ($p{'Message'}, "\n"); }
    
    #shiver me timbers, maytee
    return (1);
}


## Log ############################################
## NOTE: need to build syslog support into this
## eventually
sub Log {
	my ($self, %p) = @_;
	
	#Message is required
	exists($p{'Message'}) || do {
		$self->{'errstr'} = "Log: 'Message' is a required option";
		return (undef);
	};
	
	#Log is required
	exists($p{'Log'}) || do {
		$self->{'errstr'} = "Log: 'Log' is a required option (path to and name of logfile)";
		return (undef);
	};
	
	#append it to the log file
	open (LOG, ">>$self->{'v_root'}/$p{'Log'}") || do {
		$self->{'errstr'} = "Log: can't open log file ($p{'Log'}: $!\n";
		return (undef);
	};
	my $time = time();
	print LOG "[$time]: $p{'Message'}\n";
	close (LOG);

	#if specified, warn the message to stdout
	if ($p{Echo}){ carp $p{'Message'}; }

	#if specified, die as well
    if ($p{Die}){ die ($p{'Message'}, "\n"); }

	#shenannigans
	return (1);

}