# -*- perl -*-
#
#
#   Cisco::Conf - a Perl package for configuring Cisco routers via TFTP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#

package Cisco::Conf;

use strict;

require Net::Telnet;
require Socket;
require IO::File;
require Safe;
require Data::Dumper;

$Cisco::Conf::VERSION = '0.10';


=pod

=head1 NAME

Cisco::Conf - Perl module for configuring Cisco routers via TFTP

=head1 SYNOPSIS

  use Cisco::Conf;

  # Set the path of the main configuration file
  $configFile = '/usr/local/cisco/etc/config';

  # Add a new machine to the configuration file
  Cisco::Conf->Add($configFile,
		   {'name' => 'myrouter',
		    'description' => 'My Internet gateway',
		    'users' => ['root', 'joe'],
		    'host' => '192.168.1.1',
		    'username' => 'itsme',
		    'password' => 'secret',
		    'enable_password' => undef  # Prompt password
		   });

  # Remove a machine from the configuration file
  Cisco::Conf->Remove($configFile, 'myrouter');

  # Create a configuration object by reading it from the
  # configuration file
  $conf = Cisco::Conf->Read($configFile, 'myrouter');

  # Edit a machine's configuration (uses $ENV{'EDITOR'})
  $conf->Edit($editor, $file, $tmpDir);

  # Feed a machine's configuration into RCS
  $conf->RCS($file, "in");

  # Load a machine's configuration and save it in 'myfile'
  $conf->Load('myfile');

  # Strip comments from a machine configuration in $configuration
  $stripped = Cisco::Conf->Strip($configuration);

  # Read a configuration from 'myfile' and save it into the router
  $conf->Save('myfile', $write);

  # Return a list of all configurations that the current user may
  # access
  @list = Cisco::Conf->Info($configFile);

=head1 DESCRIPTION

This module offers a set of methods for creating and managing Cisco
configurations. Configurations are stored as plain text files,
including comments. Comments are indicated by an exclamation mark
and may terminate any line. Example:

    ! Here come the interfaces
    interface Ethernet 0   ! Local LAN
    ...

All methods throw a Perl exception in case of errors, thus you
should encapsulate them with an C<eval>, like this:

    $@ = '';
    eval {
        Cisco::Conf->Add('/usr/local/cisco/etc/configurations',
			 {'name' => 'myrouter',
			  ...
			 });
    };
    if ($@) {
	print STDERR "An error occurred: $@\n";
	exit 1;
    }

The following methods are offered by the module:


=head2 Add($configFile, \%attr)

(Class method) Adds a new configuration to the list of configurations
in the file C<$configFile>. A configuration is represented by the hash
ref C<\%attr> with a number of attributes, including

=over 8

=item name

A symbolic and short name for the configuration, unique in the
list of configurations.

=item description

A textual description of the configuration.

=item host

The routers host name or IP address

=item username

=item password

=item enable_password

The routers username, login and enable passwords. If these attributes
are not present or have a value of undef, the methods will prompt for
passwords.

=item file

File name where the machine configuration is stored, for example
C</usr/local/cisco/etc/mycisco.conf>.

=back

Only root may add or remove configurations.

=cut


sub _ReadConfigFile ($$) {
    my($class, $file) = @_;

    if (! -r $file) {
	die "Cannot read configuration file $file";
    }
    my $compartment = Safe->new();
    $@ = '';
    my $config = $compartment->rdo($file);
    if ($@) {
	die "Error while configuration file $file: $@";
    }
    $config;
}

