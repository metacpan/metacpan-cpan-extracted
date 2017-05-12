# Copyright (c) 2002 Andrew J. Korty
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# $Id: Admin.pm,v 1.24 2008/02/25 13:46:54 ajk Exp $

package Authen::Krb5::Admin;

use strict;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

use Carp;

require 5.004;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(
	ENCTYPE_DES3_CBC_RAW
	ENCTYPE_DES3_CBC_SHA
	ENCTYPE_DES3_CBC_SHA1
	ENCTYPE_DES_CBC_CRC
	ENCTYPE_DES_CBC_MD4
	ENCTYPE_DES_CBC_MD5
	ENCTYPE_DES_CBC_RAW
	ENCTYPE_DES_HMAC_SHA1
	ENCTYPE_LOCAL_DES3_HMAC_SHA1
	ENCTYPE_NULL
	ENCTYPE_UNKNOWN
	KADM5_ADMIN_SERVICE
	KADM5_API_VERSION_1
	KADM5_API_VERSION_2
	KADM5_API_VERSION_3
	KADM5_API_VERSION_4
	KADM5_API_VERSION_MASK
	KADM5_ATTRIBUTES
	KADM5_AUTH_ADD
	KADM5_AUTH_CHANGEPW
	KADM5_AUTH_DELETE
	KADM5_AUTH_GET
	KADM5_AUTH_INSUFFICIENT
	KADM5_AUTH_LIST
	KADM5_AUTH_MODIFY
	KADM5_AUTH_SETKEY
	KADM5_AUX_ATTRIBUTES
	KADM5_BAD_API_VERSION
	KADM5_BAD_AUX_ATTR
	KADM5_BAD_CLASS
	KADM5_BAD_CLIENT_PARAMS
	KADM5_BAD_DB
	KADM5_BAD_HISTORY
	KADM5_BAD_HIST_KEY
	KADM5_BAD_LENGTH
	KADM5_BAD_MASK
	KADM5_BAD_MIN_PASS_LIFE
	KADM5_BAD_PASSWORD
	KADM5_BAD_POLICY
	KADM5_BAD_PRINCIPAL
	KADM5_BAD_SERVER_HANDLE
	KADM5_BAD_SERVER_NAME
	KADM5_BAD_SERVER_PARAMS
	KADM5_BAD_STRUCT_VERSION
	KADM5_BAD_TL_TYPE
	KADM5_CHANGEPW_SERVICE
	KADM5_CONFIG_ACL_FILE
	KADM5_CONFIG_ADBNAME
	KADM5_CONFIG_ADB_LOCKFILE
	KADM5_CONFIG_ADMIN_KEYTAB
	KADM5_CONFIG_ADMIN_SERVER
	KADM5_CONFIG_DBNAME
	KADM5_CONFIG_DICT_FILE
	KADM5_CONFIG_ENCTYPE
	KADM5_CONFIG_ENCTYPES
	KADM5_CONFIG_EXPIRATION
	KADM5_CONFIG_FLAGS
	KADM5_CONFIG_KADMIND_PORT
	KADM5_CONFIG_KPASSWD_PORT
	KADM5_CONFIG_MAX_LIFE
	KADM5_CONFIG_MAX_RLIFE
	KADM5_CONFIG_MKEY_FROM_KBD
	KADM5_CONFIG_MKEY_NAME
	KADM5_CONFIG_PROFILE
	KADM5_CONFIG_REALM
	KADM5_CONFIG_STASH_FILE
	KADM5_DUP
	KADM5_FAILURE
	KADM5_FAIL_AUTH_COUNT
	KADM5_GSS_ERROR
	KADM5_HIST_PRINCIPAL
	KADM5_INIT
	KADM5_KEY_DATA
	KADM5_KVNO
	KADM5_LAST_FAILED
	KADM5_LAST_PWD_CHANGE
	KADM5_LAST_SUCCESS
	KADM5_MASK_BITS
	KADM5_MAX_LIFE
	KADM5_MAX_RLIFE
	KADM5_MISSING_CONF_PARAMS
	KADM5_MKVNO
	KADM5_MOD_NAME
	KADM5_MOD_TIME
	KADM5_NEW_LIB_API_VERSION
	KADM5_NEW_SERVER_API_VERSION
	KADM5_NEW_STRUCT_VERSION
	KADM5_NOT_INIT
	KADM5_NO_RENAME_SALT
	KADM5_NO_SRV
	KADM5_OK
	KADM5_OLD_LIB_API_VERSION
	KADM5_OLD_SERVER_API_VERSION
	KADM5_OLD_STRUCT_VERSION
	KADM5_PASS_Q_CLASS
	KADM5_PASS_Q_DICT
	KADM5_PASS_Q_TOOSHORT
	KADM5_PASS_REUSE
	KADM5_PASS_TOOSOON
	KADM5_POLICY
	KADM5_POLICY_CLR
	KADM5_POLICY_REF
	KADM5_PRINCIPAL
	KADM5_PRINCIPAL_NORMAL_MASK
	KADM5_PRINC_EXPIRE_TIME
	KADM5_PRIV_ADD
	KADM5_PRIV_DELETE
	KADM5_PRIV_GET
	KADM5_PRIV_MODIFY
	KADM5_PROTECT_PRINCIPAL
	KADM5_PW_EXPIRATION
	KADM5_PW_HISTORY_NUM
	KADM5_PW_MAX_LIFE
	KADM5_PW_MIN_CLASSES
	KADM5_PW_MIN_LENGTH
	KADM5_PW_MIN_LIFE
	KADM5_REF_COUNT
	KADM5_RPC_ERROR
	KADM5_SECURE_PRINC_MISSING
	KADM5_SETKEY3_ETYPE_MISMATCH
	KADM5_SETKEY_DUP_ENCTYPES
	KADM5_SETV4KEY_INVAL_ENCTYPE
	KADM5_STRUCT_VERSION
	KADM5_STRUCT_VERSION_1
	KADM5_STRUCT_VERSION_MASK
	KADM5_TL_DATA
	KADM5_UNK_POLICY
	KADM5_UNK_PRINC
	KRB5_KDB_DISALLOW_ALL_TIX
	KRB5_KDB_DISALLOW_DUP_SKEY
	KRB5_KDB_DISALLOW_FORWARDABLE
	KRB5_KDB_DISALLOW_POSTDATED
	KRB5_KDB_DISALLOW_PROXIABLE
	KRB5_KDB_DISALLOW_RENEWABLE
	KRB5_KDB_DISALLOW_SVR
	KRB5_KDB_DISALLOW_TGT_BASED
	KRB5_KDB_NEW_PRINC
	KRB5_KDB_PWCHANGE_SERVICE
	KRB5_KDB_REQUIRES_HW_AUTH
	KRB5_KDB_REQUIRES_PRE_AUTH
	KRB5_KDB_REQUIRES_PWCHANGE
	KRB5_KDB_SALTTYPE_AFS3
	KRB5_KDB_SALTTYPE_NOREALM
	KRB5_KDB_SALTTYPE_NORMAL
	KRB5_KDB_SALTTYPE_ONLYREALM
	KRB5_KDB_SALTTYPE_SPECIAL
	KRB5_KDB_SALTTYPE_V4
	KRB5_KDB_SUPPORT_DESMD5
        KADM5_CONFIG_AUTH_NOFALLBACK
        KADM5_CONFIG_NO_AUTH
        KADM5_CONFIG_OLD_AUTH_GSSAPI
	KRB5_KDB_ACCESS_ERROR
);
%EXPORT_TAGS = (constants => \@EXPORT_OK);
$VERSION = '0.17';

