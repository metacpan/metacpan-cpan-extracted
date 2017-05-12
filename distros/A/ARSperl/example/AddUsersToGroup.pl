#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/AddUsersToGroup.pl,v 1.5 2009/03/31 13:34:32 mbeijen Exp $
#
# NAME
#   AddUsersToGroup server user password group user1 [user2] ...
#
# DESCRIPTION
#   add given users to specified group
#
# AUTHOR
#   jeff murphy
#
# $Log: AddUsersToGroup.pl,v $
# Revision 1.5  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.4  2007/08/04 15:20:04  mbeijen
# Adjusted the code for current ARSperl version, added use strict; and added comments.
#
# Revision 1.3  2003/03/28 05:51:56  jcmurphy
# more 5.x editsgv
#
# Revision 1.2  1998/09/14 20:48:59  jcmurphy
# changed usage, comments. fixed bug.
#
#

use ARS;
use strict;
use warnings;

die "usage: AddUserToGroup server username password group user1 [user2] ...\n"
  if ( $#ARGV < 4 );

my ( $server, $user, $pass, $group, @users ) =
  ( shift, shift, shift, shift, @ARGV );

#Logging in to the server
( my $ctrl = ars_Login( $server, $user, $pass ) )
  || die "ars_Login: $ars_errstr";

# Retrieve a list of fieds in a hash for the User and Group forms, otherwise we have to use
# field ID's if we want to extract the values from the return strings.

( my %userfields = ars_GetFieldTable( $ctrl, "User" ) )
  || die "ars_GetFieldTable(User): $ars_errstr";

( my %groupfields = ars_GetFieldTable( $ctrl, "Group" ) )
  || die "ars_GetFieldTable(Group): $ars_errstr";

# we will retrieve the Group ID for the group specified in $group
# first create a qualifier using ars_LoadQualifier
( my $groupqualifier =
      ars_LoadQualifier( $ctrl, "Group", "'105' = \"$group\"" ) )
  || die "ars_LoadQualifier(Group): $ars_errstr";

# fetch the Entry ID for this group by using GetListEntry with the group we just specified, if there is none, die.
my @groupentry = ars_GetListEntry( $ctrl, "Group", $groupqualifier, 0, 0 )
  || die "No such group \"$group\" ($ars_errstr)\n";

# Fetch the values for this record:
( my %groupvalues = ars_GetEntry( $ctrl, "Group", $groupentry[0] ) )
  || die "ars_GetEntry(Group): $ars_errstr";

# We are only interested in the field marked Group ID:
my $group_id = $groupvalues{ $groupfields{'Group ID'} };

# This loop will process all users one by one, see if they are already a member of the group specified,
# if neccesary we add them to the group by changing the Group List and writing it back.
foreach (@users) {
    print "Adding $_ to $group .. \n";

    # Create a qualifier to retrieve the Entry ID for this user
    ( my $userqualifier =
          ars_LoadQualifier( $ctrl, "User", "'Login Name' = \"$_\"" ) )
      || die "ars_LoadQualifier: $ars_errstr";

# Fetch the EID for this user; if there is no such user, say so and continue with next user
# ars_GetListEntry provides a list with Entry-Id, Short description pairs
# In this case only one pair. That means $userentry[0] will contain the actual Entry ID.
    my @userentry = ars_GetListEntry( $ctrl, "User", $userqualifier, 0, 0, );

    # If there is no record for this user, say so and conitue with the next one
    if ( !@userentry ) { print "No user $_\n"; next; }

# Get the value of the Group List field. Syntax = ars_GetEntry(ctrl, schema, eid [field ID...n])
# so in this case we only get the value returned for one field ID, the Group List
# If you do not specify field ID's, you will get all values for the whole entry.
    my %uservalues =
      ars_GetEntry( $ctrl, "User", $userentry[0], $userfields{'Group List'} );

    # Get the field values for this entry
    # set $currentgrouplist to the contents of the Group List field
    my $currentgrouplist = $uservalues{ $userfields{'Group List'} };

#if the Group List already contains the group, say so and continue with  next user
    if (
        (
               ( $currentgrouplist =~ /^$group_id;/ )
            || ( $currentgrouplist =~ /;$group_id;/ )
        )
      )
    {
        print "\talready a member of $group\n";
        next;
    }

# add the new group to the group list, or if the group list is empty just let the new list contain only the new group.
    my $newgrouplist;
    if ($currentgrouplist) {
        print "\tcurrent group list: $currentgrouplist\n";
        $newgrouplist = $currentgrouplist . "$group_id;";
    }
    else {
        print "\tno groups were assigned to this user.\n";
        $newgrouplist = "$group_id;";
    }

    print "\tnew group list    : $newgrouplist\n";

    # write the entry back using SetEntry
    ars_SetEntry( $ctrl, "User", $userentry[0], 0, $userfields{'Group List'},
        $newgrouplist )
      || die "ars_SetEntry(User): $ars_errstr";

}

# and of course log off nicely.
ars_Logoff($ctrl);

exit 0;