sub _SaveConfigFile ($$$) {
    my($class, $file, $config) = @_;

    my $dumped = Data::Dumper->new([$config], ['CONFIGURATION']);
    $dumped->Indent(1);
    my $cstr = $dumped->Dump();

    my (@comments) =
	(['etc_dir',
	  'The directory where to create router configurations'
	 ],
	 ['tftp_dir',
	  'The directory for transferring files from or to the routers'
	 ],
	 ['tftp_prefix',
	  "The TFTP servers root directory, if any. For example, if a client\n"
	  . "requests '/my.conf' and the TFTP server returns '/tftp/my.conf'\n"
	  . "then a prefix '/tftp' should be used."
	 ],
	 ['editors',
	  'A list of editors that may be used for modifying configurations'
         ],
	 ['ci',
	  'The command being executed for running the revision control system'
	 ],
	 ['local_addr',
	  'This hosts IP number'
	 ],
	 ['hosts',
	  "The list of hosts that can be configured.\n\n"
	  . "Use the following attributes:\n\n"
	  . "    name - Short name of router, must be unique in the list\n"
	  . "    description - Router description\n"
	  . "    users - List of users that may configure this router\n"
	  . "    host - Routers host name\n"
	  . "    username - Routers login password (may be undef)\n"
	  . "    password - Routers login password (may be undef)\n"
	  . "    enable_password - Routers enable password (may be undef)\n"
	 ],
	 ['tmp_dir',
	  'A directory for creating temporary files.'
	 ]);

    my $ref;
    foreach $ref (@comments) {
	my $attr = $ref->[0];
	my $comment = '';
	my $line;
	foreach $line (split(/\n/, $ref->[1])) {
	    $comment .= "# $line\n";
	}
	$cstr =~ s/^(  \'\Q$attr\E)/$comment$1/m;
    }

    my $fh;
    $@ = '';
    eval { require IO::AtomicFile; };
    if ($@) {
	$fh = IO::File->new($file, "w");
    } else {
	$fh = IO::AtomicFile->open($file, "w");
    }
    if (!$fh) {
	die "Cannot create configuration file $file: $!";
    }
    if (!$fh->print($cstr)) {
	if ($fh->isa("IO::AtomicFile")) {
	    $fh->delete();
	}
	die "Error while writing $file: $!";
    }
    if (!$fh->close()) {
	die "Fatal error while writing $file, contents may be destroyed: $!";
    }
}

sub Add($$$) {
    my($class, $file, $attrs) = @_;
    my($config) = $class->_ReadConfigFile($file);

    if ($< != 0  ||  $> != 0) {
	die "Must be root to add new routers.\n";
    } 

    # Verify the new configuration
    my($errors) = '';
    if (!$attrs->{'name'}) {
	$errors .= " Configuration name is missing.";
    }
    if (exists($config->{'hosts'}->{$attrs->{'name'}})) {
	$errors .= sprintf(" A host %s already exists.", $attrs->{'name'});
    }
    if (!$attrs->{'description'}) {
	$errors .= " Configuration description is missing.";
    }
    if (!$attrs->{'host'}) {
	$errors .= " Host name is missing.";
    }
    if (!Socket::inet_aton($attrs->{'host'})) {
	$errors .= sprintf(" Cannot resolv host name %s.", $attrs->{'host'});
    }
    if ($errors) {
	die "Configuration errors: $errors";
    }

    my $name = $attrs->{'name'};
    $config->{'hosts'}->{$name} = $attrs;

    $class->_SaveConfigFile($file, $config);
    bless($attrs, (ref($class) || $class));
    $attrs;
}


=pod

=head2 Remove($configFile, $name)

(Class method) Removes configuration C<$name> from the list of configurations
in the file C<$configFile>.

Only root may add or remove configurations.

=cut

sub Remove($$$) {
    my($class, $file, $name) = @_;

    if ($< != 0  ||  $> != 0) {
	die "Must be root to remove routers.\n";
    } 

    my($config) = $class->_ReadConfigFile($file);
    if (!exists($config->{'hosts'}->{$name})) {
	die "A host $name doesn't exist.";
    }
    delete $config->{'hosts'}->{$name};
    $class->_SaveConfigFile($file, $config);
    $class;
}


=pod

=head2 Read($configFile, $name)

(Class method) Reads the configuration of the host C<$name> from the
configuration file C<$configFile> and returns a I<Cisco::Conf> instance
representing the host.

=cut


sub Read ($$$) {
    my ($class, $configFile, $name) = @_;
    my $config;
    if (!ref($configFile)) {
        $config = $class->_ReadConfigFile($configFile);
    } else {
	$config = $configFile;
    }
    if (!exists($config->{'hosts'}->{$name})) {
	die "No such host: $name";
    }
    my $self = $config->{'hosts'}->{$name};
    bless($self, (ref($class) || $class));
    my $key;
    foreach $key (qw(editors ci local_addr tftp_prefix)) {
	if (!exists($self->{$key})) {
	    $self->{$key} = $config->{$key};
	}
    }
    $self->{'configFile'} = $configFile;
    my($euid, $epasswd, $euser) = getpwuid($>);
    my($ruid, $rpasswd, $ruser) = getpwuid($<);
    my($user);
    foreach $user (@{$self->{'users'}}) {
	if ($user eq $euid  ||  $user eq $euser  ||
	    $user eq $ruid  ||  $user eq $ruser) {
	    return $self;
	}
    }
    die "You have no permissions to access host $name.";
}


=pod

=head2 Edit($editor, $file, $tmpDir)

(Instance method) Invoke the editor C<$editor> to edit the configuration
file. If $editor is not defined, use $ENV{'EDITOR'} or the first editor
from the list of editors in the configuration file. (The I<editors>
attribute.)

For security reasons valid editors are restricted to those from the
configuration file. Editing takes place in the directory $tmpDir,
so that we can change the EUID to the users.

Example:

    $self->Edit('emacs', 'myrouter.conf', '/tmp');

=cut


sub _System($$) {
    my($class, $command) = @_;
    $! = 0;
    my $rc = system $command;
    if ($rc == 0xff00) {
	die "Command $command failed: " .
	    ($!  ||  "Unknown system error");
    } elsif ($rc) {
	die "Command $command exited, error status $rc";
    }
}


sub _Edit ($$$$) {
    my($self, $editor, $file, $tmpDir) = @_;

    if ($< == $>) {
	# We aren't running SUID, so things are easy.
	return $self->_System(sprintf("%s %s", $editor, $file));
    }

    #   Editing a file is a true security problem. :-(
    #   Most editors have escape sequences that allow to execute
    #   arbitrary shell commands with. When running suid root,
    #   this means that we can do just anything!
    #
    #   We try to work around this problem as follows:
    #   First we create a copy of the file that should be
    #   edited. The real user becomes owner of this file.
    #
    #   Next we fork a child. This child changes the EUID
    #   to the UID, so it is no longer running suid. Now
    #   we can edit the copy.
    #
    #   Finally the copy is restored back to become the original.
    #   That's it, folks! :-)
    #

    my $configuration;
    my $fh;
    {
	local $/ = undef;
	$fh = IO::File->new($file, "r");
	if (!$fh  ||  !defined($configuration = $fh->getline())  ||
	    !$fh->close()) {
	    die "Error while reading $file: $!";
	}
    }

    my $tmpFile = $tmpDir . "/cisconf.$$";
    $fh = IO::File->new($tmpFile, "w");
    if (!$fh  ||  !chmod(0600, $tmpFile)  ||
	!chown($<, $(, $tmpFile)  ||  !$fh->print($configuration)  ||
	!$fh->flush()  ||  !$fh->close()) {
	unlink $tmpFile;
	die "Error while creating temporary file $tmpFile: $!";
    }

    my $pid = fork();
    if (!defined($pid)) {
	unlink $tmpFile;
	die "Cannot fork: $!";
    } elsif (!$pid) {
	# This is the child; change UID and call the editor
	$) = $(;
	$> = $<;
	exec sprintf("%s %s", $editor, $tmpFile);
    }

    {
	local($SIG{'CHLD'}) = 'IGNORE';
	wait;

	if ($?) {
	    unlink $tmpFile;
	    die "Error while editing $tmpFile, error status was $?";
	}
    }

    #   Now copy the temporary file back
    {
	local $/ = undef;

	$fh = IO::File->new($tmpFile, "r");
	if (!$fh  ||  !defined($configuration = $fh->getline())  ||
	    !$fh->close()) {
	    my $status = $!;
	    unlink $tmpFile;
	    die "Error while reading $tmpFile: $status";
	}
    }
    unlink $tmpFile;
    $fh = IO::File->new("$file.new", "w");
    if (!$fh  ||  !$fh->print($configuration)  ||  !$fh->flush()  ||
	!$fh->close()) {
	my $status = $!;
	die "Error while creating new file $file.new: $status";
    }
    if (-f $file) {
	unlink "$file.bak";
	if (!rename $file, "$file.bak") {
	    die "Error while renaming $file to $file.bak: $!";
	}
    }
    if (!rename "$file.new", $file) {
	die "Error while renaming $file.new to $file: $!";
    }
}


sub Edit ($$$$) {
    my($self, $editor, $file, $tmpDir) = @_;

    require File::Copy;

    $editor ||= $ENV{'EDITOR'} || $self->{'editors'}->[0];
    if (!$editor) {
	die "No editor configured in configuration file "
	    . $self->{'configFile'};
    }

    # Guess an editor, depending on the users settings.
    my $e;
    foreach $e (@{$self->{'editors'}}) {
	my($eFile) = $e;
	$eFile =~ s/.*\///;
	if ($editor eq $eFile  ||  $editor eq $e) {
	    $self->_Edit($e, $file, $tmpDir);
	    return 1;
	}
    }
    die sprintf("No such editor configured in %s: %s", $self->{'configFile'},
		$editor);
}


=head2 RCS($file, $inout)

(Instance method) Invoke the revision control system (RCS) by using
the I<ci> attribute from the config file

Example:

    $self->RCS($file, "in");

=cut


sub RCS ($$$) {
    my($self, $file, $inout) = @_;
    my $haveRcs = eval { require Rcs };

    if (!$haveRcs) {
	if ($inout eq 'in') {
	    my $ci = $self->{'ci'};
	    if (!$ci) {
		die "No RCS program configured in " . $self->{'configFile'};
	    }
	    $self->_System(sprintf("%s %s", $ci, $file));
	}
    } else {
	require File::Basename;
	my $dir = File::Basename::dirname($file);
	my $file = File::Basename::basename($file);
	my $rcs = Rcs->new();
	$rcs->rcsdir("$dir/RCS");
	$rcs->workdir($dir);
	$rcs->file($file);
	if ($inout eq "in") {
	    $rcs->ci("-u");
	} else {
	    $rcs->co("-l");
	}
    }
}


=pod

=head2 Strip($configuration)

(Class method) Strips comments and empty lines from the machine
configuration in the string C<$configuration> and returns the
resulting string.

Comments may appear on any line, beginning with an exclamation mark.
Example:

   ! This is a comment
   interface Ethernet 0  ! Another comment

=cut


sub Strip ($$) {
    my($class, $configuration) = @_;
    my $output = '';
    my $line;
    foreach $line (split(/\r?\n/, $configuration)) {
	$line =~ s/\!(.*)//;
	if (length($line)) {
	    $output .= "$line\n";
	}
    }
    $output;
}


=pod

=head2 Load($file)

(Instance method) Loads the current configuration from the host
and saves it into the file C<$file>. If such a file already
exists, it will be overwritten silently: It is the calling functions
task to emit a warning or do whatever appropriate.

You cannot choose arbitrary file names for $file: The location depends
on the settings of your local TFTP server. In particular you have to
*have* a local TFTP server running. :-) See L<tftpd(1)> for details.

Note that the file mode of $file will be 0666, on other words, the
file is readable and writeable for the world! You should change this
as soon as possible.

=cut


sub _PromptPassword ($$) {
    my($self, $type) = @_;
    if ($type eq "Username") {
	print("\nEnter the username:");
    } else {
	print("\nPlease enter the $type password:");
    }
    $@ = '';
    eval { require Term::ReadKey; };
    my $password;
    if ($@) {
	$password = <STDIN>;
    } else {
        Term::ReadKey::ReadMode('noecho');
	$password = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
    }
    $password =~ s/\r?\n$//;
    print "\n";
    $password;
}

sub _Login ($) {
    my ($self) = @_;

    my $peer_addr = Socket::inet_aton($self->{'host'});
    if (!$peer_addr) {
	die "Cannot resolv host: " . $self->{'host'};
    }
    $self->{'_peer_addr'} = Socket::inet_ntoa($peer_addr);
    my $local_addr = Socket::inet_aton($self->{'local_addr'});
    if (!$local_addr) {
	die "Cannot resolv host: " . $self->{'local_addr'};
    }
    $self->{'_local_addr'} = Socket::inet_ntoa($local_addr);

    my $fh = IO::Handle->new();
    if (!$fh->fdopen(fileno(STDOUT), "w")) {
	die "Cannot open STDOUT for logging: $!";
    }

    my $cmd = Net::Telnet->new(Timeout => 20,
			       Host => $self->{'_peer_addr'},
			       Input_log => $fh,
			       Port => $self->{'port'} || 23);
    if (!$cmd) {
	die "Cannot connect to " . $self->{'host'} . ": $!";
    }
    my $loggedIn = 0;
    while (1) {
	my $match;
	(undef, $match) = $cmd->waitfor(Match => '/\>/',
					Match => '/\#/',
					Match => '/ogin:/',
                                        Match => '/sername:/',
					Match => '/assword:/');
	if ($match =~ /\#/) {
	    if (!$cmd->print("term mon")) {
		die "Output error: $!";
	    }
	    $cmd->waitfor('/\#/');
	    return $cmd;
	}
	my $output;
	if ($match =~ /\>/) {
	    $loggedIn = 1;
	    $output = "enable";
	} elsif ($match =~ /sername:/ || $match =~ /ogin:/) {
	    $output = $self->{'username'} ||
		$self->_PromptPassword("Username");
	} elsif (!$loggedIn) {
	    $output = $self->{'password'}  ||
		$self->_PromptPassword("Login");
	} else {
	    $output = $self->{'enable_password'}  ||
		$self->_PromptPassword("Enable");
	}
	if (!$cmd->print($output)) {
	    die "Output error: $!";
	}
    }
}

sub _Logout ($$) {
    my($self, $cmd) = @_;
    if (!$cmd->print("logout")) {
	die "Output error: $!";
    }
    $cmd->close();
    print "\n";
}


sub Load ($$) {
    my($self, $file) = @_;

    my $tftp_client_file = $file;
    if ($self->{'tftp_prefix'}) {
	my $prefix = $self->{'tftp_prefix'};
	if ($tftp_client_file =~ /^\Q$prefix\E(.*)/) {
	    $tftp_client_file = $1;
	} else {
	    print STDERR("Warning: TFTP prefix $prefix doesn't match file",
			 " name $tftp_client_file.\n");
	}
    }

    # Create an empty file $file
    my $fh;
    if (!($fh = IO::File->new($file, "w"))  ||	!$fh->close()  ||
	!chmod(0666, $file)) {
	die "Cannot create $file: $!";
    }

    my $cmd = $self->_Login();
    if (!$cmd->print("copy running-config tftp")) {
	die "Output error: $!";
    }
    $cmd->waitfor('/\[(\d+\.\d+\.\d+\.\d+)?\]\? /');
    if (!$cmd->print($self->{'_local_addr'})) {
	die "Output error: $!";
    }
    my($prematch, $match) =
	$cmd->waitfor('/(destination filename|file to write)\s+\[.*\]\? /i');
    if (!$cmd->print($tftp_client_file)) {
	die "Output error: $!";
    }
    if ($match =~ /^destination/i) {
	# Cisco IOS 12.0
	$cmd->waitfor('/\d+\s+bytes\s+copied\s+in/');
    } else {
	$cmd->waitfor('/\[confirm\]/');
	if (!$cmd->print('y')) {
	    die "Output error: $!";
	}
	$cmd->waitfor('/\[OK\].*\#/s');
    }
    $self->_Logout($cmd);
}


=pod

=head2 Save($file, $write)

(Instance method) Reads a machines configuration from $file and save it
into the router. Like with the I<Load> method, possible locations of
$file depend on your TFTP servers settings.

Note that the file mode of $file will be changed to 0444, on other words,
the file is readable for the world! You should change this as soon as
possible.

If the argument $write is TRUE, the configuration will be saved into
the non-volatile memory by executing the command

     write memory

=cut


sub Save ($$;$) {
    my($self, $file, $write) = @_;

    my $tftp_client_file = $file;
    if ($self->{'tftp_prefix'}) {
	my $prefix = $self->{'tftp_prefix'};
	if ($tftp_client_file =~ /^\Q$prefix\E(.*)/) {
	    $tftp_client_file = $1;
	} else {
	    print STDERR("Warning: TFTP prefix $prefix doesn't match file",
			 " name $tftp_client_file.\n");
	}
    }

    # Change the file permissions of $file to 0444, so that it's
    # readable by the TFTP server
    if (!chmod(0444, $file)) {
	die "Cannot make $file readable: $!";
    }

    my $cmd = $self->_Login();
    if (!$cmd->print("copy tftp running-config")) {
	die "Output error: $!";
    }
    my($prematch, $match) = 
	$cmd->waitfor('/\[(host|\d+\.\d+\.\d+\.\d+)?\]\? /');
    if ($match eq "[host]") {
	# Cisco IOS below 12.0
	if (!$cmd->print("")) {
	    die "Output error: $!";
	}
	$cmd->waitfor('/\[(\d+\.\d+\.\d+\.\d+)?\]\? /');
    }
    if (!$cmd->print($self->{'_local_addr'})) {
	die "Output error: $!";
    }
    $cmd->waitfor('/(?:Source filename|Name of configuration file) \[.*\]\? /');
    if (!$cmd->print($tftp_client_file)) {
	die "Output error: $!";
    }
    ($prematch, $match) =
	$cmd->waitfor('/(Destination filename \[.*\]|confirm)/');
    if ($match =~ /^Destination filename \[.*\]$/) {
	# Cisco IOS 12.0
	if (!$cmd->print("")) {
	    die "Output error: $!";
	}
    } else {
	if (!$cmd->print('y')) {
	    die "Output error: $!";
	}
    }
    $cmd->waitfor('/\[OK.*bytes\].*\#/s');
    if ($write) {
	if (!$cmd->print('write memory')) {
	    die "Output error: $!";
	}
	$cmd->waitfor('/\#/s');
    }
    $self->_Logout($cmd);
}


=pod

=head2 Info($configFile)

(Class method) Read a list of all configurations in C<$configFile> and
return those configurations that are accessible by the current user.

=cut


sub Info ($$) {
    my($class, $configFile) = @_;
    my $config = $class->_ReadConfigFile($configFile);
    my ($name, @list);
    foreach $name (keys %{$config->{'hosts'}}) {
	$@ = '';
	my $ref = eval { $class->Read($config, $name); };
	if ($@) {
	    if ($@ !~ /You have no permissions/) {
		die $@;
	    }
	} else {
	    push(@list, $ref);
	}
    }
    \@list;
}


=head2 EtcFile($config)

(Instance method) Returns a routers config file name.

=cut

sub EtcFile {
    my $self = shift; my $config = shift;
    $self->{'etc_file'} or ($config->{'etc_dir'} . "/" . $self->{'file'});
}


=head2 TftpFile($config)

(Instance method) Returns a routers TFTP file name.

=cut

sub TftpFile {
    my $self = shift; my $config = shift;
    $self->{'tftp_file'} or ($config->{'tftp_dir'} . "/" . $self->{'file'});
}


1;

__END__

=pod


=head1 CREDITS

=over 8

=item Esfandiar Tabari <Esfandiar_Tabari@hugoboss.com>

for giving me the contract that included the cisconf script. :-)

=item Tungning Cheng <cherng@bbn.com>

for fixing the nasty open file bug ...

=item Mike Newton <mike@delusion.org>

for adding the username and supporting the Rcs module.

=back


=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Phone: +49 7123 14887
                          Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<cisconf(1)>

=cut