# Preloaded methods go here.

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the
	# constant() XS function.  If a constant is not found then
	# control is passed to the AUTOLOAD in AutoLoader.

	my $constname;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak $constname, ' not defined' if $constname eq 'constant';
	my $val = constant($constname, @_ ? $_[0] : 0);
	if ($! != 0) {
		if ($! =~ /Invalid/) {
			$AutoLoader::AUTOLOAD = $AUTOLOAD;
			goto &AutoLoader::AUTOLOAD;
		} else {
			croak 'Your vendor has not defined ', __PACKAGE__,
			    ' macro ', $constname;
		}
	}
	eval "sub $AUTOLOAD { $val }";
	goto &$AUTOLOAD;
}

sub KADM5_ADMIN_SERVICE		{ 'kadmin/admin' }
sub KADM5_CHANGEPW_SERVICE	{ 'kadmin/changepw' }
sub KADM5_HIST_PRINCIPAL	{ 'kadmin/history' }

bootstrap Authen::Krb5::Admin $VERSION;

1;
__END__

=head1 NAME

Authen::Krb5::Admin - Perl extension for MIT Kerberos 5 admin interface

=head1 SYNOPSIS

  use Authen::Krb5::Admin;
  use Authen::Krb5::Admin qw(:constants);

=head1 DESCRIPTION

