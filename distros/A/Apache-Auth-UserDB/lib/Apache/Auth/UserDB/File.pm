#
# Apache::Auth::UserDB::File
# An abstract Apache file user database manager class.
#
# (C) 2003-2007 Julian Mehnle <julian@mehnle.net>
# $Id: File.pm 31 2007-09-18 01:39:14Z julian $
#
##############################################################################

package Apache::Auth::UserDB::File;

use version; our $VERSION = qv('0.120');

use warnings;
use strict;

use base qw(Apache::Auth::UserDB);

use Carp;
# TODO: We are not fully multi-user-safe yet!
#use IPC::SysV;
#use IPC::Semaphore;
use IO::File;
use File::Copy;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# When writing user DB files ...
use constant file_write_mode_write_rename   => 0;  # write new file, then rename over old one.
use constant file_write_mode_overwrite      => 1;  # overwrite old file in-place.

# Implementation:
##############################################################################

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    $self->{file_write_mode} ||= $self->file_write_mode_write_rename;
    return $self;
}

sub open {
    my ($class, %options) = @_;
    
    my $self = $class->new(%options);
    if (defined($self) and $self->_read()) {
        return $self;
    }
    else {
        return undef;
    }
}

sub _read {
    my ($self) = @_;
    
    my $file = IO::File->new($self->{file_name}, '<');
    return undef if not $file;
    #croak("Unable to open file for reading: $self->{file_name}")
    #   if not $file;
    
    $self->clear();
    
    while (my $line = <$file>) {
        chomp($line);
        my $user = $self->_parse_entry($line);
        push(@{$self->{users}}, $user);
    }
    
    $file->close();
    
    return TRUE;
}

sub _write {
    my ($self) = @_;
    
    if ($self->{file_write_mode} == $self->file_write_mode_write_rename) {
        # Write new file, then rename over old one:
        
        my $temp_file_name = $self->{file_name} . sprintf('.%d:%d', $$, time());
        my $temp_file = IO::File->new($temp_file_name, '>');
        return undef if not $temp_file;
        #croak("Unable to open file for writing: $temp_file_name")
        #   if not $temp_file;
        
        foreach my $user (@{$self->{users}}) {
            $temp_file->print($self->_build_entry($user), "\n");
        }
        
        $temp_file->close();
        move($temp_file_name, $self->{file_name})
            or return undef;
            #or croak("Unable to replace $self->{file_name} with $temp_file_name");
    }
    elsif ($self->{file_write_mode} == $self->file_write_mode_overwrite) {
        # Overwrite old file in-place, preserving file ownership and permissions.
        
        my $file = IO::File->new($self->{file_name}, '>');
        
        foreach my $user (@{$self->{users}}) {
            $file->print($self->_build_entry($user), "\n");
        }
        
        $file->close();
    }
    else {
        return undef;
        #or croak("Unexpected file_write_mode: " . $self->{file_write_mode});
    }
    
    return TRUE;
}

TRUE;
