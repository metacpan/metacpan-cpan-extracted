#!/usr/bin/perl -w

package BoxBackup::Config::DiskSets;
use strict;
use Carp;
use Config::Scoped;

=head1 NAME

BoxBackup::Config::DiskSets - Access to Box Backup diskset config files

=head1 SYNOPSIS

  use BoxBackup::Config::DiskSets;
  $diskSets = BoxBackup::Config::DiskSets->new();

or

  use BoxBackup::Config::DiskSets;
  $file = "/etc/bbox/raidfile.conf";
  $diskSets = BoxBackup::Config::DiskSets->new($file);

  @diskNames = $diskSets->getListofDisks();
  foreach $i (@diskNames)
  {
      print "Block size of " . $i . " is " . $disksets->getParamVal($i, "BlockSize) . " bytes.\n";
  }
  
=head1 ABSTRACT

BoxBackup::Config::DiskSets is a rather simple package that lets the user
have access to the data from the disk set configuration file for
Box Backup. It provides methods to retrieve the data only. No creation
or editing is supported.

=head1 REQUIRES

L<Config::Scoped>.

=head1 DESCRIPTION

Allows for programmatic access to the information stored in the Box
Backup 'disk set' config file, which holds the information related to
each disk set in the Box Backup installation.

=head2 Methods

=over

=item *
new(). The new() method parses the disksets file given as the first (and only) 
parameter, or, if no parameter is given, parses /etc/box/raidfile.conf, and 
creates the object.

=item *
getListofDisks(). The getListofDisks() method returns an array of the names of all the disk sets
found in the config file. 

=item *
getParamVal(). The getParamVal() method returns the value of a paramter  for a given disk.
2 paramters are passed to this method

=over

=item *
disk. This diskset for which the parameter should be retrieved. Normally
'disc0' or 'disc1', although anything is possible. Use getListofDisks() to
retrieve the names from the file.

=item *
parameter. The parameter you wish to retrieve from the config file, for a 
given disk (see above). Currently, the following parameters are available 
in the file:

=over

=item -
SetNumber. This is the disk set number, that's used in the accounts config file.

=item -
BlockSize. The size of the data blocks used on this diskset. Measured in bytes.

=item -
Dir0. The first of the RAID drives.

=item -
Dir1. The second RAID drive.

=item -
Dir2. The third RAID drive.

=back

=back

=back

=head1 AUTHOR

Per Reedtz Thomsen (L<mailto:pthomsen@reedtz.com>)
 
=cut

our $VERSION = v0.03;

sub new
{
    my ($self, @args) = @_;
    my $disksetFile = $args[0] || "/etc/box/raidfile.conf";

    my $parser = Config::Scoped->new( file => $disksetFile );

    $self = $parser->parse;

    return bless $self;

}


sub getListofDisks
{
    my ($self) = @_;

    # Return an array of disk names from $self.
    return keys %$self;
	
}

sub getParamVal
{
    my ($self, $disk, $parm) = @_;
    return 0 if(!defined($disk) || !defined($parm));

    return -1 if(!defined($self->{$disk}{$parm}));

    return $self->{$disk}{$parm};

}


1;


					     
