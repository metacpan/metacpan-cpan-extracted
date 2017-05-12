#! -*- perl -*-

my $script = <<'EOF';
~startperl~ -wT
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

use strict;


require Getopt::Std;
require Cisco::Conf;
require Socket;
require Symbol;


############################################################################
#
#   Constant variables
#
############################################################################

my $VERSION = 'cisconf, 24-Jul-1998, Copyright (C) 1998 by Jochen Wiedmann';
my $CONFIG_FILE = "~etc_dir~/configuration";
my $ETC_DIR = "~etc_dir~";
my $TFTP_DIR = "~tftp_dir~";


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print usage message and exit
#
############################################################################

sub Usage () {
    print <<"USAGE";
Usage:

    cisconf -a <router>           Add new <router> to config file.
    cisconf -d <router>           Remove <router> from config file.
    cisconf -e <router> [-n]      Edit configuration of <router> in
	                          ETC_DIR and feed it into the revision
                                  control system (unless -n given)
    cisconf -l <router>           Load configuration from <router> by
	                          executing

				      copy running-config tftp

				  and save it in TFTP_DIR.
    cisconf -r <router>           Read configuration of router from
                                  ETC_DIR and print it to stdout.
    cisconf -s <router> [-w]      Read configuration of <router> from
                                  ETC_DIR, strip off comments,
                                  save result in TFTP_DIR
                                  and store it on the router using

				      copy tftp running-config

				  If -w is given, do a

				      write memory

				  if successfull.
    cisconf -h                    Print this message
    cisconf -i                    Print a list of all configurations
                                  that you may access.
    cisconv -v                    Print version and exit

ETC_DIR and TFTP_DIR are configured in the config file,

    $CONFIG_FILE

$VERSION
USAGE
    exit 1;
}


############################################################################
#
#   Name:    Info
#
#   Purpose: Print list of all configurations accessible by the
#            current user and exit.
#
#   Returns: Nothing, exits in case of trouble.
#
############################################################################

sub Info () {
    my $list = Cisco::Conf->Info($CONFIG_FILE);

    if (!@$list) {
	print "There are no router configurations you can access.\n";
    } else {
	my $nLength = length('Name');
	my $dLength = length('Description');
	my $ref;
	foreach $ref (@$list) {
	    if (length($ref->{'name'}) > $nLength) {
		$nLength = length($ref->{'name'});
	    }
	    if (length($ref->{'description'}) > $dLength) {
		$dLength = length($ref->{'description'});
	    }
	}
	my $format = sprintf("    %%-%ds  %%%ds\n", $nLength, $dLength);
	printf("You have access to the following routers:\n\n$format\n",
	       'Name', 'Description');
	foreach $ref (sort { $a->{'name'} cmp $b->{'name'} } @$list) {
	    printf($format, $ref->{'name'}, $ref->{'description'});
	}
    }
}


############################################################################
#
#   Name:    Add
#
#   Purpose: Add a new configuration to the config file.
#
#   Input:   Routers name
#
#   Returns: Nothing, exits in case of trouble.
#
############################################################################

sub _Load {
    my($config, $conf, $name) = @_;
    my $tftpFile = $conf->TftpFile($config);
    if (-f $tftpFile  &&  ! -z _) {
        print "\nWarning: A file $tftpFile already exists!";
	print "\nOverwrite it? [y]";
	my $reply = <STDIN>;
	$reply =~ s/\s+//;
	if ($reply ne ''  &&  $reply !~ /y/i) {
	    exit 0;
	}
    }
    $conf->Load($tftpFile);
    $tftpFile;
}


