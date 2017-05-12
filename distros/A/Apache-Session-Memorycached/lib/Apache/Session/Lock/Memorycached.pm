############################################################################
#
# Apache::Session::Lock::Memorycached
# Copyright(c) eric german <germanlinux@yahoo.fr> 
# Distribute under the Artistic License
#
############################################################################

package Apache::Session::Lock::Memorycached;

use strict;

use vars qw($VERSION);

$VERSION = '1.0';


sub new {
    my $class = shift;
    
    return bless { read => 0, write => 0, opened => 0, id => 0 }, $class;
}

sub acquire_read_lock  {
    my $self    = shift;
    my $session = shift;
    
    return if $self->{read};

    if (!$self->{opened}) {
        $self->{opened} = 1;
    }
    $self->{read} = 1;
}

sub acquire_write_lock {
    my $self    = shift;
    my $session = shift;

    return if $self->{write};
    
    if (!$self->{opened}) {
        $self->{opened} = 1;
    }
    $self->{write} = 1;
}

sub release_read_lock  {
    my $self    = shift;
    my $session = shift;
    
    die unless $self->{read};
    
    if (!$self->{write}) {
        $self->{opened} = 0;
    }
    
    $self->{read} = 0;
}

sub release_write_lock {
    my $self    = shift;
    my $session = shift;
    
    die unless $self->{write};
    
    if ($self->{read}) {
    }
    else {
        $self->{opened} = 0;
    }
    
    $self->{write} = 0;
}

sub release_all_locks  {
    my $self    = shift;
    my $session = shift;

    if ($self->{opened}) {
    }
    
    $self->{opened} = 0;
    $self->{read}   = 0;
    $self->{write}  = 0;
}

sub DESTROY {
    my $self = shift;
    
    $self->release_all_locks;
}

sub clean {
    my $self = shift;
    my $dir  = shift;
    my $time = shift;

           
}

1;

=pod

=head1 NAME

Apache::Session::Lock::File - Provides mutual exclusion using flock

=head1 SYNOPSIS

 use Apache::Session::Lock::File;
 
 my $locker = new Apache::Session::Lock::File;
 
 $locker->acquire_read_lock($ref);
 $locker->acquire_write_lock($ref);
 $locker->release_read_lock($ref);
 $locker->release_write_lock($ref);
 $locker->release_all_locks($ref);

 $locker->clean($dir, $age);

=head1 DESCRIPTION

Apache::Session::Lock::Memorycached  fulfills the locking interface of 
Apache::Session.  NO locking is using .

=head1 CONFIGURATION


none

=head1 NOTES


=head1 AUTHOR

This module was written by eric german <germanlinux@yahoo.fr>

=head1 SEE ALSO

L<Apache::Session>
