# --*-Perl-*--
# $Id: LabelStyle.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::LabelStyle;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#  use PBib::Style;
use base qw(PBib::Style);

# used modules
#use ZZZZ;

# module variables
# our ($mmmm);

#
#
# access methods
#
#

sub options { my $self = shift; return $self->converter()->labelOptions(); }

sub items { my $self = shift;
  return $self->bibStyle()->items();
}

#
# label options
#

sub useUniqueLabels { my ($self) = @_;
	my $opt = $self->option("unique");
	return defined($opt) ? $opt : 1;
}
sub forceKey { my ($self) = @_;
# should the 'Key' field take precedence over the default label?
	return $self->option("forcekey") || 0;
}

#
# label & field options
#

sub etalNumber { my ($self, $options) = @_;
# how many authors until I use the "et al." style?
  return $self->fieldOption("etal", $options) || 3;
}
sub inlineField { my ($self, $options) = @_;
# should this field be inlined (if the style allows), e.g.
# Tandler (2001) instead of (Tandler, 2001)
  return $self->fieldOption("inline", $options) || 0;
}
sub suppressAuthor { my ($self, $options) = @_;
# similar to "inline": don't output an author name, e.g.
# (2001) instead of (Tandler, 2001).
# This can be used, if the author is given already in the text, e.g.
# "... as Tandler [ :noauthor | [Tandler-2001]] says ..." will become
# "... as Tandler (2001) says ..." or
# "... as Tandler [42] says ..." or
# "... as Tandler [Tan01] says ..." depending on style.
  return $self->fieldOption("noauthor", $options) || 0;
}
sub noParens { my ($self, $options) = @_;
# produce no surrounding parentheses, e.g.
# "Tandler, 2001"
  return $self->fieldOption("noparens", $options) || 0;
}

sub useBraces { my ($self, $options) = @_;
# use [...] instead of (...) for reference.
#### This should be a option of class ReferenceStyle instead!!!
  return $self->fieldOption("useBraces", $options) || 0;
}



#
#
# methods
#
#

sub text {
#
# return the replacement text
#
  my ($self, $refID, $options) = @_;
  $self->setRefID($refID);
  $self->{'fieldOptions'} = $options;

  my $labels = $self->{'labels'};
  if( not defined($labels) ) {
	$self->logMessage("generate labels");
	$labels = $self->{'labels'} = {};
	$self->{'uniqueLabelPostfixes'} = {};
	my $items = $self->items();
	my $label;
  	foreach my $item (@$items) {
	  $self->setRefID($item);
  	  $label = ($self->forceKey() && $self->entryNotEmpty('Key'))
	  		? $self->entry('Key')
	  		: $self->formatLabel($item, $options);
	  $labels->{$item} = $label;
  	}

	# check for unique names?
	if( $self->useUniqueLabels() ) {
	  my %allLabels;
  	  foreach my $item (@$items) {
	    $label = $labels->{$item};
	    while( exists($allLabels{$label}) ) {
		  $label = $self->uniqueLabel($item, $label, $labels, \%allLabels);
		}
		$labels->{$item} = $label;
		$allLabels{$label} = $item;
	  }
	}
#	use Data::Dumper;
#	print Dumper $labels; #, \%allLabels;
  }
  if( not exists($labels->{$refID}) ) {
	$self->warn("no label for $refID!"); return "<<no label for $refID>>";
  }
# print "$refID -> $labels->{$refID}\n";
  return $labels->{$refID};
}

sub formatLabel {
#
# return the label (cite key) for this reference
# can be overwritten by subclasses
# to implement more sophisticated styles
# the default implementation is rather simple ...
#
  my ($self, $refID, $options) = @_;
  return $refID;
}

sub formatSeparators {
  my ($self, $refField, $options) = @_;
  return $refField;
}

sub formatField {
#
# allow to change format of the field,
# e.g. add [...], or replace multi-reference separator etc.
#
# can be overwritten by subclasses
# to implement more sophisticated styles
# the default implementation is rather simple ...
#
  my ($self, $refField, $options) = @_;
  return "[$refField]";
}


#
#
# helper methods
#
#

sub uniqueLabel {
#
# generate a unique label from $label
#
	my ($self, $item, $label, $labels, $allLabels) = @_;
	my $postfixes = $self->{'uniqueLabelPostfixes'};
	$self->logMessage("generate unique label for $item ($label), conflict with $allLabels->{$label}");

	# is this the first collision? (and do we have a year somewhere?)
	if( $label =~ s/([a-z])$// ) {
		# there is a latter already appended -> inc. it
		my $postfix = chr(ord($1) + 1);
		$label .= $postfix;
		$postfixes->{$item} = $postfix;
		return $label;
	}

	# this is the first collision => we have to append 'a' to the
	# previous label as well! (but don't remove it from allLabels!)

	# get the item that we have a collision with
	my $other = $allLabels->{$label};
	$labels->{$other} = "${label}a";
	$allLabels->{"${label}a"} = $label;
	$label .= 'b';
	$postfixes->{$other} = 'a';
	$postfixes->{$item} = 'b';
	return $label;
}


sub postfix {
	my ($self, $refID) = @_;
	return $self->{'uniqueLabelPostfixes'}->{$refID} || '';
}


1;

#
# $Log: LabelStyle.pm,v $
# Revision 1.6  2003/09/30 14:35:12  tandler
# useBraces option for Label styles, not really nicely implemented, i.e. should be changed ...
#
# Revision 1.5  2003/09/23 11:40:08  tandler
# new label-style option :noparens
# use Biblio::Util's xname mode in splitname
#
# Revision 1.4  2002/11/03 22:14:36  peter
# support postfix for unique labels
#
# Revision 1.3  2002/10/11 10:14:29  peter
# unchanged
#
# Revision 1.2  2002/08/22 10:40:21  peter
# - fix option "unique"
#
# Revision 1.1  2002/03/27 10:00:50  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#