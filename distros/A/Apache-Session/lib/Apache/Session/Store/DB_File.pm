#############################################################################
#
# Apache::Session::Store::DB_File
# Implements session object storage via Perl's DB_File module
# Copyright(c) 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Store::DB_File;

use strict;
use vars qw($VERSION);
use DB_File;

$VERSION = '1.01';

sub new {
    my $class = shift;
    
    return bless {dbm => {}}, $class;
}

sub insert {
    my $self    = shift;
    my $session = shift;
    
    if (!tied %{$self->{dbm}}) {
        my $rv = tie %{$self->{dbm}}, 'DB_File', $session->{args}->{FileName};

        if (!$rv) {
            die "Could not open dbm file $session->{args}->{FileName}: $!";
        }
    }
    
    if (exists $self->{dbm}->{$session->{data}->{_session_id}}) {
        die "Object already exists in the data store";
    }
    
    $self->{dbm}->{$session->{data}->{_session_id}} = $session->{serialized};
}

sub update {
    my $self = shift;
    my $session = shift;
    
    if (!tied %{$self->{dbm}}) {
        my $rv = tie %{$self->{dbm}}, 'DB_File', $session->{args}->{FileName};

        if (!$rv) {
            die "Could not open dbm file $session->{args}->{FileName}: $!";
        }
    }
    
    $self->{dbm}->{$session->{data}->{_session_id}} = $session->{serialized};
}

sub materialize {
    my $self = shift;
    my $session = shift;
    
    if (!tied %{$self->{dbm}}) {
        my $rv = tie %{$self->{dbm}}, 'DB_File', $session->{args}->{FileName};

        if (!$rv) {
            die "Could not open dbm file $session->{args}->{FileName}: $!";
        }
    }
    
    $session->{serialized} = $self->{dbm}->{$session->{data}->{_session_id}};

    if (!defined $session->{serialized}) {
        die "Object does not exist in data store";
    }
}

sub remove {
    my $self = shift;
    my $session = shift;
    
    if (!tied %{$self->{dbm}}) {
        my $rv = tie %{$self->{dbm}}, 'DB_File', $session->{args}->{FileName};

        if (!$rv) {
            die "Could not open dbm file $session->{args}->{FileName}: $!";
        }
    }
    
    delete $self->{dbm}->{$session->{data}->{_session_id}};
}

1;

=pod

=head1 NAME

Apache::Session::Store::DB_File - Use DB_File to store persistent objects

=head1 SYNOPSIS

 use Apache::Session::Store::DB_File;

 my $store = new Apache::Session::Store::DB_File;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

This module fulfills the storage interface of Apache::Session.  The serialized
objects are stored in a Berkeley DB file using the DB_File Perl module.  If
DB_File works on your platform, this module should also work.

=head1 OPTIONS

This module requires one argument in the usual Apache::Session style.  The
name of the option is FileName, and the value is the full path of the database
file to be used as the backing store.  If the database file does not exist,
it will be created.  Example:

 tie %s, 'Apache::Session::DB_File', undef,
    {FileName => '/tmp/sessions'};

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session>, L<DB_File>