The B<Authen::Krb5::Admin> Perl module is an object-oriented interface
to the Kerberos 5 admin server.  Currently only MIT KDCs are
supported, but the author envisions seamless integration with other
KDCs.

The following classes are provided by this module:

 Authen::Krb5::Admin             handle for performing kadmin operations
 Authen::Krb5::Admin::Config     kadmin configuration parameters
 Authen::Krb5::Admin::Key        key data from principal object
 Authen::Krb5::Admin::Policy     kadmin policies
 Authen::Krb5::Admin::Principal  kadmin principals

=head2 Configuration Parameters, Policies, and Principals

Before performing kadmin operations, the programmer must construct
objects to represent the entities to be manipulated.  Each of the
classes

	Authen::Krb5::Admin::Config
	Authen::Krb5::Admin::Key
	Authen::Krb5::Admin::Policy
	Authen::Krb5::Admin::Principal

has a constructor I<new> which takes no arguments (except for the
class name).  The new object may be populated using accessor methods,
each of which is named for the C struct element it represents.
Methods always return the current value of the attribute, except for
the I<policy_clear> method, which returns nothing.  If a value is
provided, the attribute is set to that value, and the new value is
returned.

All attributes may be modified in each object, but read-only
attributes will be ignored when performing kadmin operations.  These
attributes are indicated in the documentation for their accessor
methods.

Each of the C functions that manipulate I<kadm5> principal and policy
structures takes a mask argument to indicate which fields should be
taken into account.  The Perl accessor methods take care of the mask
for you, assuming that when you change a value, you will eventually
want it changed on the server.

Flags for the read-only fields do not get set automatically because
they would result in a bad mask error when performing kadmin
operations.

Some writable attributes are not allowed to have their masks set for
certain operations.  For example, KADM5_POLICY may not be set during a
I<create_principal> operation, but since the Perl module sets that
flag automatically when you set the I<policy> attribute of the
principal object, a bad mask error would result.  Therefore, some
kadmin operations automatically clear certain flags first.

Though you should never have to, you can manipulate the mask on your
own using the I<mask> methods and the flags associated with each
attribute (indicated in curly braces ({}s) below).  Use the tag
I<:constants> to request that the flag constants (and all other
constants) be made available (see L<Exporter(3)>).

=over 8

=item B<Authen::Krb5::Admin::Config>

This class is used to configure a kadmin connection.  Without this
object, B<Authen::Krb5::Admin> constructors will default to the
configuration defined in the Kerberos 5 profile (F</etc/krb5.conf> by
default).  So this object is usually only needed when selecting
alternate realms or contacting a specific, non-default server.

The only methods in this class are the constructor (I<new>, described
above) and the following accessor methods.

=item * admin_server {KADM5_CONFIG_ADMIN_SERVER}

Admin server hostname

=item * kadmind_port {KADM5_CONFIG_KADMIND_PORT}