sub Add ($) {
    my $name = shift;
    my $config = Cisco::Conf->_ReadConfigFile($CONFIG_FILE);

    if (!$name) {
	print STDERR "Must have a valid router name.\n";
	exit 1;
    }
    if (exists($config->{'hosts'}->{$name})) {
	die "A router $name already exists.";
    }

    print "\nEnter a description of the router $name (one line):\n";
    my $description = <STDIN>;
    $description =~ s/^\s+//;
    $description =~ s/\s+$//;

    my $user = ((getpwuid($>))[0]);
    if ($< != $>) {
	$user .= " " . ((getpwuid($<))[0]);
    }
    if ($< != 0  &&  $> != 0) {
	$user .= " " . ((getpwuid(0))[0]);
    }
    print "\nEnter blank separated list of users that may configure the";
    print "\n router: [$user] ";
    my $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    $user = $reply ? $reply : $user;

    my $peer_address;
    if ($peer_address = Socket::inet_aton($name)) {
	$peer_address = Socket::inet_ntoa($peer_address);
    } else {
	$peer_address = $name;
    }
    print "\nEnter IP address of the router [$peer_address] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    $peer_address = $reply ? $reply : $peer_address;

    my $local_address = $config->{'local_addr'};
    print "\nEnter the local hosts IP address that the router will use";
    print "\nfor accessing the TFTP server: [$local_address] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    $local_address = $reply ? $reply : $local_address;

    print "\nDepending on your routers configuration, a username might";
    print "\nbe required. If so, you may make it part of the cisconf";
    print "\nconfiguration by entering it now. If you don't, or if your";
    print "\nrouter doesn't require a username, enter the word 'undef'.";
    print "\nIn the latter case you will be queried whenever a username";
    print "\nis required. Username: [undef] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    my $login_username = $reply;
    if ($login_username eq 'undef') {
	$login_username = undef;
    }

    print "\nEnter the routers login password or the word 'undef', if you";
    print "\ndon't want to configure a fixed password. If you don't enter a";
    print "\npassword, you will be queried for the password each time you";
    print "\nare accessing the router: [undef] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    my $login_password = $reply ? $reply : undef;

    print "\nEnter the routers enable password. If you don't enter a";
    print "\npassword, but an empty string, you will be queried for";
    print "\nthe password each time you are accessing the router: [undef] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    my $enable_password = $reply ? $reply : undef;

    print "\nEnter the file name of the routers configuration [$name.conf] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;
    my $file = $reply ? $reply : "$name.conf";

    Cisco::Conf->Add($CONFIG_FILE, { 'name' => $name,
                                     'description' => $description,
                                     'users' => [split(/ /, $user)],
                                     'host' => $peer_address,
                                     'local_addr' => $local_address,
				     'username' => $login_username,
                                     'password' => $login_password,
                                     'enable_password' => $enable_password,
                                     'file' => $file });
    $config = Cisco::Conf->_ReadConfigFile($CONFIG_FILE);
    my $conf = Cisco::Conf->Read($config, $name);

    my $etcFile = $conf->EtcFile($config);
    if (-f $etcFile) {
        print "\nA file $etcFile already exists. Keeping the existing file.\n";
	return;
    }

    print "\nShall I try to load the routers current configuration as an";
    print "\ninitial version? An empty file will be created otherwise: [y] ";
    $reply = <STDIN>;
    $reply =~ s/^\s+//;
    $reply =~ s/\s+$//;

    my $configuration;
    if (!$reply  ||  $reply =~ /y/i) {
        my $file = _Load($config, $conf, $name);
	local $/ = undef;
	my $fh = Symbol::gensym();
	if (!open($fh, "<$file")  ||  !defined($configuration = <$fh>)  ||
	    !close($fh)) {
	    die "Error while reading $file: $!";
	}
    } else {
        $configuration = '';
    }

    my $fh = IO::File->new($etcFile, "w");
    if (!$fh  ||  !$fh->print($configuration)  ||  !$fh->flush()  ||
	!$fh->close()) {
	my $status = $!;
	die "Error while creating new file $etcFile: $status";
    }
}


############################################################################
#
#   This is main().
#
############################################################################

{
    $ENV{'PATH'} = '/bin:/usr/bin';
    delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
    my $o = {};

    Getopt::Std::getopt('a:d:e:hil:nr:s:vw', $o);
    if (exists($o->{'v'})) {
	print "\n$VERSION\n";
	exit 0;
    } elsif (exists($o->{'h'})) {
	Usage();
    } elsif (exists($o->{'i'})) {
	Info();
    } elsif (exists($o->{'a'})) {
	Add($o->{'a'});
    } elsif (exists($o->{'d'})) {
	Cisco::Conf->Remove($CONFIG_FILE, $o->{'d'});
    } elsif (exists($o->{'e'})) {
	my $config = Cisco::Conf->_ReadConfigFile($CONFIG_FILE);
	my $conf = Cisco::Conf->Read($config, $o->{'e'});
	my $tmpDir = $config->{'tmp_dir'} || "/tmp";
	my $etcFile = $conf->EtcFile($config);
	if (!$o->{'n'}) {
	    $conf->RCS($etcFile, "out");
	}
	$conf->Edit(undef, $etcFile, $tmpDir);
	if (!$o->{'n'}) {
	    $( = $);
	    $< = $>;
	    $conf->RCS($etcFile, "in");
	}
    } elsif (exists($o->{'l'})) {
	my $config = Cisco::Conf->_ReadConfigFile($CONFIG_FILE);
	my $conf = Cisco::Conf->Read($config, $o->{'l'});
	_Load($config, $conf, $o->{'l'})
    } elsif (exists($o->{'r'})) {
	my $config = Cisco::Conf->_ReadConfigFile($CONFIG_FILE);
	my $conf = Cisco::Conf->Read($config, $o->{'r'});
	my $etcFile = $conf->EtcFile($config);
	my $fh = Symbol::gensym();
	if (!open($fh, $etcFile)) {
	    print STDERR "Cannot open $etcFile: $!\n";
	    exit 1;
	}
	my $line;
	while (defined($line = <$fh>)) {
	    print $line;
	}
    } elsif (exists($o->{'s'})) {
	my $config = Cisco::Conf->_ReadConfigFile($CONFIG_FILE);
	my $conf = Cisco::Conf->Read($config, $o->{'s'});
	my $etcFile = $conf->EtcFile($config);
	my $tftpFile = $conf->TftpFile($config);
	if (-f $tftpFile  &&  ! -z _) {
	    print "\nWarning: A file $tftpFile already exists!";
	    print "\nOverwrite it? [y]";
	    my $reply = <STDIN>;
	    $reply =~ s/\s+//;
	    if ($reply ne ''  &&  $reply !~ /y/i) {
		exit 0;
	    }
	}
	my $configuration;
	{
	    local $/ = undef;
	    my $fh = Symbol::gensym();
	    if (!open($fh, $etcFile)  ||
		!defined($configuration = <$fh>)) {
		print STDERR "Error while reading $etcFile: $!\n";
		exit 1;
	    }
	}
	if (!$conf->{'wants_comments'}) {
	    $configuration = Cisco::Conf->Strip($configuration);
	}
	{   my $fh = Symbol::gensym();

	    if (!open($fh, ">$tftpFile")      ||
		!(print $fh $configuration)  ||
		!(close($fh))) {
		print STDERR "Error while creating $tftpFile: $!\n";
		exit 1;
	    }
	}
	$conf->Save($tftpFile, (exists($o->{'w'}) ? 1 : 0));
    } else {
	Usage();
    }
}

