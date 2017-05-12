# $Id: AuthzLDAP.pm,v 1.26 2005/05/09 16:36:06 cgilmore Exp $
#
# Author          : Jason Bodnar, Christian Gilmore
# Created On      : Apr 04 12:04:00 CDT 2000
# Status          : Functional
# 
# PURPOSE
#    LDAP Group Authentication
#
###############################################################################
#
# IBM Public License Version 1.0
#
# THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS IBM
# PUBLIC LICENSE ("AGREEMENT"). ANY USE, REPRODUCTION OR
# DISTRIBUTION OF THE PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF
# THIS AGREEMENT.
#
# 1. DEFINITIONS
#
# "Contribution" means:
#
#   a) in the case of International Business Machines Corporation
#   ("IBM"), the Original Program, and
#
#   b) in the case of each Contributor,
#
#   i) changes to the Program, and
#
#   ii) additions to the Program;
#
#   where such changes and/or additions to the Program originate from
#   and are distributed by that particular Contributor. A Contribution
#   'originates' from a Contributor if it was added to the Program by
#   such Contributor itself or anyone acting on such Contributor's
#   behalf. Contributions do not include additions to the Program
#   which: (i) are separate modules of software distributed in
#   conjunction with the Program under their own license agreement,
#   and (ii) are not derivative works of the Program.
#
# "Contributor" means IBM and any other entity that distributes the
# Program.
#
# "Licensed Patents " mean patent claims licensable by a Contributor
# which are necessarily infringed by the use or sale of its
# Contribution alone or when combined with the Program.
#
# "Original Program" means the original version of the software
# accompanying this Agreement as released by IBM, including source
# code, object code and documentation, if any.
#
# "Program" means the Original Program and Contributions.
#
# "Recipient" means anyone who receives the Program under this
# Agreement, including all Contributors.
#
# 2. GRANT OF RIGHTS
#
#   a) Subject to the terms of this Agreement, each Contributor hereby
#   grants Recipient a non-exclusive, worldwide, royalty-free
#   copyright license to reproduce, prepare derivative works of,
#   publicly display, publicly perform, distribute and sublicense the
#   Contribution of such Contributor, if any, and such derivative
#   works, in source code and object code form.
#
#   b) Subject to the terms of this Agreement, each Contributor hereby
#   grants Recipient a non-exclusive, worldwide, royalty-free patent
#   license under Licensed Patents to make, use, sell, offer to sell,
#   import and otherwise transfer the Contribution of such
#   Contributor, if any, in source code and object code form. This
#   patent license shall apply to the combination of the Contribution
#   and the Program if, at the time the Contribution is added by the
#   Contributor, such addition of the Contribution causes such
#   combination to be covered by the Licensed Patents. The patent
#   license shall not apply to any other combinations which include
#   the Contribution. No hardware per se is licensed hereunder.
#
#   c) Recipient understands that although each Contributor grants the
#   licenses to its Contributions set forth herein, no assurances are
#   provided by any Contributor that the Program does not infringe the
#   patent or other intellectual property rights of any other entity.
#   Each Contributor disclaims any liability to Recipient for claims
#   brought by any other entity based on infringement of intellectual
#   property rights or otherwise. As a condition to exercising the
#   rights and licenses granted hereunder, each Recipient hereby
#   assumes sole responsibility to secure any other intellectual
#   property rights needed, if any. For example, if a third party
#   patent license is required to allow Recipient to distribute the
#   Program, it is Recipient's responsibility to acquire that license
#   before distributing the Program.
#
#   d) Each Contributor represents that to its knowledge it has
#   sufficient copyright rights in its Contribution, if any, to grant
#   the copyright license set forth in this Agreement.
#
# 3. REQUIREMENTS
#
# A Contributor may choose to distribute the Program in object code
# form under its own license agreement, provided that:
#
#   a) it complies with the terms and conditions of this Agreement;
#
# and
#
#   b) its license agreement:
#
#   i) effectively disclaims on behalf of all Contributors all
#   warranties and conditions, express and implied, including
#   warranties or conditions of title and non-infringement, and
#   implied warranties or conditions of merchantability and fitness
#   for a particular purpose;
#
#   ii) effectively excludes on behalf of all Contributors all
#   liability for damages, including direct, indirect, special,
#   incidental and consequential damages, such as lost profits;
#   iii) states that any provisions which differ from this Agreement
#   are offered by that Contributor alone and not by any other party;
#   and
#
#   iv) states that source code for the Program is available from such
#   Contributor, and informs licensees how to obtain it in a
#   reasonable manner on or through a medium customarily used for
#   software exchange.
#
# When the Program is made available in source code form:
#
#   a) it must be made available under this Agreement; and
#
#   b) a copy of this Agreement must be included with each copy of the
#   Program.
#
# Each Contributor must include the following in a conspicuous
# location in the Program:
#
#   Copyright © {date here}, International Business Machines
#   Corporation and others. All Rights Reserved.
#
# In addition, each Contributor must identify itself as the originator
# of its Contribution, if any, in a manner that reasonably allows
# subsequent Recipients to identify the originator of the
# Contribution.
#
# 4. COMMERCIAL DISTRIBUTION
#
# Commercial distributors of software may accept certain
# responsibilities with respect to end users, business partners and
# the like. While this license is intended to facilitate the
# commercial use of the Program, the Contributor who includes the
# Program in a commercial product offering should do so in a manner
# which does not create potential liability for other Contributors.
# Therefore, if a Contributor includes the Program in a commercial
# product offering, such Contributor ("Commercial Contributor") hereby
# agrees to defend and indemnify every other Contributor ("Indemnified
# Contributor") against any losses, damages and costs (collectively
# "Losses") arising from claims, lawsuits and other legal actions
# brought by a third party against the Indemnified Contributor to the
# extent caused by the acts or omissions of such Commercial
# Contributor in connection with its distribution of the Program in a
# commercial product offering. The obligations in this section do not
# apply to any claims or Losses relating to any actual or alleged
# intellectual property infringement. In order to qualify, an
# Indemnified Contributor must: a) promptly notify the Commercial
# Contributor in writing of such claim, and b) allow the Commercial
# Contributor to control, and cooperate with the Commercial
# Contributor in, the defense and any related settlement negotiations.
# The Indemnified Contributor may participate in any such claim at its
# own expense.
#
# For example, a Contributor might include the Program in a commercial
# product offering, Product X. That Contributor is then a Commercial
# Contributor. If that Commercial Contributor then makes performance
# claims, or offers warranties related to Product X, those performance
# claims and warranties are such Commercial Contributor's
# responsibility alone. Under this section, the Commercial Contributor
# would have to defend claims against the other Contributors related
# to those performance claims and warranties, and if a court requires
# any other Contributor to pay any damages as a result, the Commercial
# Contributor must pay those damages.
#
# 5. NO WARRANTY
#
# EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE PROGRAM IS
# PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION,
# ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT,
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Each Recipient
# is solely responsible for determining the appropriateness of using
# and distributing the Program and assumes all risks associated with
# its exercise of rights under this Agreement, including but not
# limited to the risks and costs of program errors, compliance with
# applicable laws, damage to or loss of data, programs or equipment,
# and unavailability or interruption of operations.
#
# 6. DISCLAIMER OF LIABILITY
#
# EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER RECIPIENT
# NOR ANY CONTRIBUTORS SHALL HAVE ANY LIABILITY FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING WITHOUT LIMITATION LOST PROFITS), HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OR DISTRIBUTION OF THE PROGRAM OR THE EXERCISE OF ANY RIGHTS
# GRANTED HEREUNDER, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGES.
#
# 7. GENERAL
#
# If any provision of this Agreement is invalid or unenforceable under
# applicable law, it shall not affect the validity or enforceability
# of the remainder of the terms of this Agreement, and without further
# action by the parties hereto, such provision shall be reformed to
# the minimum extent necessary to make such provision valid and
# enforceable.
#
# If Recipient institutes patent litigation against a Contributor with
# respect to a patent applicable to software (including a cross-claim
# or counterclaim in a lawsuit), then any patent licenses granted by
# that Contributor to such Recipient under this Agreement shall
# terminate as of the date such litigation is filed. In addition, If
# Recipient institutes patent litigation against any entity (including
# a cross-claim or counterclaim in a lawsuit) alleging that the
# Program itself (excluding combinations of the Program with other
# software or hardware) infringes such Recipient's patent(s), then
# such Recipient's rights granted under Section 2(b) shall terminate
# as of the date such litigation is filed.
#
# All Recipient's rights under this Agreement shall terminate if it
# fails to comply with any of the material terms or conditions of this
# Agreement and does not cure such failure in a reasonable period of
# time after becoming aware of such noncompliance. If all Recipient's
# rights under this Agreement terminate, Recipient agrees to cease use
# and distribution of the Program as soon as reasonably practicable.
# However, Recipient's obligations under this Agreement and any
# licenses granted by Recipient relating to the Program shall continue
# and survive.
#
# IBM may publish new versions (including revisions) of this Agreement
# from time to time. Each new version of the Agreement will be given a
# distinguishing version number. The Program (including Contributions)
# may always be distributed subject to the version of the Agreement
# under which it was received. In addition, after a new version of the
# Agreement is published, Contributor may elect to distribute the
# Program (including its Contributions) under the new version. No one
# other than IBM has the right to modify this Agreement. Except as
# expressly stated in Sections 2(a) and 2(b) above, Recipient receives
# no rights or licenses to the intellectual property of any
# Contributor under this Agreement, whether expressly, by implication,
# estoppel or otherwise. All rights in the Program not expressly
# granted under this Agreement are reserved.
#
# This Agreement is governed by the laws of the State of New York and
# the intellectual property laws of the United States of America. No
# party to this Agreement will bring a legal action under this
# Agreement more than one year after the cause of action arose. Each
# party waives its rights to a jury trial in any resulting litigation.
#
###############################################################################


