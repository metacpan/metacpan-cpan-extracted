package App::Glacier;
use strict;
use warnings;
use parent 'App::Glacier::Core';
use File::Basename;
use Net::Amazon::Glacier;
use App::Glacier::Command;
use File::Basename;
use Carp;

our $VERSION = '2.13';


my %comtab = (
    mkvault => sub {
	require App::Glacier::Command::CreateVault;
	return new App::Glacier::Command::CreateVault(@_);
    },
    ls => sub {
	require App::Glacier::Command::ListVault;
	return new App::Glacier::Command::ListVault(@_);
    },
    sync => sub {
	require App::Glacier::Command::Sync;	
	return new App::Glacier::Command::Sync(@_);
    },
    put => sub {
	require App::Glacier::Command::Put;	
	return new App::Glacier::Command::Put(@_);
    },
    rmvault => sub {
	require App::Glacier::Command::DeleteVault;
	return new App::Glacier::Command::DeleteVault(@_);
    },
    rm => sub {
	require App::Glacier::Command::DeleteFile;
	return new App::Glacier::Command::DeleteFile(@_);
    },
    purge => sub {
	require App::Glacier::Command::Purge;
	return new App::Glacier::Command::Purge(@_);
    },	
    get => sub {
	require App::Glacier::Command::Get;	
	return new App::Glacier::Command::Get(@_);
    },
    jobs => sub {
	require App::Glacier::Command::Jobs;
	return new App::Glacier::Command::Jobs(@_);
    },
    periodic => sub {
	require App::Glacier::Command::Periodic;
	return new App::Glacier::Command::Periodic(@_);
    }	
);

sub getcom {
    my ($self, $com) = @_;
    
    while (defined($comtab{$com}) and ref($comtab{$com}) ne 'CODE') {
	$com = $comtab{$com};
    }
    croak "internal error: unresolved command alias" unless defined $com;
    return $comtab{$com} if exists $comtab{$com};

    my @v = map { /^$com/ ? $_ : () } sort keys %comtab;
    if ($#v == -1) {
	$self->usage_error("unrecognized command");
    } elsif ($#v > 0) {
	$self->usage_error("ambiguous command: ".join(', ', @v));
    }
    return $self->getcom($v[0]);
}

sub new {
    my ($class, $argref) = shift;

    my $self = $class->SUPER::new(
	$argref,
	optmap => {
	'config-file|f=s' => 'config',
	'account=s' => 'account',
	'region=s' => 'region'
    });

    my $com = shift @{$self->argv}
	or $self->usage_error("no command name");
    &{$self->getcom($com)}($self->argv,
			   debug => $self->{_debug},
			   dry_run => $self->dry_run,
			   progname => $self->progname,
			   %{$self->{_options} // {}});
}
__END__

=head1 NAME

App::Glacier - command line utility for accessing Amazon Glacier storage

=head1 SYNOPSIS

B<glacier>
[B<-?dn>]
[B<-f> I<FILE>] 
[B<--account=>I<STRING>]
[B<--config-file=>I<FILE>]
[B<--debug>]
[B<--dry-run>]
[B<--help>]    
[B<--region=>I<STRING>]    
[B<--usage>]
I<COMMAND> [I<OPTIONS>] I<ARG>...

=head1 DESCRIPTION

Command line tool for working with the Amazon Glacier storage.  The I<COMMAND>
instructs it what kind of manipulation is required.  Its action can be
modified by I<OPTIONS> supplied after the command name.  Options occurring
before it affect the behavior of the program as a whole and are common
for all commands.
    
The following is a short summary of existing commands.  For a detailed
description about any particular I<command>, please refer to the
corresponding manual page (B<glacier-I<command>>), or run
B<glacier I<command> --help>.    

=head2 On file versioning
    
In the discussion below, I<FILE> stands for the name of the file to which
the command in question applies. In contrast to the UNIX filesystem, where
each file name is unique within the directory, B<Glacier> vaults can keep
multiple copies of the same file. To discern between them, the I<version
number> is used. When a file B<FILE> is first stored in a vault, it is
assigned version number B<1>. The version numbed of this copy is incremented
each time a new copy of the same file is added to the vault. The most recently
stored copy always has the version number of B<1>.    

Each command by default operates on the most recent copy of the file, i.e.
the one with the version number B<1>. To address a particular version of the
file, append the version number to its name with a semicolon in between. For
example, to list B<FILE>, version B<3>, do:

    glacier ls vault 'FILE;3'
    
Notice the use of quotes to prevent C<;> from being interpreted by the shell.

=head1 COMMANDS
    
=head2 glacier get I<VAULT> I<FILE> [I<LOCALNAME>]

Download I<FILE> from the I<VAULT>.  The I<LOCALNAME> argument, if present,
gives the name of the local file.

=head2 glacier jobs [I<VAULT>...]

List Glacier jobs.
    
=head2 glacier ls [I<VAULT>] [I<FILES>...]

Without arguments, lists all existing vaults.  With one argument, lists files
in the specified vault.  If additional arguments are given, only files with 
matching names will be listed.
    
=head2 glacier mkvault I<NAME>

Creates a vault with given I<NAME>.    
    
=head2 glacier purge I<VAULT>

Removes all archives from the vault.    
    
=head2 glacier put I<VAULT> I<FILE> [I<REMOTENAME>]

Uploads I<FILE> to I<VAULT>.  The I<REMOTENAME>, if supplied, gives the
new name for the uploaded copy of file.  If absent, the base name of I<FILE>
is used.    
    
=head2 glacier rm I<VAULT> I<FILE>...

Removes files from the vault.    
    
=head2 glacier rmvault I<NAME>

Removes the vault.  It must be empty for the command to succeed.    
    
=head2 glacier sync I<VAULT>

Synchronizes the local vault directory with its latest inventory.    

=head2 glacier periodic

Periodic task for glacier job maintenance. It is recommended to run it
each 4 hours as a cronjob.
    
=head1 OPTIONS

=over 4

=item B<-?>

Displays short option summary.
    
=item B<--account=>I<STRING>

Sets account ID to use.  See B<Multiple accounts>, below. 
    
=item B<-f>, B<--config-file=>I<FILE>

Sets the name of the configuration file to use.  In the absense of this
option, the environment variable B<GLACIER_CONF> is consulted.  If it
is not set, the default file F</etc/glacier.conf> is read.  See
the section B<CONFIGURATION> for its description.    
    
=item B<-d>, B<--debug>

Increases debug output verbosity level.    
    
=item B<-n>, B<--dry-run>

Dry run mode: do nothing, print everything.
    
=item B<--help>

Display the detailed help page.
    
=item B<--region=>I<STRING>

Sets the avaialbility region.    
    
=item B<--usage>

Displays a succint command line usage summary,    

=back    
    
=head1 CONFIGURATION

Default configuration file is F</etc/glacier.conf>. This file is optional.
If it does not exist, B<glacier> will attempt to start up with default
values (optionally modified by the command line options). If you run
glacier on a EC2 instance with an associated IAM profile, you can omit
the configuration file, provided that the profile gives the necessary
permissions on the Glacier storage. Please see
L<https://docs.aws.amazon.com/amazonglacier/latest/dev/access-control-identity-based.html> for details on identity-based policies.

Th configuration file can also be specified using the environment variable
B<GLACIER_CONF>, or from the command line, using the B<--config-file> (B<-c>)
option. If both are used, the option takes precedence over the variable.

Configuration file consists of statements in the form
I<variable> B<=> I<value>), grouped into sections.  Whitespace is ignored,
except that it serves to separate input tokens.  However, I<value> is read
verbatim, including eventual whitespace characters that can appear within it.

The following sections are recognized:

=over 4

=item B<[glacier]>

Configures access to the Glacier service.  The following keywords are defined:
    
=over 8

=item B<credentials => I<FILE>

Sets the name of the credentials file.  See below for a detailed discussion.
    
=item B<access => I<KEYNAME>

Defines Amazon access key or access ID for look up in the credentials file.
    
=item B<secret => I<SECRET>

Sets the secret key.  The use of this statement is discouraged for
security reason.    

=item B<region => I<NAME>

Sets the Amazon region.  If this setting is absent, B<glacier> will attempt
to retrieve the region from the instance store (assuming it is run on an EC2
AWS instance).    
    
=back

If either of B<access> or B<secret> is not supplied, B<glacier> attemtps to
obtain access and secret keys from the file named in the B<credentials>
setting (if it is defined). If unable to find credentials, B<glacier> attempts
to get credentials from the instance store, assuming it is run on an EC2
instance. It will exit if this attempt fails.    

The credentials file allows you to store all security sensitive data in a
single place and to tighten permissions accordingly. In the simplest case,
this file contains a single line with your access and secret keys separated
by a semicolon, e.g.:

    AEBRGYTEBRET:RTFERYABNERTYR4HDDHEYRTWW

Additionally, the default region can be specified after a second semicolon:

    AEBRGYTEBRET:RTFERYABNERTYR4HDDHEYRTWW:us-west-1
    
If you have several accounts, you can list their credentials on separate lines.
In that case, B<glacier> will select the account with the access key supplied
by the B<access> configuration statement, or the B<--account> command line
option.  If neither of these are supplied, the first account in the file will
be used.

To further facilitate selection of the credential pair, each line can be tagged
with the line B<#:I<NAME>> immediately preceding it.  In that case, the I<NAME>
can be used to select it using the B<--account> option or B<access> configuration statement.

Apart from these constructs, the credentials file can contain empty lines and
comments (lines beginning with B<#> followed by any character, except B<:> ),
which are ignored.

=item B<[transfer]>

Configures transfer values.  The section name can be optionally followed
by B<upload> or B<download> to indicate that it applies only to transfers
in that particular direction.    
    
=over 8

=item B<single-part-size => I<SIZE>

Defines the maximum size for single-part transfers.  Archives larger than
I<SIZE> will be transferred using multiple-part procedure.  I<SIZE> must
be a number, optionally followed by one of the following suffixes: B<K>,
for kilobytes, B<M>, for megabytes, or B<G> for gigabytes.  Suffixes are
case-insensitive.  The default is B<100M>.  
    
=item B<jobs => I<NUMBER>

Sets the number of transfers running in parallel, if multi-part transfer is
selected.  The default value is 16.    

=item B<retries => I<NUMBER>

Sets the number of retries for failed transfers.  Defaults to 10.    

=back

=item B<[transfer download]>

In addition to settings discussed above, the C<transfer download> section
can contain the following:

=over 8

=item B<cachedir => I<DIR>

Names the directory used to keep files downloaded after successful
completion of archive retrieval jobs. This directory is managed by
B<glacier periodic> subcommand. The default value is F</var/lib/glacier/cache>.
    
=back    

=item B<[database job]>

Configures the I<job database>.  Job database is a local GDBM file, which
B<glacier> uses to keep track of the initiated Amazon Glacier jobs.
    
=over 8

=item B<file => I<NAME>

Defines the database file name.  The default is F</var/lib/glacier/job.db>.

=item B<mode => I<OCTAL>

Defines the file permissions.  It is used if the database does not exist and
B<glacier> has to create it.  The default value is 644.

=item B<ttl => I<NUMBER>

Interval in seconds after which the completed job will be checked to ensure
it has not expired.  Default is 72000 seconds (20 hours). 
    
=back

=item B<[database inv]>

Configures B<inventory databases>.  Inventory databases associate file names
with the corresponding Glacier archives and keep additional bookkeeping
information.    
    
=over 8

=item B<directory => I<DIR>

Directory where to place the databases.  The default is F</var/lib/glacier/inv>.
    
=item B<mode => I<OCTAL>

File mode for creating missing databases.  The default value is 644.

=item B<ttl => I<NUMBER>

Interval in seconds after which the completed inventory will be checked to
ensure it has not expired.  Default is 72000 seconds (20 hours).
    
=back    

=back    
    
=cut
    
=head1 FILES

=over 4

=item F</etc/glacier.conf>

Default configuration file.

=item F</var/lib/glacier/job.db>

Default job database name,

=item F</var/lib/glacier/inv/I<VAULT>.db>

Inventory database for the I<VAULT>.

=back    

=head1 SEE ALSO

B<glacier-get>(1),
B<glacier-jobs>(1),
B<glacier-ls>(1),
B<glacier-mkvault>(1),
B<glacier-purge>(1),
B<glacier-put>(1),
B<glacier-rm>(1),
B<glacier-rmvault>(1),
B<glacier-sync>.
    
=head1 LICENSE

GPLv3+: GNU GPL version 3 or later, see
<http://gnu.org/licenses/gpl.html>
    
This  is  free  software:  you  are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

=head1 AUTHOR

Sergey Poznyakoff <gray@gnu.org>
    
=cut

    


