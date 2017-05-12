package DCE::ACL;

use strict;
use vars qw($VERSION @ISA);
use DCE::UUID ();
use DynaLoader ();
use DCE::aclbase ();

@DCE::ACL::ISA = qw(DynaLoader DCE::aclbase);
@DCE::ACL::handle::ISA = qw(DCE::ACL);

$VERSION = '1.01';

bootstrap DCE::ACL $VERSION;
*AUTOLOAD = \&DCE::aclbase::AUTOLOAD; #bleh

# Preloaded methods go here.

#sec_acl_entry_type_t
my(@types) = qw(
user_obj
group_obj
other_obj
user
group
mask_obj
foreign_user
foreign_group
foreign_other
unauthenticated
extended
any_other
user_obj_deleg
user_deleg
for_user_deleg
group_obj_deleg
group_deleg
for_group_deleg
other_obj_deleg
for_other_deleg
any_other_deleg
	    );

my(%types);
{
    my($i, $eval);
    $i = 0; $eval = "";
    foreach $_ (@types) {
	$types{$_} = $i;
	$eval .= "sub type_$_ {$i};\n";
	$i++;
    }
    eval $eval;
}

sub types { @types }

sub type { 
    my($self, $idx) = @_;
    return $types[$_[1]] if $idx =~ /^\d+$/;
    $types{$idx};
}

sub fail {
    my($self, $status) = @_;
    $status != 0;
}
#sec_acl_type_t
sub type_object {0}
sub type_default_object {1}
sub type_default_container {2}

sub DCE::ACL::handle::new_list {
    my($h, $mgr) = @_;
    my($list, $status) = $h->lookup($mgr);
    $h->acls->delete;
    ($list, $status);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

DCE::ACL - Perl interface to DCE ACL client API

=head1 SYNOPSIS

  use DCE::ACL;

  $aclh = DCE::ACL->bind($object);
  
=head1 DESCRIPTION

DCE::ACL provides a Perl interface to the sec_acl_* client API.
As the sec_acl_list_t structure is rather complex, additional classes
and methods are provided so Perl scripts can deal with it in a reasonable
fashion.

=head1 DCE::ACL::handle methods

=over 4

=item DCE::ACL::handle->bind

See L<DCE::ACL-E<gt>bind>.

=item $aclh->num_acls

Returns the number of acls in the sec_acl_list_t structure.

 $num = $aclh->num_acls

=item $aclh->get_manager_types

Equivalent to the sec_acl_get_manager_types function.  
C<$manager_types> is a array reference.

 ($num_used, $num_types, $manager_types, $status) = 
    $aclh->get_manager_types();

If called in a scalar context, only the C<$manager_types> array reference is returned.

 $manager = $achl->get_manager_types->[0]; #first manager

 
=item $aclh->get_access

Equivalent to the sec_acl_get_access function.  

 ($permset, $status) = $aclh->get_access($manager);

=item $aclh->get_printstring 

Equivalent to the sec_acl_get_printstring function.  

C<$printstrings> is an array reference of hash references.

 ($chain, $mgr_info, $tokenize, $total, $num, $printstrings, $status) = 
    $aclh->get_printstring($manager); 

If called in a scalar context, only the C<$printstrings> reference is returned.

 $printstrings = $aclh->get_printstring($manager);

 foreach $str (@$printstrings) {
     $permstr .= 
	 ($str->{permissions} & $entry->perms) ?  
	     $str->{printstring} : "-";
 }


=item $aclh->test_access

Equivalent to the sec_acl_test_access function.   

 ($ok, $status) = $aclh->test_access($manager, $perms);


=item $aclh->replace

Equivalent to the sec_acl_replace function.   

 $status = $aclh->replace($manager, $aclh->type_object, $list);

=item $aclh->lookup

Equivalent to the sec_acl_lookup function.   
C<$list> is a reference to a sec_acl_list_t structure, blessed into the
I<DCE::ACL::list> class.  C<$type> is an optional argument which defaults
to C<DCE::ACL->type_object>.

 ($list, $status) = $aclh->lookup($manager, [$type]);

=item $aclh->new_list

This method does a lookup, deleting all entries and returns the empty list.
C<$type> is an optional argument which defaults to C<DCE::ACL->type_object>.

 ($list, $status) = $aclh->new_list($manager, [$type]);

=back

=head1 DCE::ACL::list methods

=over 4

=item $list->acls

Returns a list of all acls if no index argument is given, 
when called in a scalar context, only the first acl is returned.
Objects returned are references to sec_acl_t structures, blessed
into the I<DCE::ACL> class.

 $acl = $list->acls;

=back

=head1 DCE::ACL methods

=over 4

=item DCE::ACL->bind

Equivalent to the sec_acl_bind function.  
Returns a reference to the sec_acl_list_t structure bless into the
I<DCE::ACL::handle> class.  The optional argument C<$bind_to_entry> defaults to C<FALSE>.

 ($aclh, $status) = DCE::ACL->bind($object, [$bind_to_entry]);

=item DCE::ACL->type

When given an integer argument, returns the string representation.

 $str = DCE::ACL->type(0); #returns 'user_obj'

=item DCE::ACL->type_*

A method is provided foreach sec_acl_type_t type, returning an integer.

 $type = DCE::ACL->type_user;

=item $acl->num_entries

Returns the number of sec_acl_entry_t structures.

 $num = $acl->num_entries;

 
=item $acl->default_realm


Returns a hash reference with B<uuid> and B<name> keys.

 
 $name = $acl->default_realm->{name}; #/.../cell.foo.com


=item $acl->remove

Removes the specifed entry from the acl structure, where entry is a
reference to sec_acl_entry_t structure, blessed into the I<DCE::ACL::entry>
class.

 $status = $acl->remove($entry);

=item $acl->delete

Removes all entries from the $acl.
 
=item $acl->new_entry

Allocates memory needed for a new sec_acl_entry_t structure, returns a
reference to that structure blessed in to the I<DCE::ACL::entry> class.

 $entry = $acl->new_entry;
 
=item $acl->add

Adds a sec_acl_entry_t structure to a sec_acl_t structure.

 $status = $acl->add($entry);

=item $acl->entries

Returns references to sec_acl_entry_t structures blessed in to the 
I<DCE::ACL::entry> class.  If an integer argument is given, only that
entry will be returned, otherwise, a list of all entries will be returned.

 $entry = $acl->entries(0); #return the first entry

 foreach $entry ($acl->entries) { #return all entries
    ...

=back

=head1 DCE::ACL::entry methods

=over 4

=item $entry->compare

Compares two acl entries, returns true if they are the same, returns false
otherwise.

 $match = $entry1->compare($entry2);

=item $entry->perms

Returns the permission bits for the specified entry, setting the bits if
given an argument.

    $bits = $entry->perms;

    for (qw(perm_read perm_control perm_insert)) {
	$bits |= DCE::ACL->$_();
    }

    $e->perms($bits); 

=item $entry->entry_info

Returns a hash reference containing entry info, changing it if given an
argument.

    $uuid = $entry->entry_info->{id}{uuid};

    $entry->entry_info({
	entry_type => DCE::ACL->type_user,
	id => {
	    uuid => $uuid,
	},
    });

=back

=head1 AUTHOR

Doug MacEachern <dougm@osf.org>

=head1 SEE ALSO

perl(1), DCE::aclbase(3), DCE::Registry(3), DCE::UUID(3), DCE::Login(3), DCE::Status(3).

=cut

