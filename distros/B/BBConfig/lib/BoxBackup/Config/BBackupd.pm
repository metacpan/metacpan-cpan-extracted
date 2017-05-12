#!/usr/bin/perl -w

package BoxBackup::Config::BBackupd;
use strict;
use Carp;
use Config::Scoped;

use vars '$AUTOLOAD';
our $VERSION = v0.03;

use subs qw(getStoreHostName
            setStoreHostName
            getAccountNumber
            setAccountNumber
            getKeysFile
            setKeysFile
            getCertificateFile
            setCertificateFile
            getPrivateKeyFile
            setPrivateKeyFile
            getTrustedCAsFile
            setTrustedCAsFile
            getDataDirectory
            setDataDirectory
            getNotifyScript
            setNotifyScript
            getAutomaticBackup
            setAutomaticBackup
            getUpdateStoreInterval
            setUpdateStoreInterval
            getMinimumFileAge
            setMinimumFileAge
            getMaxUploadWait
            setMaxUploadWait
            getFileTrackingSizeThreshold
            setFileTrackingSizeThreshold
            getDiffingUploadSizeThreshold
            setDiffingUploadSizeThreshold
            getMaximumDiffingTime
            setMaximumDiffingTime
            getExtendedLogging
            setExtendedLogging
            getCommandSocket
            setCommandSocket
          );

sub new
{
    my ($self, @args) = @_;
    my $bbackupdFile = $args[0] || "/etc/box/bbackupd.conf";

    my $parser = Config::Scoped->new( file => $bbackupdFile );

    $self = $parser->parse;

    return bless $self;

}

sub save
{
}

sub getServerPidFile
{
    # This is a bit of an odd man out, since there is a section
    # wrapped around the PidFile, but there is no real chance of
    # multiple 'Server' sections, at least not at this time.
    my $self = shift;
    
    return($self->{"Server"}{"PidFile"});
   
}

sub setServerPidFile
{
    # This is a bit of an odd man out, since there is a section
    # wrapped around the PidFile, but there is no real chance of
    # multiple 'Server' sections, at least not at this time.
    my $self = shift;
    my $pidFile = shift;
    
    return($self->{"Server"}{"PidFile"} = shift);
        
}


# Shamelessly copied from Ben's distribution bbackupd.conf
#
# BackupLocations specifies which locations on disc should be backed up. Each
# directory is in the format
# 
# 	name
# 	{
# 		Path = /path/of/directory
# 		(optional exclude directives)
# 	}
# 
# 'name' is derived from the Path by the config script, but should merely be
# unique.
# 
# The exclude directives are of the form
# 
# 	[Exclude|AlwaysInclude][File|Dir][|sRegex] = regex or full pathname
# 
# (The regex suffix is shown as 'sRegex' to make File or Dir plural)
#
# For example:
# 
# 	ExcludeDir = /home/guest-user
# 	ExcludeFilesRegex = *.(mp3|MP3)$
# 	AlwaysIncludeFile = /home/username/veryimportant.mp3
# 
# This excludes the directory /home/guest-user from the backup along with all mp3
# files, except one MP3 file in particular.
# 
# In general, Exclude excludes a file or directory, unless the directory is
# explicitly mentioned in a AlwaysInclude directive.




sub getListOfBackupLocations
{
}

sub getBackupLocationPath
{
}

sub setBackupLocationPath
{
}

sub addBackupLocation
{
}

sub removeBackupLocation
{
}

# The AUTOLOAD method handles all getters and setters.
#
# It's a little hairy, because it also handles getters/setters
# for the 'BackupLocations' sections.
sub AUTOLOAD
{
    my $self = shift;
    
    croak "$self not an object" unless ref($self);
    
    return if $AUTOLOAD =~ /::DESTROY$/;
    
    if($AUTOLOAD =~ /.*::get(\w+)/) # this is a getter
    {
      my $name =  $1;
      # For the 'BackupLocations' section we have to get the location
      # in question, before we know which parameter value to get.
      if($name =~ /AlwaysInclude/ || $name =~ /Exclude/ || $name =~ /Path/)
      {
        my $backupLocation = shift;
        return($self->{"BackupLocations"}{$backupLocation}{$name});
      }
      else
      {
        return($self->{$name});
      }
    }
    
    if($AUTOLOAD =~ /.*::set(\w+)/) # this is a setter
    {
      
      my $name =  $1;
      if($name =~ /AlwaysInclude/ || $name =~ /Exclude/ || $name =~ /Path/)
      {
        my $backupLocation = shift;
        return($self->{"BackupLocations"}{$backupLocation}{$name} = shift);
      }
      else
      {
        return($self->{$name} = shift);
      }
    }
  
}

1;