# Package name
package Apache::AuthzLDAP;


# Required libraries
use strict;
use mod_perl ();
use Apache::Constants ':common';
use Apache::Log ();
use Net::LDAP qw(:all);
use Text::ParseWords ();


# Global constants
use constant REQUIRE_OPTS => { 'inagroup'     => 1,
			       'inmanygroups' => 2,
			       'inallgroups'  => 3 };


# Global variables
$Apache::AuthzLDAP::VERSION = '1.11';


###############################################################################
###############################################################################
# check_group: check user membership in group
###############################################################################
###############################################################################
sub check_group {
  my ($r, $ld, $basedn, $groupattrtype, $memberattrtype,
      $userinfo, $groups, $nestedattrtype, $nested_groups,
      $requirement, $recursion_depth) = @_;
  my ($group, $authgroups, $member) = undef;
  my $foundgroups = '';
  my @grouplist = ();

  $r->log->debug("check_group: Recursion depth is $recursion_depth");
  $r->log->debug("check_group: Parsing on $groups");
  @grouplist = Text::ParseWords::parse_line('\s+', 0, $groups);

  foreach $group (@grouplist) {
    # Look up the group
    my $filter = qq(($groupattrtype=$group));
    $r->log->debug("check_group: Iterating over group $group");
    $r->log->debug("check_group: Using filter: $filter");
    $r->log->debug("check_group: Using base: $basedn");
    # Want to just validate group's existence, not get its contents
    my $msg = $ld->search(base => $basedn, filter => $filter,
			  attrs => [ $nestedattrtype ]);
    unless ($msg->code == LDAP_SUCCESS) {
      $r->note_basic_auth_failure;
      $r->log_reason("user $userinfo: Could not search for $group: " .
		     $msg->code . " " . $msg->error, $r->uri);
      next unless $requirement == 3;
      return AUTH_REQUIRED;
    }

    # Did we get any entries?
    unless ($msg->count) {
      $r->log->debug("check_group: user $userinfo: could not find $group");
      return AUTH_REQUIRED if $requirement == 3;
      next;
    }

    # Check the group
    my $entry = $msg->first_entry; # Only want one
    my $dn = $entry->dn;
    $r->log->debug("check_group: Checking group $dn for $userinfo");
    $msg = $ld->compare($dn, attr => $memberattrtype, value => $userinfo);

    if ($msg->code == LDAP_COMPARE_TRUE) {
      return (OK, $group) unless $recursion_depth == 1;
      if ($requirement == 1) {
	$r->log->debug("LDAP compare inAGroup user found; returning");
	return (OK, "\"$group\"");
      } elsif ($foundgroups eq '') {
	$r->log->debug("LDAP compare inManyGroups or inAllGroups user found; appending");
	$foundgroups = "\"$group\"";
      } else {
	$r->log->debug("LDAP compare inManyGroups or inAllGroups user found; appending");
	$foundgroups .= " \"$group\"";
      }
      next;
    }

    # Return undef if nested groups is not set
    $r->log->debug("check_group: Could not find $userinfo in $group");
    next unless $nested_groups =~ /on/i;

    # If we did not find the person in the group let's check the
    # group's members
    foreach $member ($entry->get($nestedattrtype)) {
      $r->log->debug("check_group: Checking $member");
      # We just want the group's name
      if ($member =~ /^[^=]+="([^"]+)",/) {
	$member = $1;
	$r->log->debug("check_group: Setting quoted $member");
      } elsif ($member =~ /^[^=]+=([^,]+),/) {
	$member = $1;
	$r->log->debug("check_group: Examining escaped $member");
	$member =~ s/\\(.)/$1/g;
	$r->log->debug("check_group: Setting escaped $member");
      }

      $r->log->debug("check_group: Member now $member");
      my ($result, $child_group) = check_group($r, $ld, $basedn, $groupattrtype,
					       $memberattrtype, $userinfo,
					       "\"$member\"", $nestedattrtype,
					       $nested_groups, $requirement,
					       $recursion_depth + 1);
      if ($recursion_depth != 1 && $result == OK) {
	$r->log->debug("Recursion of $recursion_depth; returning OK");
	return (OK, $group);
      } elsif ($result == OK) {
	if ($requirement == 1) {
	  $r->log->debug("Requirement inAGroup; returning");
	  return (OK, "\"$group\"");
	} elsif ($foundgroups eq '') {
	  $r->log->debug("Requirement inManyGroups or inAllGroups; appending");
	  $foundgroups = "\"$group\"";
	} else {
	  $r->log->debug("Requirement inManyGroups or inAllGroups; appending");
	  $foundgroups .= " \"$group\"";
	}
	next;
      }
    }
    $r->log->debug("Requirement inAllGroups failed; returning"),
      return AUTH_REQUIRED if $requirement == 3 &&
	!($entry->exists($nestedattrtype));
  }

  # This case happens when inManyGroups is required
  $r->log->debug("inManyGroups success"),
    return(OK, $foundgroups) if $foundgroups ne '';

  # We've fallen through without finding the user in the group
  $r->log_reason("Could not find $userinfo in $groups", $r->uri);
  return AUTH_REQUIRED;
}


###############################################################################
###############################################################################
# handler: hook into Apache/mod_perl API
###############################################################################
###############################################################################
sub handler {
  my $r = shift;
  return OK unless $r->is_initial_req; # only the first internal request
  my $requires = $r->requires;
  return OK unless $requires;

  my $username = $r->connection->user;

  # The required patch was not introduced in 1.26. It is no longer
  # promised to be included in any timeframe. Commenting out.
  # if ($mod_perl::VERSION < 1.26) {
    # I shouldn't need to use the below lines as this module
    # should never be called if there was a cache hit.  Since
    # set_handlers() doesn't work properly until 1.26 (according
    # to Doug MacEachern) I have to work around it by cobbling
    # together cheat sheets for the previous and subsequent
    # handlers in this phase. I get the willies about the
    # security implications in a general environment where you
    # might be using someone else's handlers upstream or
    # downstream...
  my $group_sent = $r->subprocess_env("REMOTE_GROUP") ||
    $r->headers_in->{'REMOTE_GROUP'};
  my $cache_result = $r->notes('AuthzCache');
  if ($group_sent && $cache_result eq 'hit') {
    $r->log->debug("handler: upstream cache hit for ",
		   "user=$username, group=$group_sent");
    return OK;
  # }
  }

  # Clear for paranoid security precautions
  $r->subprocess_env(REMOTE_GROUP => undef);
  undef($r->headers_in->{'REMOTE_GROUP'});

  my $basedn = $r->dir_config('AuthzBaseDN');
  my $groupattrtype = $r->dir_config('AuthzGroupAttrType') || 'cn';
  my $authzldapserver = $r->dir_config('AuthzLDAPServer') || "localhost";
  my $authzldapport = $r->dir_config('AuthzLDAPPort') || 389;
  my $authenldapserver = $r->dir_config('AuthenLDAPServer') ||
    $r->dir_config('AuthzLDAPServer') || "localhost";
  my $authenldapport = $r->dir_config('AuthenLDAPPort') ||
    $r->dir_config('AuthzLDAPPort') || 389;
  my $memberattrtype = $r->dir_config('AuthzMemberAttrType') || 'member';
  my $memberattrvalue = $r->dir_config('AuthzMemberAttrValue') || 'cn';
  my $nestedattrtype = $r->dir_config('AuthzNestedAttrType') || 'member';
  my $nested_groups = $r->dir_config('AuthzNestedGroups');
  my $requirement = $r->dir_config('AuthzRequire') || 'inAGroup';
  my $uidattrtype = $r->dir_config('AuthzUidAttrType') || 'uid';
  my $userbasedn = $r->dir_config('AuthenBaseDN');

  $requirement = REQUIRE_OPTS->{lc($requirement)} || 1;
  $r->log->debug(join ", ", "AuthzBaseDN=$basedn",
		 "GroupAttrType=$groupattrtype",
		 "LDAPServer=$authzldapserver",
		 "MemberAttrType=$memberattrtype",
		 "MemberAttrValue=$memberattrvalue",
		 "NestedAttrType=$nestedattrtype",
		 "NestedGroups=$nested_groups",
		 "Requirement=$requirement",
		 "UserBaseDN=$userbasedn");

  for my $req (@$requires) {
    my ($require, $rest) = split /\s+/, $req->{requirement}, 2;

    if ($require eq "user") { return OK
				if grep $username eq $_, split /\s+/, $rest}
    elsif ($require eq "valid-user") { return OK }
    elsif ($require eq 'group') {
      my $ld = undef;
      # Connect to the server
      unless ($ld = new Net::LDAP($authenldapserver,port => $authenldapport)) {
	$r->note_basic_auth_failure;
	$r->log_reason("user $username: Authen LDAP Connection Failed",$r->uri);
	return SERVER_ERROR;
      }

      # Bind anonymously
      my $msg = $ld->bind;
      unless ($msg->code == LDAP_SUCCESS) {
	$r->note_basic_auth_failure;
	$r->log_reason("user $username: Authen LDAP Initial Bind Failed: " .
		       $msg->code . " " . $msg->error, $r->uri);
	return SERVER_ERROR;
      }

      # Get user DN
      $msg = $ld->search(base   => $userbasedn,
			 filter => qq($uidattrtype=$username));
      unless ($msg->code == LDAP_SUCCESS) {
	$r->note_basic_auth_failure;
	$r->log_reason("LDAP read failure " .
		       $msg->code . " " . $msg->error, $r->uri);
	return SERVER_ERROR;
      }
      unless ($msg->count) {
	$r->note_basic_auth_failure;
	$r->log_reason("user ($uidattrtype) $username doesn't " .
		       "exist in LDAP " .
		       $msg->code . " " . $msg->error . $r->uri);
	return AUTH_REQUIRED;
      }

      my $userinfo = undef;
      if ($memberattrvalue eq 'dn') {
	$userinfo = $msg->first_entry->dn;
      } else {
	$userinfo = ($msg->first_entry->get($memberattrvalue))[0];	
      }
      $r->log->debug("handler: Userinfo is $userinfo ($memberattrvalue)");

      $ld->unbind();
      $ld = undef;
      # Connect to the server
      unless ($ld = new Net::LDAP($authzldapserver,port => $authzldapport)) {
	$r->note_basic_auth_failure;
	$r->log_reason("user $username: Authz LDAP Connection Failed",$r->uri);
	return SERVER_ERROR;
      }

      # Bind anonymously
      $msg = $ld->bind;
      unless ($msg->code == LDAP_SUCCESS) {
	$r->note_basic_auth_failure;
	$r->log_reason("user $username: Authz LDAP Initial Bind Failed: " .
		       $msg->code . " " . $msg->error, $r->uri);
	return SERVER_ERROR;
      }

      # Compare the username
      my ($result, $group) = check_group($r, $ld, $basedn, $groupattrtype,
					 $memberattrtype, $userinfo, $rest,
					 $nestedattrtype, $nested_groups,
					 $requirement, 1);
      return $result unless $result == OK;

      # Everything's A-OK
      $r->log->debug("Setting REMOTE_GROUP to $group");
      $r->subprocess_env(REMOTE_GROUP => $group);
      $r->headers_in->{'REMOTE_GROUP'} = $group;
      return OK;
    }
  }
}

1;

__END__

# Documentation - try 'pod2text AuthzLDAP'

=head1 NAME

Apache::AuthzLDAP - mod_perl LDAP Authorization Module

=head1 SYNOPSIS

 <Directory /foo/bar>
 # Authorization Realm and Type (only Basic supported)
 AuthName "Foo Bar Authentication"
 AuthType Basic

 # Any of the following variables can be set.
 # Defaults are listed to the right.
 PerlSetVar AuthenBaseDN         o=Foo,c=Bar       # Default: Empty String ("")
 PerlSetVar AuthzBaseDN          o=My Company      # Default: none
 PerlSetVar AuthzGroupAttrType   gid               # Default: cn
 PerlSetVar AuthzLDAPServer      ldap.foo.com      # Default: localhost
 PerlSetVar AuthzLDAPPort        389               # Default: 389
 PerlSetVar AuthzMemberAttrType  uniquemember      # Default: member
 PerlSetVar AuthzMemberAttrValue dn                # Default: cn
 PerlSetVar AuthzNestedAttrType  uniquegroup       # Default: member
 PerlSetVar AuthzNestedGroups    on                # Default: off
 PerlSetVar AuthzRequire         inAllGroups       # Default: inAGroup
 PerlSetVar AuthzUidattrType     userid            # Default: uid

 PerlAuthzHandler Apache::AuthzLDAP

 require group "My Group" GroupA "Group B"         # Authorize user against
                                                   # multiple groups
 </Directory>

=head1 DESCRIPTION

B<Apache::AuthzLDAP> is designed to work with mod_perl
and Net::LDAP. This module authorizes a user against an LDAP
backend. It can be combined with Apache::AuthenLDAP to
provide LDAP authentication as well.

B<Apache::AuthzLDAP> sets both a request header and an environment
variable called REMOTE_GROUP which contains a space-separated,
double-quoted list of groups to which the requestor is authorized.

=head1 CONFIGURATION OPTIONS

The following variables can be defined within the configuration
of Directory, Location, or Files blocks or within .htaccess
files.

=over 4

=item B<AuthenBaseDN>

The base distinguished name with which to query LDAP for purposes
of authentication. By default, the AuthenBaseDN is blank.

=back

=over 4

=item B<AuthzBaseDN>

The base distinguished name with which to query LDAP for purposes
of authorization. By default, the AuthzBaseDN is blank.

=back

=over 4

=item B<AuthzGroupAttrType>

The attribute type name that contains the group's
identification. By default, AuthzGroupAttrType is set to cn.

=back

=over 4

=item B<AuthzLDAPServer>

The hostname for the LDAP server to query. By default,
AuthzLDAPServer is set to localhost.

=back

=over 4

=item B<AuthzLDAPPort>

The port on which the LDAP server is listening. By default,
AuthzLDAPPort is set to 389.

=back

=over 4

=item B<AuthzMemberAttrType>

The attribute type name that contains the group member's
identification. By default, AuthzMemberAttrType is set to member.

=back

=over 4

=item B<AuthzMemberAttrValue>

The attribute value contained within the AuthzMemberAttrType
above. By default, AuthzMemberAttrValue is set to cn.

=back

=over 4

=item B<AuthzNestedAttrType>

The attribute type name that contains the group nested member's
identification. By default, AuthzNestedAttrType is set to member.

=back

=over 4

=item B<AuthzNestedGroups>

When the AuthzNestedGroups value is on, a recursive group search
occurs until the user is found in a group or the deepest group's
member list does not contain any groups. By default,
AuthzNestedGroups is set to off.

=back

=over 4

=item B<AuthzRequire>

AuthzRequire accepts three values: inAGroup (user must be found in
just one group), inManyGroups (user must be found in at least one
group), inAllGroups (user must be found in all groups).

=back

=over 4

=item B<AuthzUidAttrType>

The attribute type name that contains the user's
identification. By default, AuthzUidAttrType is set to uid.

=back

=head1 NOTES

This module has hooks built into it to handle Apache::AuthzCache
version 0.02 and higher passing notes to avoid bugs in the
set_handlers() method in mod_perl versions 1.2x.

=head1 AVAILABILITY

This module is available via CPAN at
http://www.cpan.org/modules/by-authors/id/C/CG/CGILMORE/.

=head1 AUTHORS

Jason Bodnar,
Christian Gilmore <cag@us.ibm.com>

=head1 SEE ALSO

httpd(8), ldap(3), mod_perl(1), slapd(8C)

=head1 COPYRIGHT

Copyright (C) 2004, International Business Machines Corporation
and others. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of the IBM Public License.

=cut

###############################################################################
###############################################################################
# $Log: AuthzLDAP.pm,v $
# Revision 1.26  2005/05/09 16:36:06  cgilmore
# Updated to version 1.11 based upon Andrew's fix in December.
#
# Revision 1.25  2004/12/06 17:18:40  anyoung
# There was a period where there should have been a comma.
#
# Revision 1.24  2004/12/01 21:44:38  cgilmore
# Now handle LDAP v2 and v3 character escaping methods within distinguished names to better support nested group searches.
#
# Revision 1.23  2003/06/18 16:28:24  cgilmore
# see ChangeLog
#
# Revision 1.22  2003/02/03 23:09:12  cgilmore
# *** empty log message ***
#
# Revision 1.21  2003/02/03 23:08:10  cgilmore
# see ChangeLog
#
# Revision 1.20  2002/04/15 03:24:30  cgilmore
# changed return value for caching purposes to help RT #980
#
# Revision 1.19  2002/03/04 22:53:00  cgilmore
# updated to handle BlueGroups
#
# Revision 1.18  2001/07/17 20:02:49  cgilmore
# updated documentation
#
# Revision 1.17  2001/07/17 20:01:22  cgilmore
# updated documentation
#
# Revision 1.16  2001/07/12 14:18:52  cgilmore
# see ChangeLog
#
# Revision 1.15  2001/05/27 20:47:41  cgilmore
# Added handling for AuthenLDAPServer to query user information
#
# Revision 1.14  2001/05/27 20:27:15  cgilmore
# removed redeclaration of $msg in same scope
#
# Revision 1.13  2001/05/27 20:22:51  cgilmore
# updated docs to reflect new variable names
#
# Revision 1.12  2001/05/27 20:01:12  cgilmore
# see ChangeLog
#
# Revision 1.11  2001/01/08 17:23:47  cgilmore
# fixed nested group bug and better handled pre-1.26 conditions
#
# Revision 1.10  2000/09/26 18:51:21  cgilmore
# updated to Apache from Tivoli namespace and updated pod.
#
# Revision 1.9  2000/08/26 16:41:49  cgilmore
# corrected fetch bug with userinfo. cleaned up debug statements.
#
# Revision 1.8  2000/08/26 15:34:32  cgilmore
# re-designed. See pod.
#
# Revision 1.7  2000/08/26 15:26:46  cgilmore
# re-fixed same bug
#
# Revision 1.6  2000/08/21 14:15:49  cgilmore
# fixed bug that improperly dealt with end-of-line non-quoted groups
#
# Revision 1.5  2000/07/18 15:37:11  cgilmore
# added userbasedn and adding $groups to empty @groups
#
# Revision 1.4  2000/07/17 15:37:06  cgilmore
# added handling of no hits for user in LDAP
#
# Revision 1.3  2000/07/12 18:32:07  cgilmore
# Finally found a hack (using r->notes) around bugs in set_handlers()
# and lookup_uri(). See files for more.
#
# Revision 1.2  2000/06/01 16:18:54  cgilmore
# added Log message
#
###############################################################################
###############################################################################
