#=====================================================================
# GROUP CLASS DERIVED FROM Class::DBI
#=====================================================================
package CDBI_group;
use base CDBI_base;

__PACKAGE__->table("auth_group");
__PACKAGE__->columns(All => qw/ group_id description / );
__PACKAGE__->has_many(users => ['CDBI_link', 'user_id'] );
__PACKAGE__->has_many(user_links => 'CDBI_link');

#---------------------------------------------------------------------
# These methods make the class compatible with C::B::A::Group API.
#---------------------------------------------------------------------
sub load
   { my ($class,%args) = @_
   ; $class->retrieve($args{id});
   }

sub add
   { my ($class,$args) = @_
   # $args might be just a string with the name
   ; ref($args) or $args = { group => $args }
   # group id stored in different field, rename it.
   ; $$args{group_id} = delete $$args{group}
   ; $class->create($args)
   }

sub list { ($_[0]->retrieve_all) }

sub add_member
   { my ($self,@users) = @_
   ; for my $user (@users)
      { $self->add_to_user_links({ user_id => $user })
      }
   ; return 1
   }

sub remove_member
   { my ($self,@users) = @_
   ; for my $user (@users)
      { $self->user_links( user_id => $user )->delete_all
      }
   ; return 1
   }

sub member_list { ($_[0]->users) }

"Copyright 2004 by Vincent Veselosky [[http://www.control-escape.com]]";
