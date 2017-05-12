#############################################################################
#
# Apache::Session::Store::File
# Implements session object storage via flat files
# Copyright(c) 1998, 1999, 2000, 2004 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Store::File;

use strict;
use Symbol;
use IO::File;
use Fcntl;
use vars qw($VERSION);

$VERSION = '1.04';

$Apache::Session::Store::File::Directory = '/tmp';

sub new {
    my $class = shift;
    my $self;
    
    $self->{fh}     = Symbol::gensym();
    $self->{opened} = 0;
    
    return bless $self, $class;
}

sub insert {
    my $self    = shift;
    my $session = shift;
 
    my $directory = $session->{args}->{Directory} || $Apache::Session::Store::File::Directory;

    if (-e $directory.'/'.$session->{data}->{_session_id}) {
        die "Object already exists in the data store";
    }
    
    my $file = $directory.'/'.$session->{data}->{_session_id};
    sysopen ($self->{fh}, $file, O_RDWR|O_CREAT) ||
        die "Could not open file $file: $!";

    $self->{opened} = 1;
    
    print {$self->{fh}} $session->{serialized};
    $self->{fh}->flush();
}

sub update {
    my $self    = shift;
    my $session = shift;
    
    my $directory = $session->{args}->{Directory} || $Apache::Session::Store::File::Directory;

    if (!$self->{opened}) {
        my $file = $directory.'/'.$session->{data}->{_session_id};
        sysopen ($self->{fh}, $file, O_RDWR|O_CREAT) ||
            die "Could not open file $file: $!";

        $self->{opened} = 1;
    }
    
    truncate($self->{fh}, 0) || die "Could not truncate file: $!";
    seek($self->{fh}, 0, 0);
    print {$self->{fh}} $session->{serialized};
    $self->{fh}->flush();
}

sub materialize {
    my $self    = shift;
    my $session = shift;
    
    my $directory = $session->{args}->{Directory} || $Apache::Session::Store::File::Directory;
    
    my $file = $directory.'/'.$session->{data}->{_session_id};
    if (-e $file) {
        if (!$self->{opened}) {
            sysopen ($self->{fh}, $file, O_RDWR|O_CREAT) ||
                die "Could not open file $file: $!";

            $self->{opened} = 1;
        }
        else {
            seek($self->{fh}, 0, 0) || die "Could not seek file: $!";
        }

        $session->{serialized} = '';
        
        my $fh = $self->{fh};
        while (my $line = <$fh>) {
            $session->{serialized} .= $line;
        }
    }
    else {
        die "Object does not exist in the data store";
    }
}    

sub remove {
    my $self    = shift;
    my $session = shift;
        
    my $directory = $session->{args}->{Directory} || $Apache::Session::Store::File::Directory;

    if ($self->{opened}) {
        CORE::close $self->{fh};
        $self->{opened} = 0;
    }

    my $file = $directory.'/'.$session->{data}->{_session_id};
    if (-e $file) {
        unlink ($file) ||
            die "Could not remove file $file: $!";
    }
    else {
        die "Object does not exist in the data store";
    }
}

sub close {
    my $self = shift;
    
    if ($self->{opened}) {
        CORE::close $self->{fh};
        $self->{opened} = 0;
    }
}

sub DESTROY {
    my $self = shift;
    
    if ($self->{opened}) {    
        CORE::close $self->{fh};
    }
}

1;

=pod

=head1 NAME

Apache::Session::Store::File - Store persistent data on the filesystem

=head1 SYNOPSIS


 use Apache::Session::Store::File;

 my $store = new Apache::Session::Store::File;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

This module fulfills the storage interface of Apache::Session.  The serialized
objects are stored in files on your filesystem.

=head1 OPTIONS

This module requires one argument in the usual Apache::Session style.  The
name of the option is Directory, and the value is the full path of the 
directory where you wish to place the files.  Example

 tie %s, 'Apache::Session::File', undef,
    {Directory => '/tmp/sessions'};

=head1 NOTES

All session objects are stored in the same directory.  Some filesystems, such
as Linux's ext2fs, have O(n) performance where n is the number of files in a
directory.  Other filesystems, like Sun's UFS, and Linux's reiserfs, do not
have this problem.  You should consider your filesystem's performance before
using this module to store many objects.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session>
