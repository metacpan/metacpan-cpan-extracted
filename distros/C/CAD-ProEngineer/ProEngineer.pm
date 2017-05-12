
#
# CAD::ProEngineer package
#

package CAD::ProEngineer;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

sub dl_load_flags { 0x01 }

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CAD::ProEngineer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';

sub new {
    my($class) = @_;
    my $self = {};
    bless $self, $class;
    # print "class: ", $class, "  ref: ", ref($class), "\n";
    return $self;
}


# We provide a DESTROY method so that the autoloader
# doesn't bother trying to find it.
sub DESTROY { }


#  sub AUTOLOAD {
#      # This AUTOLOAD is used to 'autoload' constants from the constant()
#      # XS function.  If a constant is not found then control is passed
#      # to the AUTOLOAD in AutoLoader.
#  
#      my $constname;
#      our $AUTOLOAD;
#      ($constname = $AUTOLOAD) =~ s/.*:://;
#      croak "& not defined" if $constname eq 'constant';
#      print "  AUTOLOAD args:", join('|',@_), "\n";
#      my $val = constant($constname, int(@_ ? $_[0] : 0));
#      if ($! != 0) {
#  	if ($! =~ /Invalid/ || $!{EINVAL}) {
#  	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
#  	    goto &AutoLoader::AUTOLOAD;
#  	}
#  	else {
#  	    croak "Your vendor has not defined CAD::ProEngineer macro $constname";
#  	}
#      }
#      {
#  	no strict 'refs';
#  	# Fixed between 5.005_53 and 5.005_61
#  	if ($] >= 5.00561) {
#  	    *$AUTOLOAD = sub () { $val };
#  	}
#  	else {
#  	    *$AUTOLOAD = sub { $val };
#  	}
#      }
#      goto &$AUTOLOAD;
#  }


bootstrap CAD::ProEngineer $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.




our %Callbacks;
our $Verbose = 0;

sub Register_Callback {
  my($code_ref) = pop @_;
  my($cb_num, $domain);
  print "code_ref: ", $code_ref, " ", ref($code_ref), "\n";
  print "  args: ", join('|',@_), "\n";

  if (ref($code_ref) ne "CODE") {print "Not a code ref!\n";return undef};

  if (scalar(@_) > 2) {
    $cb_num = pop @_;
    $domain = pop @_;
    print "    getting cb_num from args: $cb_num\n";
  }
  else {
    # $cb_num = (scalar keys %Callbacks) + 1;
    map{$cb_num=($_>=$cb_num?$_+1:$cb_num+0)} (0, keys %Callbacks);
    $domain = pop @_;
    print "    getting cb_num from keys: $cb_num\n";
  }
  print "  using cb_num: ", $cb_num, "\n";

  $Callbacks{$domain}{$cb_num} = $code_ref;
  return $cb_num;
}

sub Execute_Callback {
  my($obj,$Domain,$cb_num,@args);
  if (ref($_[0])) {
    ($obj,$Domain,$cb_num,@args) = @_;
  }
  else {
    ($Domain,$cb_num, @args) = @_;
  }
  # print "cb_num: ", $cb_num, " ", ref($cb_num), "\n";
  if (exists $Callbacks{$Domain}{$cb_num} && defined($Callbacks{$Domain}{$cb_num})) {
    &{$Callbacks{$Domain}{$cb_num}};
  }
}

# sub split_format_string {
#   my($format_string) = $_[0];
#   my(@List);
# 
#   $format_string = '  %d%f %3(-1.4)g%0(2.3)w%1f%-5s %% %3d %4(9)f ';
#   # print "format_string:", $format_string, "\n";
# 
#   $format_string =~ s/%%/ /g;
#   # print "format_string:", $format_string, "\n";
# 
#   $format_string =~ s/\s*%-?[0-9]?-?(\(-?[0-9]+(\.[0-9]+)?\))?/%/g;
#   # print "format_string:", $format_string, "\n";
# 
#   $format_string =~ s/(%.)[^%]*/$1/g;
#   # print "format_string:", $format_string, "\n";
# 
#   @List = split /%/, $format_string; shift @List;
#   # print "list:", join('|',@List), "  count:", scalar(@List), "\n";
# 
#   return(\@List);
# }


#
# CAD::ProEngineer::ProMdl package
#

package CAD::ProEngineer::ProMdl;
our @ISA = qw(CAD::ProEngineer);

our %ProMdlExt_ByExt = (
    "asm" => CAD::ProEngineer::PRO_MDL_ASSEMBLY(),
    "prt" => CAD::ProEngineer::PRO_MDL_PART(),
    "drw" => CAD::ProEngineer::PRO_MDL_DRAWING(),
  );

our %ProMdlExt_ByType = reverse %ProMdlExt_ByExt;

