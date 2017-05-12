#!/usr/bin/perl -w

package BoxBackup::Config::Accounts;
use strict;
use Carp;

=head1 NAME

BBConfig::Accounts - Access to Box Backup account config files

=head1 SYNOPSIS

  use BoxBackup::Config::Accounts;
  $bbconfig = BoxBackup::Config::Accounts->new();

or

  use BoxBackup::Config::Accounts;
  $file = "/etc/bbox/accounts.txt";
  $bbconfig = BoxBackup::Config::Accounts->new($file);

  @accounts = $bbconfig->getAccountIDs();
  foreach $i (@accounts)
  {
      # Find out what account is on what diskset.
      $disk = $bbconfig->getDisk($i);
  }
  
=head1 ABSTRACT

BoxBackup::Config::Accounts is a rather simple package that lets the user
have access to the data from the accounts configuration file for
Box Backup. It provides methods to retrieve the data only. No creation
or editing is supported.

=head1 DESCRIPTION

Allows for programmatic access to the information stored in the Box
Backup 'accounts' config file, which simply holds the mapping between
accounts and disk sets.

=head2 Methods

=over

=item *
new(). The new() method parses the accounts file given as the first (and only) 
parameter, or, if none are given, parses /etc/box/bbstored/accounts.txt, and 
creates the object.

=item *
getAccountIDs(). The getAccountIDs() method returns a sorted array of all the account IDs 
found in the config file. This will often be used for processing all the 
accounts in some way.

=item *
getDisk(). The getDisk() method returns a diskset ID when given an account ID. 

=back

=head1 AUTHOR
Per Reedtz Thomsen (L<mailto:pthomsen@reedtz.com>)
 
=cut
  
our $VERSION = v0.03;

sub new
{
    my ($self, @args) = @_;
    my $accountFile = $args[0] || "/etc/box/bbstored/accounts.txt";

    open (ACCOUNTS, "<$accountFile") or croak("Can't open $accountFile: $!\n");

    my %accounts;
    while (<ACCOUNTS>)
    {
	chomp;
	next if(m/^\#/);
	# Format of Accounts file: <account number>:<disk set>
	my ($acct,$disk) = split /:/;
	if(($acct eq "") || !defined($disk))
	{
	    carp("Bad line in $accountFile: [$_] skipping");
	    next;
	}
	my $acctF = sprintf("%lx", hex($acct));
	# print $acctF , " - ", $disk, "\n";
	$accounts{$acctF} = $disk;
    }
    bless \%accounts, $self;
}

sub numerically { $a <=> $b }

sub getDisk
{
    my ($self, $accountID) = @_;

    # Return the disk set number for the given account.
    # The $accountID string is reformatted to a non-padded
    # hex number, to conform to the object storage format.
    my $accountIDF = sprintf("%lx", hex($accountID));
    return $self->{$accountIDF} if exists($self->{$accountIDF});
    return -1;
}

sub setDisk
{
    my ($self, $accountID, $diskSet) = @_;
    my $accountIDF = sprintf("%lx", hex($accountID));
    
    $self->{$accountIDF} = $diskSet;
    
}


sub getAccountIDs
{
    my ($self) = @_;

    return sort numerically (keys %$self);

}



1;


					     
