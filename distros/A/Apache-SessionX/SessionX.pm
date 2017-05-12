###################################################################################
#
#   Apache::SessionX - Copyright (c) 1999-2001 Gerald Richter / ecos gmbh
#   Copyright(c) 1998, 1999 Jeffrey William Baker (jeffrey@kathyandjeffrey.net)
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: SessionX.pm,v 1.4 2001/12/04 13:33:39 richter Exp $
#
###################################################################################


package Apache::SessionX ;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '2.01';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::SessionX::Config ;

use constant NEW      => Apache::Session::NEW () ;
use constant MODIFIED => Apache::Session::MODIFIED () ;
use constant DELETED  => Apache::Session::DELETED () ;
use constant SYNCED   => Apache::Session::SYNCED () ;


sub TIEHASH {
    my $class = shift;
    
    my $session_id = shift;
    my $args       = shift || {};

    if(ref $args ne "HASH") 
        {
        die "Additional arguments should be in the form of a hash reference";
        }

    my $config = $args -> {config} || $Apache::SessionX::Config::default;
    foreach my $cfg (keys  (%{$Apache::SessionX::Config::param{$config}})) 
        {
        $args -> {$cfg} = $Apache::SessionX::Config::param{$config} -> {$cfg} if (!exists $args -> {$cfg}) ;
        }  
    
    my $self = 
        {
        args         => $args,
        data         => { _session_id => $session_id },
        initial_session_id => $session_id,
        lock         => 0,
        lock_manager => undef,
        object_store => undef,
        status       => 0,
        serialized   => undef,
        idfrom       => $args -> {idfrom},
        newid        => $args -> {newid},
        };
    
    bless $self, $class;

    $self -> require_modules ($args) ;

    $self -> init if (!$args -> {'lazy'}) ;


    return $self ;
    }


sub require_modules
    {
    my $self = shift ;
    my $args = shift ;

    # check object_store and lock_manager classes (Apache::Session 1.00)
    
    foreach my $mod ('Store', 'Lock', 'Generate', 'Serialize')
        {
        if ($args -> {$mod})
            {
            if (!($args -> {$mod} =~ /::/)) 
                {
                my $modname = "Apache::SessionX::$mod\:\:$args->{$mod}" ;
                eval "require $modname" ;
                if ($@) 
                    {
                    $@ = '' ;
                    $modname = "Apache::Session::$mod\:\:$args->{$mod}" ;
                    eval "require $modname" ;
                    }

                die "Cannot require $modname ($@)" if ($@) ;
                $args->{$mod} = $modname ;
                }
            else
                {
                my $modname = $args->{$mod} ;
                eval "require $modname" ;
                die "Cannot require $modname" if ($@) ;
                }
            }
        }
    }





sub init
    {
    my $self = shift ;

    #If a session ID was passed in, this is an old hash.
    #If not, it is a fresh one.

    $self->populate;

    my $session_id = $self->{data}->{_session_id} ;

    if (!$session_id && $self -> {idfrom})
        {
        $session_id = $self->{data}->{_session_id} = &{$self->{generate}}($self, $self -> {idfrom})  ;
        }

    $self->{initial_session_id} ||= $session_id ;


    if (defined $session_id  && $session_id) 
        {
        #check the session ID for remote exploitation attempts
        #this will die() on suspicious session IDs.        

        #eval { &{$self->{validate}}($self); } ;
        &{$self->{validate}}($self); 
        #if (!$@)
            { # session id is ok        

            $self->{status} &= ($self->{status} ^ NEW);

	    if ($self -> {'args'}{'create_unknown'})
	        {
                eval { $self -> restore } ;
	        #warn "Try to load session: $@" if ($@) ;
	        $@ = "" ;
	        $session_id = $self->{data}->{_session_id} ;
	        }
	    else
	        {
	        $self->restore;
	        }
            }
        }

    $@ = '' ;

    if (!($self->{status} & SYNCED))
        {
        $self->{status} |= NEW();
        if (!$self->{data}->{_session_id} || $self -> {'args'}{'recreate_id'})
            {
            if (exists ($self->{generate}))
                { # Apache::Session >= 1.50
	        $self->{data}->{_session_id} = &{$self->{generate}}($self)  ;
                }
            else
                {
	        $self->{data}->{_session_id} = $self -> generate_id() ;
                }
            }
        $self->save;
        }
    else
        {
        $self -> {newidpending} = $self -> {newid} ;
        }

    
    #warn "Session INIT $self->{initial_session_id};$self->{data}->{_session_id};" ;

    return $self;
    }