sub new {
  # print "  ProMdl constructor: @_", "\n";
  my $class = shift;
  if (scalar @_ == 0) {
    # print "  ProMdl constructor: zero args", "\n";
    return(CAD::ProEngineer::ProMdlCurrentGet())
  }
  elsif (scalar @_ == 2) {
    # print "  ProMdl constructor: two args", "\n";
    return(CAD::ProEngineer::ProMdlInit($_[0],$_[1]))
  }
  elsif (scalar @_ == 1 && $_[0] =~ /^(.*)\.(.*)(\..*)?$/) {
    my $type = $ProMdlExt_ByExt{lc($2)};
    # print "  ProMdl constructor: one arg ", CAD::ProEngineer::PRO_MDL_ASSEMBLY(), " -- ", $1, " - ", $type, "\n";
    return(CAD::ProEngineer::ProMdlInit($1,$type))
  }
  else {
    return undef;
  }
}

sub DESTROY {
  print "Destroying ProMdl Object: ", $_[0], "\n"  if $Verbose;
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $self = shift;
  my $name = $AUTOLOAD;
  my $pack_prefix = 'ProMdl';
  $name =~ s/.*://;   # strip fully-qualified portion
  # print "Autoloading '$pack_prefix$name' (was '$name') for: $self", "\n";
  $name = $pack_prefix . $name;
  return(scalar($self->$name));
}  

sub ExtensionGet {
  my $self = shift;
  return $ProMdlExt_ByType{$self->TypeGet};
}


#
# CAD::ProEngineer::ProSolid package
#

package CAD::ProEngineer::ProSolid;
our @ISA = qw(CAD::ProEngineer::ProMdl);


#
# CAD::ProEngineer::ProModelitem package
#

package CAD::ProEngineer::ProModelitem;
our @ISA = qw(CAD::ProEngineer);

sub AUTOLOAD {
  our $AUTOLOAD;
  my $self = shift;
  my $name = $AUTOLOAD;
  my $pack_prefix = 'ProModelitem';
  $name =~ s/.*://;   # strip fully-qualified portion
  # print "Autoloading '$pack_prefix$name' (was '$name') for: $self", "\n";
  $name = $pack_prefix . $name;
  return(scalar($self->$name));
}  


#
# CAD::ProEngineer::ProParameter package
#
package CAD::ProEngineer::ProParameter;


#
# CAD::ProEngineer::ProParamvalue package
#
package CAD::ProEngineer::ProParamvalue;


#
# CAD::ProEngineer::ProDimension package
#
package CAD::ProEngineer::ProDimension;



# Put package here again so autosplit does not get confused.
package CAD::ProEngineer;
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CAD::ProEngineer - Perl extension for the Pro/Engineer API (Pro/Toolkit)

=head1 SYNOPSIS

  use CAD::ProEngineer;
  blah blah blah

=head1 DESCRIPTION

This module implements a few Pro/Toolkit functions in perl.  There are two 
main components: an embedded imterpreter and an extension module.  The 
embedded interpreter can be found in the perl folder.  This is an early 
build so don't expect a flawless install to work, but the module works 
very well on Solaris and Windows.  It is not fully tested, so your mileage 
may vary.

Functions implemented (to be documented at a later time):

  ProMdlCurrentGet()
  ProMdlDelete()
  ProMdlDisplay()
  ProMdlErase()
  ProMdlEraseAll()
  ProMdlIdGet()
  ProMdlInit()
  ProMdlModificationVerify()
  ProMdlNameGet()
  ProMdlPostfixIdGet()
  ProSolidPostfixIdGet()
  ProMdlSessionIdGet()
  ProMdlSave()
  ProMdlSubtypeGet()
  ProMdlToModelitem()
  ProMdlTypeGet()
  ProMdlWindowGet()

  ProMessageClear()
  ProMessageDisplay()
  ProMessageDoubleRead()
  ProMessageIntegerRead()
  ProMessagePasswordRead()
  ProMessageStringRead()

  ProCmdActionAdd()
  ProMenubarmenuPushbuttonAdd()

  ProDimensionInit()
  ProDimensionSymbolGet()
  ProDimensionValueGet()
  ProSolidDimensionVisit()

  ProModelitemInit()
  ProModelitemMdlGet()

  ProParameterInit()
  ProParameterNameGet()
  ProParameterValueGet()
  ProParameterVisit()
  ProParamvalueValueGet()

  ProTreetoolRefresh()


  These can be used by three (or more) methods:

    Method #1:
      $retval = CAD::ProEngineer::ProMdlCurrentGet();

    Method #2:
      $o = new CAD::ProEngineer;
      $retval = $o->ProMdlCurrentGet($mdl);

    Method #2:
      $o = new CAD::ProEngineer;
      ($mdl,$retval) = $o->ProMdlCurrentGet();


