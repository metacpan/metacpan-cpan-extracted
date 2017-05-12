package CGI::Builder::Auth::Group
; use strict

; our $VERSION = '0.05'

; our $_group_admin;

; use CGI::Builder::Auth::GroupAdmin
; use CGI::Builder::Auth::User
; use Class::constr 
   ( { name => 'load', init => '_init', copy => 1  }
   , { name => 'new', init => '_factory' }
   )

; use Class::groups
   ( { name => 'config'
     , default =>
        { DBType  => 'Text' # type of database, one of 'DBM', 'Text', or 'SQL'
        , DB      => '.htgroup' # database name
#       , Server  => 'apache'
#       , Locking => 1
#       , Path    => '.' # Path does not seem to work as documented -VV
        , Debug   => 0
      # read, write and create flags. There are four modes: rwc - the default,
      # open for reading, writing and creating. rw - open for reading and
      # writing. r - open for reading only. w - open for writing only.
#       , Flags   => 'rwc'

      # FOR DBI 
#       , Host    => 'localhost'
#       , Port    => ???
#       , User    => ''
#       , Auth    => ''
#       , Driver  => 'SQLite'
#       , GroupTable  => 'groups'
#       , NameField  => 'user_id'
#       , GroupField  => 'group_id'
      
      # FOR DBM Files
#      , DBMF => 'NDBM'
#      , Mode => 0644
       }
     }
   )
; use Class::props   
   ( { name => '_group_admin'
     , default => sub { CGI::Builder::Auth::GroupAdmin->new(%{$_[0]->config}) }
     }
   , { name => 'realm'
     , default => 'main'
     }
   )
; use Object::props
   ( { name => 'id' 
     }
   )

; use overload
   (   '""' => 'as_string'
   ,   fallback => 1
   )

; sub as_string { $_[0]->id }

#---------------------------------------------------------------------
# Initializers
#---------------------------------------------------------------------

# Cancel construction if requested group does not exist
; sub _init { $_[0] = undef unless $_[0]->_exists }

# When constructing a factory, id must be undef
; sub _factory { $_[0]->id(undef) }

#---------------------------------------------------------------------
# Factory Methods
#---------------------------------------------------------------------
; sub list { $_[0]->_group_admin->list }

; sub add 
   { my ($self, $data) = @_
   ; my $group = ref $data ? $data->{group} : $data;
   
   ; return if $self->_exists($group);

   ; $self->_group_admin->create($group) or warn "Creation Failed"
   ; return $self->load(id => $group)
   }
   
#---------------------------------------------------------------------
# Instance Methods
#---------------------------------------------------------------------
; sub _exists 
   { defined $_[1] 
      ? $_[0]->_group_admin->exists($_[1]) 
      : $_[0]->_group_admin->exists($_[0]->id) 
   }
; sub delete 
   { defined $_[1] 
      ? $_[0]->_group_admin->remove($_[1]) 
      : $_[0]->_group_admin->remove($_[0]->id) 
   }

# 
# FIXME add_member & remove_member appear to succeed when !exists user
# 
; sub add_member 
   { my ($self, @users) = @_
   ; my $group = $self->id || shift(@users);
   
   ; return if !$self->_exists($group)

   ; my $user_factory = CGI::Builder::Auth::User->new
   ; for my $user (@users) { 
      next unless $user_factory->_exists($user)
      ; $self->_group_admin->add($user, $group)
      }
   ; 1
   }
; sub remove_member 
   { my ($self, @users) = @_
   ; my $group = $self->id || shift(@users)
   
   ; return if !$self->_exists($group)
   
   ; for my $user (@users)
      { $self->_group_admin->delete($user, $group)
      }
   ; 1
   }
; sub member_list
   { my ($self, $group) = @_
   ; $group = $group || $self->id
   
   ; return if !$self->_exists($group)
   
   ; $self->_group_admin->list($group)
   }

; sub DESTROY
   { ref($_group_admin) 
           and !Scalar::Util::isweak($_group_admin) 
           and Scalar::Util::weaken($_group_admin)
   }
 

=head1 NAME

CGI::Builder::Auth::Group - Provide access to a group table and its rows

=head1 DESCRIPTION

This Class provides an API for manipulating a Group table. The implementation
stores the table in a text file, but developers are free to create their own
implementations of this API that wrap SQL databases or other resources.

Developers using the library probably will not need to manipulate the user
objects directly, since the L<context object|CGI::Builder::Auth::Context>
provides a wrapper around all the common functions. However, developers
creating their own user classes need to pay special attention to implementing
this API correctly.

This document describes the default implementation, and includes many notes
about mandatory and optional features for alternate implementations.

WARNING: This interface is experimental. Developers may create their own
implementations, but are advised to subscribe to the mailing list to be
notified of changes. Backward compatibility is a goal, but is not guaranteed
for future releases.


=head1 SPECIAL PROPERTIES

The group object C<overload>'s the string operator so that it prints the group name
in string context rather than the usual reference information. As a result, you
may use the group object in your code as if it were a (read-only) scalar
containing the group name.

This is required behavior for all implementations. See L<overload> for details.


=head1 CONSTRUCTORS


=head2 C<load(id =E<gt> $id)>

Class method, takes a hash where the key is 'id' (literal) and the value is the
group name you wish to load.

Return a group object with the group name of C<$id>. Return C<undef> if the group
does not exist in the database. 

Note that the group name is required to be unique in a given table.


=head2 C<add($name | \%attr)>

Add a group to the group table.

Class method, takes a scalar that is either the name of the group to add, or a
reference to a hash of group attributes. Attributes supported in this
implementation:

=over

=item B<group>

=back

All implementations are required to support the C<group> attribute, and may
support as many more as they like. Note that the group name is required to be
unique in a given table.

Return the group object on success, undef on failure.


=head1 OTHER CLASS METHODS


=head2 C<config([$opt[,$new_val]])>

Class method, takes one or two scalar arguments.

Store and retrieve configuration options. With one argument C<$opt>, returns
the value of the config option. With two arguments, stores C<$new_val> as the
new value for config option C<$opt>. Returns C<undef> if the option is unset.


=head2 C<list>

Class method, takes no arguments.

Return an array of all groups (as objects) in the group table, or C<undef> on
error.



=head1 INSTANCE (OBJECT) METHODS


=head2 C<add_member(@users)>

Instance method, takes a list of @users arguments. The users may be user
objects, usernames, or a combination of the two.

Create a relationship between the group and user such that the user is added to
the C<member_list>.

Return void (currently always returns true).


=head2 C<delete>

Instance method, takes no arguments.

Delete the group from the group table. After a call to this method, the object
should be considered unusable. 


=head2 C<member_list>

Instance method, takes no arguments.

Return a list of usernames (NOT user objects) who are members of this group.
Implementations may return a list of user objects as long as they have
implemented the overload behavior described above. 

Future releases may require this method to return a list of objects. Alternate
implementations are encouraged to return objects.


=head2 C<remove_member(@users)>

Instance method, takes a list of @users arguments. The users may be user
objects, usernames, or a combination of the two.

Remove a relationship between the group and user such that the user is no
longer returned in the C<member_list>.

Return void (currently always returns true).


=head1 SUPPORT

Support for this module and all the modules of the CBF is via the mailing list.
The list is used for general support on the use of the CBF, announcements, bug
reports, patches, suggestions for improvements or new features. The API to the
CBF is stable, but if you use the CBF in a production environment, it's
probably a good idea to keep a watch on the list.

You can join the CBF mailing list at this url:

L<http://lists.sourceforge.net/lists/listinfo/cgi-builder-users>


=head1 AUTHOR

Vincent Veselosky


=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Vincent Veselosky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 



=cut

"Copyright 2004 Vincent Veselosky [[http://control-escape.com]]";
# vim:ft=perl:expandtab:ts=3:sw=3:
