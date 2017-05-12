# Apache::Session::SharedMem 

# Copyright 2004 Simon Wistow <simon@thegestalt.org>
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package Apache::Session::SharedMem;

use strict;
use vars qw(@ISA $VERSION);

use IPC::Cache;
use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::SharedMem;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;

@ISA = qw(Apache::Session);
$VERSION = '0.6';

use Apache::Session;


@ISA = qw(Apache::Session);


sub populate {
    my ($self) = @_;


    $self->{object_store} = new Apache::Session::Store::SharedMem $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

sub DESTROY {
    my $self = shift;
    
    $self->save;
    $self->{object_store}->close;
    $self->release_all_locks;
}


sub new 
{
    my ($class, $session) = shift;
    
    my ($self, $cacheargs); 
    

    $cacheargs->{namespace}  = $session->{data}->{_session_id};
    $cacheargs->{expires_in} = $session->{args}->{expires_in};

    $self->{cache}  = new IPC::Cache ( $cacheargs );
    
    return bless $self, $class;
}


1;

=head1 NAME

Apache::Session::SharedMem - Session management via shared memory

=head1 SYNOPSIS

 use Apache::Session::SharedMem;

 tie %s, 'Apache::Session::SharedMem', $sessionid, { expires_in => 86400 }

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses B<IPC::Cache> 
to store session variables in shared memory.

The advantage of this is that it is fairly fast (about the same speed, if 
not faster than B<Apache::Session::File> and is very easy to set up
making it perfect for when you want to test sessions but can't be bothered 
to set up a database or don't want cgi scripts writing temp files.

=head2 CAVEATS

It probably isn't very scaleable (i.e you probably shouldn't use this in 
production code which is going to get hit hard.

I have no idea if it leaks memory yet. I've only just written it :)

Apparently it B<IPC::ShareLite> (and hence B<IPC::Cache>) don't work under Perl 5.6.

=head1 USAGE

Just the same as all the other B<Apache::Session> modules. You can optionally 
pass the parameter B<expires_in> which will tell the Session to expire in
a certain time. 


=head1 PREREQUISITES

B<Apache::Session::SharedMem> needs B<Apache::Session> and B<IPC:Cache>, both available from the CPAN.

=head1 AUTHOR

Simon Wistow <simon@twoshortplanks.com>

=head1 COPYRIGHT

This software is copyright(c) 2000, 2001, 2002 Simon Wistow. It is free software
and can be used under the same terms as perl, i.e. either the GNU
Public Licence or the Artistic License.

=head1 SEE ALSO

L<Apache::Session>, L<IPC::Cache>

=cut