Enum's available as perl subroutines:

  PRO_TK_NO_ERROR
  PRO_TK_GENERAL_ERROR
  PRO_TK_BAD_INPUTS
  PRO_TK_USER_ABORT
  PRO_TK_E_NOT_FOUND

  PRO_TK_E_FOUND
  PRO_TK_LINE_TOO_LONG
  PRO_TK_CONTINUE
  PRO_TK_BAD_CONTEXT
  PRO_TK_NOT_IMPLEMENTED

  PRO_TK_OUT_OF_MEMORY
  PRO_TK_COMM_ERROR
  PRO_TK_NO_CHANGE
  PRO_TK_SUPP_PARENTS
  PRO_TK_PICK_ABOVE

  PRO_TK_INVALID_DIR
  PRO_TK_INVALID_FILE
  PRO_TK_CANT_WRITE
  PRO_TK_INVALID_TYPE
  PRO_TK_INVALID_PTR

  PRO_TK_UNAV_SEC
  PRO_TK_INVALID_MATRIX
  PRO_TK_INVALID_NAME
  PRO_TK_NOT_EXIST
  PRO_TK_CANT_OPEN
  PRO_TK_ABORT

  PRO_TK_NOT_VALID
  PRO_TK_INVALID_ITEM
  PRO_TK_MSG_NOT_FOUND
  PRO_TK_MSG_NO_TRANS
  PRO_TK_MSG_FMT_ERROR

  PRO_TK_MSG_USER_QUIT
  PRO_TK_MSG_TOO_LONG
  PRO_TK_CANT_ACCESS
  PRO_TK_OBSOLETE_FUNC
  PRO_TK_NO_COORD_SYSTEM

  PRO_TK_E_AMBIGUOUS
  PRO_TK_E_DEADLOCK
  PRO_TK_E_BUSY
  PRO_TK_E_IN_USE
  PRO_TK_NO_LICENSE
  PRO_TK_BSPL_UNSUITABLE_DEGREE

  PRO_TK_BSPL_NON_STD_END_KNOTS
  PRO_TK_BSPL_MULTI_INNER_KNOTS
  PRO_TK_BAD_SRF_CRV
  PRO_TK_EMPTY
  PRO_TK_BAD_DIM_ATTACH

  PRO_TK_NOT_DISPLAYED
  PRO_TK_CANT_MODIFY
  PRO_TK_CHECKOUT_CONFLICT
  PRO_TK_CRE_VIEW_BAD_SHEET
  PRO_TK_CRE_VIEW_BAD_MODEL

  PRO_TK_CRE_VIEW_BAD_PARENT
  PRO_TK_CRE_VIEW_BAD_TYPE
  PRO_TK_CRE_VIEW_BAD_EXPLODE
  PRO_TK_UNATTACHED_FEATS
  PRO_TK_REGEN_AGAIN
  PRO_TK_DWGCREATE_ERRORS
  
  PRO_MDL_UNUSED
  PRO_MDL_ASSEMBLY
  PRO_MDL_PART
  PRO_MDL_DRAWING
  PRO_MDL_3DSECTION
  PRO_MDL_2DSECTION
  PRO_MDL_LAYOUT
  PRO_MDL_DWGFORM
  PRO_MDL_MFG
  PRO_MDL_REPORT
  PRO_MDL_MARKUP
  PRO_MDL_DIAGRAM

  PROMDLSTYPE_NONE
  PROMDLSTYPE_BULK
  PROMDLSTYPE_PART_SOLID
  PROMDLSTYPE_PART_COMPOSITE
  PROMDLSTYPE_PART_SHEETMETAL
  PROMDLSTYPE_PART_CONCEPT_MODEL
  PROMDLSTYPE_ASM_DESIGN
  PROMDLSTYPE_ASM_INTERCHANGE
  PROMDLSTYPE_ASM_INTCHG_SUBST
  PROMDLSTYPE_ASM_INTCHG_FUNC
  PROMDLSTYPE_ASM_CLASS_CAV
  PROMDLSTYPE_ASM_VERIFY
  PROMDLSTYPE_ASM_PROCPLAN
  PROMDLSTYPE_ASM_NCMODEL
  PROMDLSTYPE_MFG_NCASM
  PROMDLSTYPE_MFG_NCPART
  PROMDLSTYPE_MFG_EXPMACH
  PROMDLSTYPE_MFG_CMM
  PROMDLSTYPE_MFG_SHEETMETAL
  PROMDLSTYPE_MFG_CAST
  PROMDLSTYPE_MFG_MOLD
  PROMDLSTYPE_MFG_DIEFACE
  PROMDLSTYPE_MFG_HARNESS
  PROMDLSTYPE_MFG_PROCPLAN
  PROMDLSTYPE_REGEN_BACKUP
  PROMDLSTYPE_OLD_REG_MFG
  PROMDLSTYPE_ASM_CLASS_SCAN_SET

  PRO_B_FALSE
  PRO_B_TRUE

  uiCmdPrioDefault
  uiProeImmediate
  uiProeAsynch
  uiProe2ndImmediate
  uiProe3rdImmediate
  uiCmdNoPriority


  These can be used by two methods:

    Method #1:
      if ($retval == CAD::ProEngineer::PRO_B_TRUE) ...

    Method #2:
      $o = new CAD::ProEngineer;
      if ($retval == $o->PRO_B_TRUE) ...



=head2 EXPORT

None by default, but a pseudo object oriented syntax can be used.


=head1 AUTHOR

Marc Mettes, E<lt>marcs_perl@yahoo.comE<gt>


=head1 COPYRIGHT

The CAD::ProEngineer module is Copyright (c) 2003 Marc Mettes.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<perl>, L<perlapi>, L<perlxs>, L<perlembed>.

=cut


