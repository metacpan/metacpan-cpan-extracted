# Apache::Session::Store::SharedMem

# Copyright 2004, Simon Wistow <simon@thegestalt.org>
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Apache::Session::Store::SharedMem;

use strict;
use IPC::Cache;




sub new 
{
    my ($class, $session) = shift;
    
    my ($self, $cacheargs); 
    

    $cacheargs->{namespace}  = $session->{data}->{_session_id};
    $cacheargs->{expires_in} = $session->{args}->{expires_in};

    $self->{cache}  = new IPC::Cache ( $cacheargs );
    
    return bless $self, $class;
}

sub insert {

    my ($self, $session) = @_;
    
    $self->{cache}->set($session->{data}->{_session_id}, $session->{serialized});
}

sub update {

    my ($self, $session) = @_;
    
    $self->{cache}->set($session->{data}->{_session_id}, $session->{serialized});
}

sub materialize {
    my ($self, $session) = @_;
    
    $session->{serialized} = $self->{cache}->get($session->{data}->{_session_id});
    return undef unless defined $session->{serialized};

}    

sub remove {

    my ($self, $session) = @_;
    
    
    $self->{cache}->clear();
    
}

sub close {
    
}


1;

=pod

=head1 NAME

Apache::Session::Store::SharedMem - Store persistent data in shared memory

=head1 SYNOPSIS


 use Apache::Session::Store::SharedMem;
 
 my $store = new Apache::Session::Store::SharedMem;
 
 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

This module fulfills the storage interface of B<Apache::Session>.  The serialized
objects are stored in shared memory.

=head1 OPTIONS

This module can optionally take one argument in the usual Apache::Session style.  
The name of the option is B<expires_in>, and the value is the amount of time, in
seconds, that the data in the session will expire in.


 # session wil expire in a day
 tie %s, 'Apache::Session::SharedMem', undef, { expires_in => 86400 };


=head1 AUTHOR

This module was written by Simon Wistow <simon@twoshortplanks.com>.


=head1 COPYRIGHT

Copyright 2000, 2001 Simon Wistow <simon@twoshortplanks.com>
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::SharedMem>, L<IPC::Cache>