Admin server port number

=item * kpasswd_port {KADM5_CONFIG_KPASSWD_PORT}

Kpasswd server port number

=item * mask

Mask (described above)

=item * profile {KADM5_CONFIG_PROFILE}

Kerberos 5 configuration profile

=item * realm {KADM5_CONFIG_REALM}

Kerberos 5 realm name

=item B<Authen::Krb5::Admin::Key>

This class represents key data contained in kadmin principal objects.
The only methods in this class are the constructor (I<new>, described
above) and the following accessor methods.

=item * key_contents

Key contents, encrypted with the KDC master key.  This data may not be
available remotely.

=item * enc_type

Kerberos 5 enctype of the key

=item * key_type

Alias for I<enc_type>

=item * kvno

Key version number

=item * salt_contents

Salt contents, if any (I<ver> > 1)

=item * salt_type

Salt type, if any (I<ver> > 1)

=item * ver

Version number of the underlying I<krb5_key_data> structure

=item B<Authen::Krb5::Admin::Policy>

This class represents kadmin policies.  The only methods in this class
are the constructor (I<new>, described above) and the following
accessor methods.

=item * mask

Mask (described above)

=item * name {KADM5_POLICY}

Policy name

=item * pw_history_num {KADM5_PW_HISTORY_NUM}

Number (between 1 and 10, inclusive) of past passwords to be stored
for the principal.  A principal may not set its password to any of its
previous I<pw_history_num> passwords.

=item * pw_max_life {KADM5_PW_MAX_LIFE}

Default number of seconds a password lasts before the principal is
required to change it

=item * pw_max_fail {KADM5_PW_MAX_FAILURE}

The maximum allowed number of attempts before a lockout.

=item * pw_failcnt_interval {KADM5_PW_FAILURE_COUNT_INTERVAL}

The period after which the bad preauthentication count will be reset.

=item * pw_lockout_duration {KADM5_PW_LOCKOUT_DURATION}

The period in which lockout is enforced; a duration of zero means that
the principal must be manually unlocked.

=item * pw_min_classes {KADM5_PW_MIN_CLASSES}

Number (between 1 and 5, inclusive) of required character classes
represented in a password

=item * pw_min_length {KADM5_PW_MIN_LENGTH}

Minimum number of characters in a password

=item * pw_min_life {KADM5_PW_MIN_LIFE}

Number of seconds a password must age before the principal may change
it

=item * policy_refcnt {KADM5_REF_COUNT}

Number of principals referring to this policy (read-only, does not set
KADM5_REF_COUNT automatically)

=item Authen::Krb5::Admin::Principal

The attributes I<fail_auth_count>, I<last_failed>, and I<last_success>
are only meaningful if the KDC is configured to update the database
with this type of information.

The only methods in this class are the constructor (I<new>, described
above), the following accessor methods, and I<policy_clear>, which is
used to clear the policy attribute.

=item * attributes {KADM5_ATTRIBUTES}

Bitfield representing principal attributes (see L<kadmin(8)>)

=item * aux_attributes {KADM5_AUX_ATTRIBUTES}

Bitfield used by kadmin.  Currently only recognizes the KADM5_POLICY,
which indicates that a policy is in effect for this principal.  This
attribute is read-only, so KADM5_AUX_ATTRIBUTES is not set
automatically.

=item * fail_auth_count {KADM5_FAIL_AUTH_COUNT}

Number of consecutive failed AS_REQs for this principal.  This
attribute is read-only, so KADM5_FAIL_AUTH_COUNT is not set
automatically.

=item * kvno {KADM5_KVNO}

Key version number

=item * last_failed {KADM5_LAST_FAILED}

Time (in seconds since the Epoch) of the last failed AS_REQ for this
principal.  This attribute is read-only, so KADM5_LAST_FAILED is not
set automatically.

=item * last_pwd_change {KADM5_LAST_PWD_CHANGE}

