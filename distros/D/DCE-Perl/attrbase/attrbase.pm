package DCE::attrbase;

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
	sec_attr_base_v0_0_included
	sec_attr_bind_type_string
	sec_attr_bind_type_svrname
	sec_attr_bind_type_twrs
	sec_attr_bind_auth_none
	sec_attr_bind_auth_dce
	sec_attr_enc_any
	sec_attr_enc_void
	sec_attr_enc_integer
	sec_attr_enc_printstring
	sec_attr_enc_printstring_array
	sec_attr_enc_bytes
	sec_attr_enc_confidential_bytes
	sec_attr_enc_i18n_data
	sec_attr_enc_uuid
	sec_attr_enc_attr_set
	sec_attr_enc_binding
	sec_attr_enc_trig_binding
	sec_attr_sch_entry_multi_inst
	sec_attr_sch_entry_none
	sec_attr_sch_entry_reserved
	sec_attr_sch_entry_unique
	sec_attr_sch_entry_use_defaults
	sec_attr_schema_part_acl_mgrs
	sec_attr_schema_part_comment
	sec_attr_schema_part_defaults
	sec_attr_schema_part_intercell
	sec_attr_schema_part_multi_inst
	sec_attr_schema_part_name
	sec_attr_schema_part_reserved
	sec_attr_schema_part_scope
	sec_attr_schema_part_trig_bind
	sec_attr_schema_part_trig_types
	sec_attr_schema_part_unique
	sec_attr_trig_type_none
	sec_attr_trig_type_query
	sec_attr_trig_type_update
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
		croak "Your vendor has not defined DCE::attrbase macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap DCE::attrbase $VERSION;

sub sec_attr_bind_auth_none { 0; }
sub sec_attr_bind_auth_dce { 1; }

sub sec_attr_enc_any { 0; }
sub sec_attr_enc_void { 1; }
sub sec_attr_enc_integer { 2; }
sub sec_attr_enc_printstring { 3; }
sub sec_attr_enc_printstring_array { 4; }
sub sec_attr_enc_bytes { 5; }
sub sec_attr_enc_confidential_bytes { 6; }
sub sec_attr_enc_i18n_data { 7; }
sub sec_attr_enc_uuid { 8; }
sub sec_attr_enc_attr_set { 9; }
sub sec_attr_enc_binding { 10; }
sub sec_attr_enc_trig_binding { 11; }

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

DCE::attrbase - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DCE::attrbase;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for DCE::attrbase was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 Exported constants

  sec_attr_base_v0_0_included
  sec_attr_bind_type_string
  sec_attr_bind_type_svrname
  sec_attr_bind_type_twrs
  sec_attr_sch_entry_multi_inst
  sec_attr_sch_entry_none
  sec_attr_sch_entry_reserved
  sec_attr_sch_entry_unique
  sec_attr_sch_entry_use_defaults
  sec_attr_schema_part_acl_mgrs
  sec_attr_schema_part_comment
  sec_attr_schema_part_defaults
  sec_attr_schema_part_intercell
  sec_attr_schema_part_multi_inst
  sec_attr_schema_part_name
  sec_attr_schema_part_reserved
  sec_attr_schema_part_scope
  sec_attr_schema_part_trig_bind
  sec_attr_schema_part_trig_types
  sec_attr_schema_part_unique
  sec_attr_trig_type_none
  sec_attr_trig_type_query
  sec_attr_trig_type_update
  volatile


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