sub FETCH {
    my $self = shift;
    my $key  = shift;

    $self -> init if (!$self -> {'status'}) ;

    return $self->{data}->{$key};
}

sub STORE {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    $self->{data}->{$key} = $value;
    
    $self->{status} |= MODIFIED;
    
    return $self->{data}->{$key};
}

sub DELETE {
    my $self = shift;
    my $key  = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    $self->{status} |= MODIFIED;
    
    delete $self->{data}->{$key};
}

sub CLEAR {
    my $self = shift;

    $self -> init if (!$self -> {'status'}) ;

    $self->{status} |= MODIFIED;
    
    $self->{data} = {};
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    my $reset = keys %{$self->{data}};
    return each %{$self->{data}};
}

sub NEXTKEY {
    my $self = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    return each %{$self->{data}};
}

sub DESTROY {
    my $self = shift;
    
    $self->save if ($self -> {'status'}) ;
    # destroy store object to make sure all data is written and everything 
    # is closed before we release the locks
    $self->{object_store} = undef ;
    $self->release_all_locks;
}

sub cleanup 
    {
    my $self = shift;
    
    $self->{initial_session_id} = undef ;
    if ($self -> {'status'})
	{
        $self->save;
        }
#    {
#    local $SIG{__WARN__} = 'IGNORE' ;
#    local $SIG{__DIE__}  = 'IGNORE' ; 
#    eval { $self -> {object_store} -> close } ; # Try to close file storage 
#    $@ = "" ;
#    }

    # destroy store object to make sure all data is written and everything 
    # is closed before we release the locks
    $self->{object_store} = undef ;
    $self->release_all_locks;

    $self->{'status'} = 0 ;
    $self->{data} = {} ;
    $self->{serialized} = undef ;
    # destroy lock object to make sure all locks are really released
    $self->{lock_manager} = undef ;
    }


sub setid {
    my $self = shift;

    $self->{'status'} = 0 ;
    $self->{data}->{_session_id} = $self->{initial_session_id} = shift ;
}

sub setidfrom {
    my $self = shift;

    $self->{'status'} = 0 ;
    $self->{data}->{_session_id} = $self->{initial_session_id} = undef ;
    $self->{idfrom} = shift ;

}
sub getid {
    my $self = shift;

    return $self->{data}->{_session_id}  ;
}

sub getids {
    my $self = shift;
    my $init = shift;

    $self -> init if ($init && !$self -> {'status'}) ;

    if ($self -> {newidpending} && $self->{status}) 
        {
        $self->{data}->{_session_id} = &{$self->{generate}}($self) ;
        $self -> {newidpending} = 0 ;
        $self->{status} |= NEW ;
        }

    return ($self->{initial_session_id}, $self->{data}->{_session_id},  $self->{status} & MODIFIED) ;
}

sub delete {
    my $self = shift;
    
    return if ($self->{status} & NEW);
    
    $self->{initial_session_id} = "!DELETE" ;

    $self -> init if (!$self -> {'status'}) ;

    $self->{status} |= DELETED;
    $self->save;
    $self->{data} = {} ; # Throw away the data
}    



sub restore {
    my $self = shift;
    
    return if ($self->{status} & SYNCED);
    return if ($self->{status} & NEW);
    
    if (exists $self -> {'args'}->{Transaction} && $self -> {'args'}->{Transaction}) 
        {
        $self->acquire_write_lock;
        }
    else
        {
        $self->acquire_read_lock;
        }

    $self->{object_store}->materialize($self);
    &{$self->{unserialize}}($self);
    
    $self->{status} &= ($self->{status} ^ MODIFIED);
    $self->{status} |= SYNCED
}