Time (in seconds since the Epoch) of the last password change for this
principal.  This attribute is read-only, so KADM5_LAST_PWD_CHANGE is
not set automatically.

=item * last_success {KADM5_LAST_SUCCESS}

Time (in seconds since the Epoch) of the last successful AS_REQ for
this principal.  This attribute is read-only, so KADM5_LAST_SUCCESS is
not set automatically.

=item * mask

Mask (see above)

=item * max_life {KADM5_MAX_LIFE}

maximum lifetime in seconds of any Kerberos ticket issued to this
principal

=item * max_renewable_life {KADM5_MAX_RLIFE}

maximum renewable lifetime in seconds of any Kerberos ticket issued to
this principal

=item * mod_date {KADM5_MOD_TIME}

Time (in seconds since the Epoch) this principal was last modified.
This attribute is read-only, so KADM5_MOD_TIME is not set
automatically.

=item * mod_name {KADM5_MOD_NAME}

Kerberos principal (B<Authen::Krb5::Principal>, see
L<Authen::Krb5(3)>) that last modified this principal.  This attribute
is read-only, so KADM5_MOD_NAME is not set automatically.

=item * policy {KADM5_POLICY}

Name of policy that affects this principal if KADM5_POLICY is set in
I<aux_attributes>

=item * policy_clear {KADM5_POLICY_CLR}

Not really an attribute--disables the current policy for this
principal.  This method doesn't return anything.

=item * princ_expire_time {KADM5_PRINC_EXPIRE_TIME}

Expire time (in seconds since the Epoch) of the principal

=item * principal {KADM5_PRINCIPAL}

Kerberos principal itself (B<Authen::Krb5::Principal>, see
L<Authen::Krb5(3)>)

=item * pw_expiration {KADM5_PW_EXPIRATION}

Expire time (in seconds since the Epoch) of the principal's password

=item * db_args [@ARGS]

When called without any C<@ARGS>, returns the list of arguments that
will be passed into the underlying database, as with C<addprinc -x> in
C<kadmin>. If C<@ARGS> is non-empty, it will replace any database
arguments, which will then be returned, like this:

    my @old = $principal->db_args;
    # -or-
    my @old = $principal->db_args(@new);

    # The RPC call will ignore the tail data unless
    # you set this flag:
    $principal->mask($principal->mask | KADM5_TL_DATA);

=back

=head2 Operations

To perform kadmin operations (addprinc, delprinc, etc.), we first
construct an object of the class B<Authen::Krb5::Admin>, which
contains a server handle.  Then we use object methods to perform the
operations using that handle.

In the following synopses, parameter types are indicated by their
names as follows:

	$error		Kerberos 5 error code
	$kadm5		Authen::Krb5::Admin
	$kadm5_config	Authen::Krb5::Admin::Config
	$kadm5_pol	Authen::Krb5::Admin::Policy
	$kadm5_princ	Authen::Krb5::Admin::Principal
	$krb5_ccache	Authen::Krb5::Ccache
	$krb5_princ	Authen::Krb5::Principal
	$success	TRUE if if the call succeeeded, undef otherwise

Everything else is an unblessed scalar value (or an array of them)
inferable from context.

Parameters surrounded by square brackets ([]s) are each optional.

=over 8

=item Constructors

Each of the following constructors authenticates as $client to the
admin server $service, which defaults to KADM5_ADMIN_SERVICE if undef.
An undefined value for $kadm5_config will cause the interface to infer
the configuration from the Kerberos 5 profile (F</etc/krb5.conf> by
default).

=item * $kadm5 =  Authen::Krb5::Admin->init_with_creds($client, $krb5_ccache[, $service, $kadm5_config])

Authenticate using the credentials cached in $krb5_ccache.

=item * $kadm5 = Authen::Krb5::Admin->init_with_password($client[, $password, $service, $kadm5_config])

Authenticate with $password.

=item * $kadm5 = Authen::Krb5::Admin->init_with_skey($client[, $keytab_file, $service, $kadm5_config])

