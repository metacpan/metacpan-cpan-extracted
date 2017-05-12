# --*-Perl-*--
# $Id: ReferenceStyle.pm 11 2004-11-22 23:56:20Z tandler $
#

package PBib::ReferenceStyle;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 11 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::Style;
use base qw(PBib::Style);

# used modules
#use ZZZZ;

# module variables
#use vars qw(mmmm);


#
#
# access methods
#
#

sub options { my $self = shift; return $self->converter()->refOptions(); }

sub referenceSeparator { my ($self) = @_;
# if defined, use this char to separate references within one field

}

#
#
# methods
#
#

sub text {
#
# return the replacement text
# the refField is unquoted (i.e. the standard char set),
#
	my ($self, $refField) = @_;
	my $options;
	
	# check for options ...
	if( $refField =~ s/^\s*:\s*([^\|\[\]]*)\s*\|\s*// ) {
		$options = $self->parseFieldOptions($1);
		$self->{'fieldOptions'} = $options;
		#  	print "-- field options: $options\n";
	}
	
	#  print STDERR "\tfield [$refField]\n";
	$refField = $self->formatField($refField, $options);
	#  print STDERR "\t--> $refField\n";
	return $refField;
}

sub formatField {
#
# return the replacement text for the field
# can be overwritten by subclasses
# to implement more sophisticated styles
# default is the nice style with brackets [...]
#
  my ($self, $refField, $options) = @_;
  $refField = $self->labelStyle()->formatSeparators($refField, $options);
  my $refPattern = $self->converter()->refPattern();
#  print "ref pattern: $refPattern\n";
  $refField =~ s/\[($refPattern)\]/
	$self->{'refID'} = $1,
	$self->formatReference($1, $options) /ge;
  $refField = $self->labelStyle()->formatField($refField, $options);
  return $refField;
}

sub formatReference {
#
# return the replacement text for one reference
# can be overwritten by subclasses
# to implement more sophisticated styles
# nevertheless, it should call formatLabel to get a label
#
  my ($self, $refID, $options) = @_;
  return $self->formatLabel($refID, $options);
}

sub formatLabel {
  my ($self, $refID, $options) = @_;
  return $self->labelStyle()->text($refID, $options);
}

sub bookmarkID {
# return an ID that can be used as bookmark or undef
  my ($self, $id) = @_;
  return undef;
}


1;

#
# $Log: ReferenceStyle.pm,v $
# Revision 1.5  2002/08/08 08:21:38  Diss
# - parsing of options moved to PBib::Style
#
# Revision 1.4  2002/03/27 10:23:15  Diss
# small fixes ...
#
# Revision 1.3  2002/03/27 10:00:51  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.2  2002/03/22 17:31:01  Diss
# small changes
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#