sub save {
    my $self = shift;
    
    return unless (
        $self->{status} & MODIFIED || 
        $self->{status} & NEW      || 
        $self->{status} & DELETED
    );
    
    if ($self -> {newidpending}) 
        {
        $self->{data}->{_session_id} = &{$self->{generate}}($self) ;
        $self -> {newidpending} = 0 ;
        $self->{status} |= NEW ;
        }

    $self->acquire_write_lock;

    if ($self->{status} & DELETED) {
        $self->{object_store}->remove($self);
        $self->{status} |= SYNCED;
        $self->{status} &= ($self->{status} ^ MODIFIED);
        $self->{status} &= ($self->{status} ^ DELETED);
        return;
    }
    if ($self->{status} & NEW) {
        &{$self->{serialize}}($self);
        $self->{object_store}->insert($self);
        $self->{status} &= ($self->{status} ^ NEW);
        $self->{status} |= SYNCED;
        $self->{status} &= ($self->{status} ^ MODIFIED);
        return;
    }

    if ($self->{status} & MODIFIED) {
        &{$self->{serialize}}($self);
        $self->{object_store}->update($self);
        $self->{status} &= ($self->{status} ^ MODIFIED);
        $self->{status} |= SYNCED;
        return;
    }
}


#

# For Apache::Session 1.00
#

sub get_object_store {
    my $self = shift;

    return new {$self -> {'args'}{'object_store'}} $self;
}

sub get_lock_manager {
    my $self = shift;
    
    return new {$self -> {'args'}{'lock_manager'}} $self;
}

#
# Default validate for Apache::Session < 1.53
#

sub validate {
    #This routine checks to ensure that the session ID is in the form
    #we expect.  This must be called before we start diddling around
    #in the database or the disk.

    my $session = shift;
    
    if ($session->{data}->{_session_id} !~ /^[a-fA-F0-9]+$/) {
        die 'Invalid session id' ;
    }
}

#
# For Apache::Session >= 1.50
#

sub populate 
    {
    my $self = shift;

    my $store = $self->{args}->{Store};
    my $lock  = $self->{args}->{Lock};
    if (!$self->{populated})
        {
        my $gen   = $self->{args}->{Generate};
        my $ser   = $self->{args}->{Serialize};


        $self->{object_store} = new $store $self if ($store) ;
        $self->{lock_manager} = new $lock $self if ($lock);
        $self->{generate}     = \&{$gen . '::generate'} if ($gen);
        $self->{'validate'}     = \&{$gen . '::validate'} if ($gen && defined (&{$gen . '::validate'}));
        $self->{serialize}    = \&{$ser . '::serialize'} if ($ser);
        $self->{unserialize}  = \&{$ser . '::unserialize'} if ($ser) ;

        if (!defined ($self->{'validate'}))
            {
            $self->{'validate'} = \&validate ;
            }
        $self->{populated} = 1 ;
        }
    else
        { # recreate only store & lock classes as far as necessary
        $self->{object_store} ||= new $store $self if ($store) ;
        $self->{lock_manager} ||= new $lock $self if ($lock);
        }

    return $self;
    }



1 ;


__END__

=head1 NAME

Apache::SessionX  - An extented persistence framework for session data

=head1 SYNOPSIS

=head1 DESCRIPTION

Apache::SessionX extents Apache::Session. 
It was initialy written to use Apache::Session from inside of HTML::Embperl, 
but is seems to be usefull outside of Embperl as well, so here is it as standalone module.

Apache::Session is a persistence framework which is particularly useful
for tracking session data between httpd requests.  Apache::Session is
designed to work with Apache and mod_perl, but it should work under
CGI and other web servers, and it also works outside of a web server
altogether.

Apache::Session consists of five components: the interface, the object store,
the lock manager, the ID generator, and the serializer.  The interface is
defined in SessionX.pm, which is meant to be easily subclassed.  The object
store can be the filesystem, a Berkeley DB, a MySQL DB, an Oracle DB, or a
Postgres DB. Locking is done by lock files, semaphores, or the locking
capabilities of MySQL and Postgres.  Serialization is done via Storable, and
optionally  ASCII-fied via MIME or pack().  ID numbers are generated via MD5. 
The reader is encouraged to extend these capabilities to meet his own
requirements.

=head1 INTERFACE

The interface to Apache::SessionX is very simple: tie a hash to the
desired class and use the hash as normal.  The constructor takes two
optional arguments.  The first argument is the desired session ID
number, or undef for a new session.  The second argument is a hash
of options that will be passed to the object store and locker classes.


=head2 Addtional Attributes for TIE

=over 4

=item lazy

By Specifing this attribute, you tell Apache::Session to not do any
access to the object store, until the first read or write access to
the tied hash. Otherwise the B<tie> function will make sure the hash
exist or creates a new one.

=item create_unknown

Setting this to one causes Apache::Session to create a new session
with the given id (or a new id, depending on C<recreate_id>)
when the specified session id does not exists. Otherwise it will die.

=item recreate_id

Setting this to one causes Apache::Session to create a new session id
when the specified session id does not exists. 

=item idfrom

instead of passing in a session id, you can pass in a string, from which
Apache::SessionX generates the id in case it needs one. The main advantage
from generating the id by yourself is, that in 'lazy' mode the
id is only generated when the session is accessed.

=item newid

Setting this to one will cause Apache::SessionX to generate a new id every
time the session is saved. If you call C<getid> or C<getids> it will return
the new id that will be used to save the data.

=item config

Use predefiend config from Apache::SessionX::Config, which is defined by
Makefile.PL


=item object_store

Specify the class for the object store. (The Apache::Session:: prefix is
optional) Only for Apache::Session 1.00.

=item lock_manager

Specify the class for the lock manager. (The Apache::Session:: prefix is
optional) Only for Apache::Session 1.00.

=item Store

Specify the class for the object store. (The Apache::Session::Store prefix is
optional) Only for Apache::Session 1.5x.

=item Lock

Specify the class for the lock manager. (The Apache::Session::Lock prefix is
optional) Only for Apache::Session 1.5x.

=item Generate

Specify the class for the id generator. (The Apache::Session::Generate prefix is
optional) Only for Apache::Session 1.5x.

=item Serialize

Specify the class for the data serializer. (The Apache::Session::Serialize prefix is
optional) Only for Apache::Session 1.5x.


=back

Example using attrubtes to specfiy store and object classes instead of
a derived class:

 use Apache::SessionX

 tie %session, 'Apache::SessionX', undef,
    { 
    object_store => 'DBIStore',
    lock_manager => 'SysVSemaphoreLocker',
    DataSource => 'dbi:Oracle:db' 
    };

NOTE: Apache::SessionX will C<require> the nessecary additional perl modules for you.


=head2 Addtional Methods

=over 4

=item setid ($id)

Set the session id for futher accesses.

=item setidfrom ($string)

Set the string that is passed to the generate function to compute the id.

=item getid

Get the session id. The difference to using $session{_session_id} is,
that in lazy mode, getid will B<not> create a new session id, if it
doesn't exists.

=item getids ($init)

return the an array where the first element is the initial id, the second element
is the current id and the third element is set to true, when the session data was
modified. If the session was deleted, the initial id (first array value) will be set
to '!DELETE'.

If the optional parameter $init is set to true, getids will initialize the session 
(i.e. read from the store) when not already done.

=item cleanup

Writes any pending data, releases all locks and deletes all data from memory.

=back

=head1 SEE ALSO

=over 4

=item See documentation of Apache::Session for more informations about it's internals

=item Apache::SessionX::Generate::MD5

=item Apache::Session::Store::*

=item Apache::Session::Lock::*

=item Apache::Session::Serialize::*

=back


=head1 AUTHORS

Gerald Richter <richter@dev.ecos.de> is the current maintainer.

This class was written by Jeffrey Baker (jeffrey@kathyandjeffrey.net)
but it is taken wholesale from a patch that Gerald Richter
(richter@ecos.de) sent me against Apache::Session.


