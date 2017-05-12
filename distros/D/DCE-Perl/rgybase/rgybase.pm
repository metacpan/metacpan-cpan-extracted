package DCE::rgybase;

use strict;
use Carp;
use vars qw($VERSION @ISA $AUTOLOAD);

require DynaLoader;
require AutoLoader;

@ISA = qw(DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = '1.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined DCE::rgybase macro $constname";
	}
    }
    eval "sub $AUTOLOAD () { $val }";
    goto &$AUTOLOAD;
}

bootstrap DCE::rgybase $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

DCE::rgybase - Constants from dce/rgybase.h

=head1 SYNOPSIS

  use DCE::rgybase;

=head1 DESCRIPTION

These constant methods are inherited by DCE::Registry, a developer should not 
need to use this module and its methods directly.

Here is a list of the available constants:

	acct_admin_audit
	acct_admin_client
	acct_admin_flags_none
	acct_admin_server
	acct_admin_valid
	acct_auth_dup_skey
	acct_auth_flags_none
	acct_auth_forwardable
	acct_auth_post_dated
	acct_auth_proxiable
	acct_auth_renewable
	acct_auth_tgt
	acct_key_group
	acct_key_last
	acct_key_none
	acct_key_org
	acct_key_person
	acct_user_flags_none
	acct_user_passwd_valid
	domain_group
	domain_last
	domain_org
	domain_person
	max_unix_passwd_len
	name_max_len
	name_t_size
	no_override
	no_resolve_pname
	override
	pgo_flags_none
	pgo_is_an_alias
	pgo_is_required
	pgo_projlist_ok
	plcy_pwd_flags_none
	plcy_pwd_no_spaces
	plcy_pwd_non_alpha
	pname_max_len
	pname_t_size
	prop_auth_cert_unbound
	prop_embedded_unix_id
	prop_readonly
	prop_shadow_passwd
	properties_none
	quota_unlimited
	resolve_pname
	rgynbase_v0_0_included
	status_ok
	uxid_unknown
	wildcard_name
	wildcard_sid

=head1 AUTHOR

h2xs

=head1 SEE ALSO

perl(1), DCE::Registry(3), DCE::Login(3).

=cut