1;

__END__

=head1 NAME

cisconf - Cisco configuration management via TFTP

=head1 SYNOPSIS

    cisconf -a <conf>
    cisconf -d <conf>
    cisconf -e <conf> [-n]
    cisconf -r <conf>
    cisconf -l <conf>
    cisconf -s <conf> [-w]
    cisconf -i
    cisconf -h
    cisconf -v


=head1 DESCRIPTION

The I<cisconf> utility allows to maintain a a set of Cisco router
configurations as files. Configuration files can be loaded from routers
or saved into routers by using a local TFTP server.


=head2 Adding router configurations

Usually you start with adding router configurations to the config file,
C<~etc_dir~/configuration>. This is done by invoking

    cisconf -a <conf>

where C<E<lt>confE<gt>> is a short and unique name for the configuration
you like to add.

The script will ask you some questions interactively and allow you to
enter the new routers settings, in particular the IP address, the login
username, the login and enable password, a description and a list of users
that are allowed to manage the router.


=head2 Deleting router configurations

You can remove a given router configuration with

    cisconf -d <conf>

where C<E<lt>confE<gt>> is the name you gave the router when invoking
C<cisconf -a E<lt>confE<gt>>.


=head2 Editing router configurations

Router configurations can be edited with

    cisconf -e <conf> [-n]

This will invoke the editor from the environment variable I<EDITOR>.
If you didn't set this variable, the first editor from the I<editors>
list in the configuration file C<~etcdir~/configuration> is used.

After you have modified the configuration, the revision control system
will be invoked, unless you specify the option C<-n>. Revision control
will be done by using the command from the I<ci> attribute in the
configuration file.


=head2 Printing a router configuration

The command

    cisconf -p <conf>

will print the configuration file of the given router to stdout.


=head2 Loading a configuration file from the router

The best starting point for creating a new configuration is of
course loading the current configuration of the router. This is
done by invoking the command

    copy running-config tftp

on the router and storing the configuration on the local TFTP server.
The command

    cisconf -l <conf>

will do that for you, creating the file C<~tftp_dir~/E<lt>conf<gt>.conf>.

Of course this requires an appropriately configured TFTP server with
write permissions in the directory ~tftp_dir~.


=head2 Storing a configuration file on the router

The counterpart of the C<-l> option is

    cisconf -s <conf> [-w]

This will read the file C<~etcdir~/E<lt>conf<gt>.conf>, strip comments
and empty lines and store the result in C<~etcdir~/E<lt>conf<gt>.conf>.
The latter file will then be stored on the router by executing the
command

    copy tftp running-config

Note, that by default the new configuration is not written into the
non-volatile memory of the router! The option C<-w> modifies this
behaviour by executing the command

    write memory

on the router, if the configuration has successfully be stored on the
router.


=head2 Listing router configurations

The command

    cisconf -i

will print a list of all router configurations accessible by the
current user.


=head2 Printing a help message

You get a short help message by invoking

    cisconf -h


=head2 Version number

The command

    cisconf -v

will print the programs version number and exit immediately.


=head1 AUTHOR AND COPYRIGHT

This program is

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

L<Cisco::Conf(3)>, L<Cisco::Conf::Install(3)>, L<tftpd(8)>

EOF

require Cisco::Conf;
my $config = Cisco::Conf->_ReadConfigFile('configuration');

require Config;
$config->{'startperl'} = $Config::Config{'startperl'};

$script =~ s/\~(\w+)\~/$config->{$1}/eg;

if (!open(FILE, ">cisconf")  ||  !print FILE ($script)  ||  !close(FILE)) {
    die "Error while writing cisconf script: $!";
}
