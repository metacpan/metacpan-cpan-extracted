#=====================================================================
# USER CLASS DERIVED FROM Class::DBI
#=====================================================================
package CDBI_user;
use base CDBI_base;

__PACKAGE__->table("auth_user");
__PACKAGE__->columns(All => qw/ user_id password email name / );

#---------------------------------------------------------------------
# These methods make the class compatible with C::B::A::User API.
#---------------------------------------------------------------------

sub anonymous
   { require CGI::Builder::Auth::User
   ; CGI::Builder::Auth::User->anonymous
   }

sub load
   { my ($class,%args) = @_
   ; $class->retrieve($args{id});
   }

sub add
   { my ($class,$args) = @_
   # username stored in different field, rename it.
   ; $$args{user_id} = delete $$args{username}
   ; $class->create($args);
   }

sub list { ($_[0]->retrieve_all) }

sub password_matches
   { my ($self,$password) = @_
   ; return $self->password eq $password
   }

"Copyright 2004 by Vincent Veselosky [[http://www.control-escape.com]]";
