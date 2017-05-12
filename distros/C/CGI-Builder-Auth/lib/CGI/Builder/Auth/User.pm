package CGI::Builder::Auth::User
; use strict
; require Scalar::Util

; our $VERSION = '0.05'
; our $_user_admin;


; use CGI::Builder::Auth::UserAdmin
; use Digest::MD5 'md5_hex'

; use Class::constr 
    ( { name => 'load',      init => '_real', copy => 1 }
    , { name => 'anonymous', init => '_anon', copy => 1  }
    , { name => 'new',       init => '_factory' }
    )
; use Class::groups
    ( { name => 'config'
      , default =>
         { DBType  => 'Text' # type of database, one of 'DBM', 'Text', or 'SQL'
         , DB      => '.htpasswd' # database name
#        , Server  => 'apache'
#        , Encrypt => 'MD5'
         , Encrypt => 'crypt'
#        , Locking => 1
#        , Path    => '.'
         , Debug   => 0
        # read, write and create flags. There are four modes: rwc - the default,
        # open for reading, writing and creating. rw - open for reading and
        # writing. r - open for reading only. w - open for writing only.
#         , Flags   => 'rwc'

        # FOR DBI 
#         , Host    => 'localhost'
#         , Port    => ???
#         , User    => ''
#         , Auth    => ''
#          , Driver  => 'SQLite'
#          , UserTable  => 'users'
#          , NameField  => 'user_id'
#         , PasswordField  => 'password'
        
        # FOR DBM Files
#         , DBMF => 'NDBM'
#         , Mode => 0644
         }
      }
    )
; use Class::props 
   ( { name => '_user_admin'
     , default => sub { CGI::Builder::Auth::UserAdmin->new(%{$_[0]->config}) }
     }
   , { name => 'realm'
     , default => 'main'
     }
   )
; use Object::props 
   ( { name => 'id'
     , default => 'anonymous'
     }
   )

; use overload
   (    '""' => 'as_string'
   ,    fallback => 1
   )
# Overload Magic
; sub as_string { $_[0]->id }

# INIT Routines

# Cancel construction if requested user does not exist
; sub _real { $_[0] = undef unless $_[0]->_exists }

# Force anonymous even if caller foolishly passed an ID
; sub _anon { $_[0]->id('anonymous') }

# When building a factory, id must be undef
; sub _factory { $_[0]->id(undef) }


#---------------------------------------------------------------------
# Factory Methods
#---------------------------------------------------------------------
; sub list { $_[0]->_user_admin->list }

; sub add 
    { my ($self, $data) = @_
    ; my $username = delete $data->{'username'}
    ; my $password = delete $data->{'password'}

    ; return if $username eq 'anonymous'
    ; return if $self->_exists($username)
    
    ; $password = join(":",$username,$self->realm,$password)
        if $self->_user_admin->{ENCRYPT} eq 'MD5'

    ; return $self->_user_admin->add($username, $password, $data)
        ? $self->load(id => $username)
        : undef
    }

#---------------------------------------------------------------------
# Instance Methods
#---------------------------------------------------------------------
; sub _exists 
    { defined $_[1] 
        ? $_[0]->_user_admin->exists($_[1]) 
        : $_[0]->_user_admin->exists($_[0]->id) 
    }
; sub delete 
    { defined $_[1] 
        ? $_[0]->_user_admin->delete($_[1]) 
        : $_[0]->_user_admin->delete($_[0]->id) 
    }
; sub suspend 
    { defined $_[1] 
        ? $_[0]->_user_admin->suspend($_[1]) 
        : $_[0]->_user_admin->suspend($_[0]->id) 
    }
; sub unsuspend 
    { defined $_[1] 
        ? $_[0]->_user_admin->unsuspend($_[1]) 
        : $_[0]->_user_admin->unsuspend($_[0]->id) 
    }

; sub password_matches
    { my ($self, $passwd) = @_
    ; return unless $self->_exists
    ; $passwd = join(":",$self->id,$self->realm,$passwd)
        if $self->_user_admin->{ENCRYPT} eq 'MD5'
        
    ; my $stored_passwd = $self->_user_admin->password($self->id)
    ; return $self->_user_admin->{ENCRYPT} eq 'crypt'
        ? crypt($passwd,$stored_passwd) eq $stored_passwd
        : $self->_user_admin->encrypt($passwd) eq $stored_passwd
    }

; sub DESTROY
    { ref($_user_admin) 
            and !Scalar::Util::isweak($_user_admin) 
            and Scalar::Util::weaken($_user_admin)
    }

=head1 NAME

CGI::Builder::Auth::User - Provide access to a user table and its rows

=head1 DESCRIPTION

This Class provides an API for manipulating a User table. The implementation
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

The user object C<overload>'s the string operator so that prints the username
in string context rather than the usual reference information. As a result, you
may use the user object in your code as if it were a (read-only) scalar
containing the username.

This is required behavior for all implementations. See L<overload> for details.


=head1 CONSTRUCTORS


=head2 C<anonymous>

Class method, takes no arguments.

Return a user object with id of 'anonymous'. This user belongs to no groups.


=head2 C<load(id =E<gt> $id)>

Class method, takes a hash where the key is 'id' (literal) and the value is the
username you wish to load.

Return a user object with the username of C<$id>. Return C<undef> if the user
does not exist in the database. Attempts to C<load> a user with id of
'anonymous' must always fail, this username is reserved. To construct an
anonymous user, call the 'anonymous' constructor instead.
 
Note that the username is required to be unique in a given table.


=head2 C<add(\%attr)>

Add a user to the user table.

Class method, takes a reference to a hash of user attributes. Attributes
supported in this implementation:

=over

=item B<username>

=item B<password>

=back

All implementations are required to support these two attributes, and may
support as many more as they like. Note that the username is required to be
unique in a given table.

Return the user object on success, undef on failure.


=head1 OTHER CLASS METHODS


=head2 C<config([$opt[,$new_val]])>

Class method, takes one or two scalar arguments.

Store and retrieve configuration options. With one argument C<$opt>, returns
the value of the config option. With two arguments, stores C<$new_val> as the
new value for config option C<$opt>. Returns C<undef> if the option is unset.


=head2 C<list>

Class method, takes no arguments.

Return an array of all users (as objects) in the user table, or C<undef> on
error.



=head1 INSTANCE (OBJECT) METHODS


=head2 C<delete>

Instance method, takes no arguments.

Delete the user from the user table. After a call to this method, the object
should be considered unusable. (In practice this implementation makes the
object anonymous, but this behavior is not required and is not guaranteed to be
true in future releases. Do not rely on it.)


=head2 C<password_matches($password)>

Instance method, takes one scalar argument, a string.

Return true if the C<$password> argument matches the password stored in the
table. This allows the storage class to implement its own one-way hash function
to obscure the password in storage if desired. Note that the user object is
never required to return the stored password, but implementations may allow
this if desired.


=head2 C<suspend>

Instance method, takes no arguments.

Places this user in a suspended status. When suspended, the user method C<password_matches>
always returns false.

This method is not currently used by the Context object, but support will be
added in a (near) future release. Therefore, implementations are required to
support this method.


=head2 C<unsuspend>

Instance method, takes no arguments.

Removes this user from suspended status. When suspended, the user method C<password_matches>
always returns false.

This method is not currently used by the Context object, but support will be
added in a (near) future release. Therefore, implementations are required to
support this method.


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
# vim:expandtab:ts=3:sw=3:ft=perl:
