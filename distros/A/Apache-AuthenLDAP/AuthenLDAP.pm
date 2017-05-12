# $Id: AuthenLDAP.pm,v 1.14 2003/06/23 18:38:59 cgilmore Exp $
#
# Author          : Jason Bodnar, Christian Gilmore
# Created On      : Dec 08 12:04:00 CDT 1999
# Status          : Functional
#
# PURPOSE
#    LDAP User Authentication
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
package Apache::AuthenLDAP;


# Required packages
use strict;
use Apache::Constants qw(:common);
use Apache::Log       qw();
use Date::Calc        qw(Date_to_Days Today);
use Net::LDAP         qw(:all);


# Global variables
$Apache::AuthenLDAP::VERSION = '1.00';


###############################################################################
###############################################################################
# handler: hook into Apache/mod_perl API
###############################################################################
###############################################################################
sub handler {
  my $r = shift;
  return OK unless $r->is_initial_req; # only the first internal request
  my ($res, $sent_pwd) = $r->get_basic_auth_pw;
  return $res if $res;

  my $name = $r->connection->user;
  unless ($name) {
    $r->note_basic_auth_failure;
    $r->log_reason("no username supplied", $r->uri);
    return AUTH_REQUIRED;
  }

  my $cache_result = $r->notes('AuthenCache');
  if ($cache_result eq 'hit') {
    $r->log->debug("handler: upstream cache hit for username=$name");
    return OK;
  }

  my $basedn = $r->dir_config('AuthenBaseDN') || '';
  my $ldapserver = $r->dir_config('AuthenLDAPServer') || "localhost";
  my $ldapport = $r->dir_config('AuthenLDAPPort') || 389;
  my $uidattrtype = $r->dir_config('AuthenUidAttrType') || "uid";

  my $expire = lc($r->dir_config('AuthenExpire')) || 'false';
  my $exp_attrtype = $r->dir_config('AuthenExpireAttrType') ||
    'passwordIsExpired';
  my $exp_lastmodattrtype =
    $r->dir_config('AuthenExpireLastModAttrType') ||
      'passwordModifyTimestamp';
  my $exp_time = $r->dir_config('AuthenExpireTime') ||
    186;
  my $exp_redirect = $r->dir_config('AuthenExpireRedirect') || '';

  $r->log->debug("handler: ",
		 "AuthenBaseDN - $basedn; LDAPServer - $ldapserver; ",
		 "LDAPPort - $ldapport; UiaDttrType - $uidattrtype; ",
		 "Expire - $expire; ExireAttrType - $exp_attrtype; ",
		 "ExpireLastModAttrType - $exp_lastmodattrtype; ",
		 "ExpireTime - $exp_time; ExpireRedirect - $exp_redirect");

  if ($sent_pwd eq "") {
    $r->note_basic_auth_failure;
    $r->log_reason("user $name: no password supplied", $r->uri);
    return AUTH_REQUIRED;
  }

  # Connect to the server
  my $ld;
  unless ($ld = new Net::LDAP($ldapserver, port => $ldapport)) {
    $r->note_basic_auth_failure;
    $r->log_reason("user $name: LDAP Connection Failed", $r->uri);
    return SERVER_ERROR;
  }

  # Bind anonymously
  my $msg = $ld->bind;
  unless ($msg->code == LDAP_SUCCESS) {
    $r->note_basic_auth_failure;
    $r->log_reason("user $name: LDAP Initial Bind Failed: " . $msg->code .
		   " " . $msg->error, $r->uri);
    return SERVER_ERROR;
  }

  # Create the filter and search
  my $filter = "($uidattrtype=$name)";
  $r->log->debug("handler: Using filter: $filter");
  $msg = $ld->search(base => $basedn, filter => $filter);
  unless ($msg->code == LDAP_SUCCESS) {
    $r->note_basic_auth_failure;
    $r->log_reason("user $name: ldap search operation failed: " .
		    $msg->code . " " . $msg->error, $r->uri);
    return SERVER_ERROR;
  }

  # Did we receive any entries
  unless ($msg->count) {
    $r->note_basic_auth_failure;
    $r->log_reason("user $name: username not found",$r->uri);
    return AUTH_REQUIRED;
  }

  # Only want the first if we've received more than one
  my $entry = $msg->first_entry;
  my $dn = $entry->dn;

  # Bind as the user we're authenticating
  $msg = $ld->bind($dn, password => $sent_pwd);
  unless ($msg->code == LDAP_SUCCESS) {
    $r->note_basic_auth_failure;
    $r->log_reason("user $name: password mismatch", $r->uri);
    return AUTH_REQUIRED;
  }

  $ld->unbind;

  if ($expire eq 'true') {
    # Is the password set to expired in LDAP?
    if (($entry->get($exp_attrtype))[0] eq 'true') {
      $r->log->debug("handler: password flag expired");
      $r->custom_response(FORBIDDEN, "$exp_redirect");
      return FORBIDDEN;
    }

    # Has the password passed the age limit?
    my ($modyear, $modmonth, $modday) = 
      (($entry->get($exp_lastmodattrtype))[0] =~ /(\d{4})(\d{2})(\d{2})/);
    my ($year, $month, $day) = Today([time]);
    if (Date_to_Days($year, $month, $day) -
	Date_to_Days($modyear, $modmonth, $modday) > $exp_time) {
      $r->log->debug("handler: password age expired");
      $r->custom_response(FORBIDDEN, "$exp_redirect");
      return FORBIDDEN;
    }
  }

  # Everything's A-OK
  return OK;
}

1;

__END__

# Documentation - try 'pod2text AuthenLDAP'

=head1 NAME

Apache::AuthenLDAP - mod_perl LDAP Authentication Module

=head1 SYNOPSIS

 <Directory /foo/bar>
 # Authentication Realm and Type (only Basic supported)
 AuthName "Foo Bar Authentication"
 AuthType Basic

 # Any of the following variables can be set.
 # Defaults are listed to the right.
 PerlSetVar AuthenBaseDN      o=Foo,c=Bar  # Default: Empty String ("")
 PerlSetVar AuthenLDAPServer  ldap.foo.com # Default: localhost
 PerlSetVar AuthenLDAPPort    389          # Default: 389 (standard LDAP port)
 PerlSetVar AuthenUidattrType userid       # Default: uid

 PerlAuthenHandler Apache::AuthenLDAP

 require valid-user                        # Any Valid LDAP User
                                           # Matching Attribute and Value
 </Directory>

=head1 DESCRIPTION

B<Apache::AuthenLDAP> is designed to work with mod_perl and
Net::LDAP. This module authenticates a user against an LDAP
backend. It can be combined with Apache::AuthzLDAP to provide
LDAP authorization as well.

=head1 CONFIGURATION OPTIONS

The following variables can be defined within the configuration
of Directory, Location, or Files blocks or within .htaccess
files.

=over 4

=item B<AuthenBaseDN>

The base distinguished name with which to query LDAP. By default,
the AuthenBaseDN is empty.

=back

=over 4

=item B<AuthenLDAPServer>

The hostname for the LDAP server to query. By default,
AuthenLDAPServer is set to localhost.

=back

=over 4

=item B<AuthenLDAPPort>

The port on which the LDAP server is listening. By default,
AuthenLDAPPort is set to 389.

=back

=over 4

=item B<AuthenExpire>

Password expiration enablement. By default, AuthenExpire is set to
false.

=back

=over 4

=item B<AuthenExpireAttrType>

The attribute type name that contains whether or not the password is
expired. By default, AuthenExpireAttrType is passwordIsExpired.

=back

=over 4

=item B<AuthenExpireLastModAttrType>

The attribute type name that contains the password last modified
timestamp in YYYYMMDD format.  By default AuthenExpireLastModAttrType
is set to passwordModifyTimestamp.

=back

=over 4

=item B<AuthenExpireTime>

The time in days at which a password expires. By default,
AuthenExpireTime is set to 186.

=back

=over 4

=item B<AuthenExpireRedirect>

The location to which you wish to redirect users whose passwords are
expired. If this value is left blank, the server will respond with a
401 error.

=back

=head1 NOTES

This module has hooks built into it to handle Apache::AuthenCache
version 0.04 and higher passing notes to avoid bugs in the
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

Copyright (C) 2003 International Business Machines Corporation and
others. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of the IBM Public License.

=cut

###############################################################################
###############################################################################
# $Log: AuthenLDAP.pm,v $
# Revision 1.14  2003/06/23 18:38:59  cgilmore
# see ChangeLog
#
# Revision 1.13  2003/06/23 18:26:18  cgilmore
# see ChangeLog
#
# Revision 1.12  2002/03/07 22:03:23  cgilmore
# see ChangeLog
#
# Revision 1.11  2001/07/17 19:59:04  cgilmore
# updated documentation
#
# Revision 1.10  2001/07/12 14:14:15  cgilmore
# See ChangeLog
#
# Revision 1.9  2001/07/12 14:06:35  cgilmore
# see ChangeLog
#
# Revision 1.8  2001/05/27 19:38:24  cgilmore
# see ChangeLog
#
# Revision 1.7  2001/01/08 17:30:58  cgilmore
# added handling of blank userid and better handled set_handlers workaround
#
# Revision 1.6  2001/01/08 17:26:35  cgilmore
# released
#
# Revision 1.5  2000/09/26 18:26:54  cgilmore
# updated to Apache-general from Tivoli namespace. Updated pod.
#
# Revision 1.4  2000/08/26 15:33:04  cgilmore
# re-designed. See pod.
#
# Revision 1.3  2000/08/21 14:06:45  cgilmore
# *** empty log message ***
#
# Revision 1.2  2000/07/12 18:32:07  cgilmore
# Finally found a hack (using r->notes) around bugs in set_handlers()
# and lookup_uri(). See files for more.
#
# Revision 1.1  2000/06/01 16:19:04  cgilmore
# Initial revision
#
###############################################################################
###############################################################################