Authenticate using the keytab stored in $keytab_file.  If $keytab_file
is undef, the default keytab is used.

=item Principal Operations

=item * $success = $kadm5->chpass_principal($krb5_princ, $password)

Change the password of $krb5_princ to $password.

=item * $success = $kadm5->create_principal($kadm5_princ[, $password])

Insert $kadm5_princ into the database, optionally setting its password
to the string in $password.  Clears KADM5_POLICY_CLR and
KADM5_FAIL_AUTH_COUNT.

=item * $success = $kadm5->delete_principal($krb5_princ)

Delete the principal represented by $krb5_princ from the database.

=item * $kadm5_princ = $kadm5->get_principal($krb5_princ[, $mask])

Retrieve the Authen::Krb5::Admin::Principal object for the principal
$krb5_princ from the database.  Use KADM5_PRINCIPAL_NORMAL_MASK to
retrieve all of the useful attributes.

=item * @names = $kadm5->get_principals([$expr])

Retrieve a list of principal names matching the glob pattern $expr.
In the absence of $expr, retrieve the list of all principal names.

=item * $success = $kadm5->modify_principal($kadm5_princ)

Modify $kadm5_princ in the database.  The principal to modify is
determined by C<$kadm5_princ-E<gt>principal>, and the rest of the writable
parameters will be modified accordingly.  Clears KADM5_PRINCIPAL.

=item * @keys = $kadm5->randkey_principal($krb5_princ)

Randomize the principal in the database represented by $krb5_princ and
return B<Authen::Krb5::Keyblock> objects.

=item * $success = $kadm5->rename_principal($krb5_princ_from, $krb5_princ_to)

Change the name of the principal from $krb5_princ_from to $krb5_princ_to.

=item Policy Operations

=item * $success = $kadm5->create_policy($kadm5_pol)

Insert $kadm5_pol into the database.

=item * $success = $kadm5->delete_policy($name)

Delete the policy named $name from the database.

=item * $kadm5_pol = $kadm5->get_policy([$name])

Retrieve the B<Authen::Krb5::Admin::Policy> object for the policy
named $name from the database.

=item * @names = $kadm5->get_policies([$expr])

Retrieve a list of policy names matching the glob pattern $expr.  In
the absence of $expr, retrieve the list of all policy names.

=item * $success = $kadm5->modify_policy($kadm5_pol)

Modify $kadm5_pol in the database.  The policy to modify is
determined by C<$kadm5_pol->name>,(and the rest of the writable)
parameters will be modified accordingly.  Clears KADM5_POLICY.

=item Other Methods

=item * $magic_value = Authen::Krb5::Admin::error [$error]

Return value that acts like $! (see L<perlvar(1)>) for the most
recent Authen::Krb5::Admin call.  With error code $error, return
the error message corresponding to that error code.

=item * $error_code = Authen::Krb5::Admin::error_code

Returns the value of the error code for the most recent
Authen::Krb5::Admin call as a simple integer.

=item * $privs = $kadm5->get_privs

Return a bitfield representing the kadmin privileges a principal has,
as follows:

	get	KADM5_PRIV_GET
	add	KADM5_PRIV_ADD
	modify	KADM5_PRIV_MODIFY
	delete	KADM5_PRIV_DELETE

=back

=head1 EXAMPLES

See the unit tests included with this software for examlpes.  They can
be found in the F<t/> subdirectory of the distribution.

=head1 FILES

 krb.conf		Kerberos 5 configuration file

=head1 BUGS

There is no facility for specifying keysalts for methods like
I<create_principal> and I<modify_principal>.  This facility is
provided by the Kerberos 5 API and requires an initialized context.
So it probably makes more sense for B<Authen::Krb5(3)> to handle those
functions.

=head1 AUTHOR

Stephen Quinney <squinney@inf.ed.ac.uk>

Author Emeritus: Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

perl(1), perlvar(1), Authen::Krb5(3), Exporter(3), kadmin(8).

=cut
