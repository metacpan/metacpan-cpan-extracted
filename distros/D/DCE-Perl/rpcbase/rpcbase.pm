package DCE::rpcbase;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	rpc_c_authn_dce_dummy
	rpc_c_authn_dce_public
	rpc_c_authn_dce_secret
	rpc_c_authn_default
	rpc_c_authn_dssa_public
	rpc_c_authn_none
	rpc_c_authz_dce
	rpc_c_authz_name
	rpc_c_authz_none
	rpc_c_binding_default_timeout
	rpc_c_binding_infinite_timeout
	rpc_c_binding_max_count_default
	rpc_c_binding_max_timeout
	rpc_c_binding_min_timeout
	rpc_c_call_brdcst
	rpc_c_call_idempotent
	rpc_c_call_in_pipe
	rpc_c_call_maybe
	rpc_c_call_non_idempotent
	rpc_c_call_out_pipe
	rpc_c_cancel_infinite_timeout
	rpc_c_ep_max_annotation_size
	rpc_c_listen_max_calls_default
	rpc_c_mgmt_inq_if_ids
	rpc_c_mgmt_inq_princ_name
	rpc_c_mgmt_inq_stats
	rpc_c_mgmt_is_server_listen
	rpc_c_mgmt_stop_server_listen
	rpc_c_ns_dec_dns
	rpc_c_ns_default_exp_age
	rpc_c_ns_none
	rpc_c_ns_syntax_dce
	rpc_c_ns_syntax_dec_dns
	rpc_c_ns_syntax_default
	rpc_c_ns_syntax_internet_dns
	rpc_c_ns_syntax_unknown
	rpc_c_ns_syntax_uuid
	rpc_c_ns_syntax_x500
	rpc_c_profile_all_elts
	rpc_c_profile_default_elt
	rpc_c_profile_match_by_both
	rpc_c_profile_match_by_if
	rpc_c_profile_match_by_mbr
	rpc_c_protect_level_call
	rpc_c_protect_level_connect
	rpc_c_protect_level_default
	rpc_c_protect_level_none
	rpc_c_protect_level_pkt
	rpc_c_protect_level_pkt_integ
	rpc_c_protect_level_pkt_privacy
	rpc_c_protseq_max_reqs_default
	rpc_s_ok
	rpcbase_v0_0_included
	volatile
);
$VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined DCE::rpcbase macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DCE::rpcbase $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

DCE::rpcbase - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DCE::rpcbase;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for DCE::rpcbase was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 Exported constants

  rpc_c_authn_dce_dummy
  rpc_c_authn_dce_public
  rpc_c_authn_dce_secret
  rpc_c_authn_default
  rpc_c_authn_dssa_public
  rpc_c_authn_none
  rpc_c_authz_dce
  rpc_c_authz_name
  rpc_c_authz_none
  rpc_c_binding_default_timeout
  rpc_c_binding_infinite_timeout
  rpc_c_binding_max_count_default
  rpc_c_binding_max_timeout
  rpc_c_binding_min_timeout
  rpc_c_call_brdcst
  rpc_c_call_idempotent
  rpc_c_call_in_pipe
  rpc_c_call_maybe
  rpc_c_call_non_idempotent
  rpc_c_call_out_pipe
  rpc_c_cancel_infinite_timeout
  rpc_c_ep_max_annotation_size
  rpc_c_listen_max_calls_default
  rpc_c_mgmt_inq_if_ids
  rpc_c_mgmt_inq_princ_name
  rpc_c_mgmt_inq_stats
  rpc_c_mgmt_is_server_listen
  rpc_c_mgmt_stop_server_listen
  rpc_c_ns_dec_dns
  rpc_c_ns_default_exp_age
  rpc_c_ns_none
  rpc_c_ns_syntax_dce
  rpc_c_ns_syntax_dec_dns
  rpc_c_ns_syntax_default
  rpc_c_ns_syntax_internet_dns
  rpc_c_ns_syntax_unknown
  rpc_c_ns_syntax_uuid
  rpc_c_ns_syntax_x500
  rpc_c_profile_all_elts
  rpc_c_profile_default_elt
  rpc_c_profile_match_by_both
  rpc_c_profile_match_by_if
  rpc_c_profile_match_by_mbr
  rpc_c_protect_level_call
  rpc_c_protect_level_connect
  rpc_c_protect_level_default
  rpc_c_protect_level_none
  rpc_c_protect_level_pkt
  rpc_c_protect_level_pkt_integ
  rpc_c_protect_level_pkt_privacy
  rpc_c_protseq_max_reqs_default
  rpc_s_ok
  rpcbase_v0_0_included
  volatile


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
