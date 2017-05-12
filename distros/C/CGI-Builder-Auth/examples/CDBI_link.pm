#=====================================================================
# LINK CLASS DERIVED FROM Class::DBI
#=====================================================================
package CDBI_link;
use base CDBI_base;

__PACKAGE__->table("auth_group_members");
__PACKAGE__->columns(Primary => qw/ group_id user_id / );
__PACKAGE__->has_a(user_id => 'CDBI_user' );
__PACKAGE__->has_a(group_id => 'CDBI_group' );

"Copyright 2004 by Vincent Veselosky [[http://www.control-escape.com]]";
