#!/usr/bin/perl
use base 'LEOCHARRE::CLI';
use strict;

require CGI::Auth::Auto;
use Cwd;

# -u ./user.dat
my $o = gopts('a:');



my $cfg = {};
$cfg->{-admin} = 1;
$cfg->{-authdir} = ( $o->{a} || './' );
$cfg->{-userfile} = $o->{u};



my $_u = $ARGV[0];
if (defined $_u){
   my $abs = "$_u";
   $abs=~/^\// or $abs = cwd()."/$_u";
   $abs=~/^(.+)\/+([^\/]+)$/ or die("cant match inside [$abs]");
   $cfg->{-authdir} = $1;
   $cfg->{-userfile} = $2;
}


my $userfile = $cfg->{-authdir} . "/" . $cfg->{-userfile};

unless ( -f $userfile )
{
	# Create the user data file.
	open USERDAT, "> $userfile" and close USERDAT;
}

my $auth = new CGI::Auth::Auto( $cfg ) or die "CGI::Auth error";

if ($ARGV[0] eq 'prune')
{
	print "Pruning session file directory...\n";
	print $auth->prune, " stale session files deleted.\n";
	exit;
}

my $menutext = <<MENU;
Acquisitions Database Authorization Manager

Select one of the following options:

A - Add a user.
L - List users.
V - View a user.
D - Delete a user.
P - Prune session files.
Q - Quit.

MENU

# If not a member of CGI::Auth, just pass it an auth object reference.
sub addprompt
{
	my $self = shift;

    my @authfields = @{ $self->{authfields} };
	print "Adding a new user.\n";
    print scalar( @authfields ), " fields are needed:  ", join( ', ', map $_->{display}, @authfields ), ".\n\n";

	my $validchars = $self->{validchars};
	my @fields;
	FIELD: for my $f ( @authfields )
	{
		my $notice = ( $f->{hidden} && !$self->{md5pwd} ) ? '16 characters or less; ' : '';
		print "Enter " . $f->{display} . "(${notice}Leave blank to cancel) : ";
		my $data = <STDIN>;

		# Untaint, and remove newlines.
		$data =~ /^(.*?)$/;
		$data = $1;

		# Cancel if nothing entered.
		unless ( $data )
        {
            print "Cancelled.\n";
            return 0;
        }

		# Check for non-valid characters.
		if ( $data =~ /([^$validchars])/ )
		{
			print "Data entered contains an invalid character ($1).\n";
			redo FIELD;
		}

		# Valid data.  So store it, and move on.
		push @fields, $data;
	}

	print "Adding user '$fields[0]'.\n";
	$auth->adduser( @fields );

	return 1;
}

my $option;
do
{
	print $menutext, "Option: ";
	$option = <STDIN>;

	print "\n";
	if ($option =~ /^a/i)
	{
        addprompt( $auth );
	}
	elsif ($option =~ /^l/i)
	{
		print "Users currently in the userbase:\n\n";
		$auth->listusers;
	}
	elsif ($option =~ /^v/i)
	{
		my $un;
		print "User name to view: ";
		$un = <STDIN>;
		chomp $un; chomp $un;		# Two chomps because of the \r\n in Windows

		$auth->viewuser($un);
	}
	elsif ($option =~ /^d/i)
	{
		my $un;

		print "User name to delete: ";
		$un = <STDIN>;
		chomp $un; chomp $un;		# Two chomps because of the \r\n in Windows

		$auth->deluser($un);
	}
	elsif ($option =~ /^p/i)
	{
		print "Pruning session file directory...\n";
		print $auth->prune, " stale session files deleted.\n";
	}

	print "\n";
} while ($option !~ /^q/i);
