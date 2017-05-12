# --*-Perl-*--
# $Id: Name.pm 11 2004-11-22 23:56:20Z tandler $
#

package PBib::LabelStyle::Name;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 11 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use base qw(PBib::LabelStyle);

# used modules
use Biblio::Util;

# module variables
#use vars qw(mmmm);

#
# label & field options
#

sub etalItalics { my ($self, $options) = @_;
# how many authors until I use the "et al." style?
  return $self->fieldOption("etal-italics", $options); # || 1;
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
  my $label = $self->PBib::LabelStyle::text($refID, $options);
  my $inline = $self->{'inlineLabels'}->{$refID};
  my $postfix = $self->{'labelPostfixes'}->{$refID};
  if( $self->suppressAuthor($options) ) {
    return "($postfix)";
  }
  if( $self->inlineField($options) ) {
    return "$inline ($postfix)";
  }
  return $label;
}


sub formatLabel {
#
# return the label (cite key) for this reference
# can be overwritten by subclasses
# to implement more sophisticated styles
# the default implementation is rather simple ...
#
	my ($self, $refID, $options) = @_;
	$self->setRefID($refID);
	my $inlineLabels = $self->{'inlineLabels'};
	$inlineLabels = $self->{'inlineLabels'} = {} unless defined($inlineLabels);
	my $labelPostfixes = $self->{'labelPostfixes'};
	$labelPostfixes = $self->{'labelPostfixes'} = {} unless defined($labelPostfixes);
	my $label = $self->formatInlineLabel($refID, $options);
	my $postfix = $self->formatLabelPostfix($refID, $options);
	$inlineLabels->{$refID} = $label;
	$labelPostfixes->{$refID} = $postfix;
	if( $postfix ) {
		$label = "$label, $postfix";
	}
	return $label;
}

sub formatSeparators {
  my ($self, $refField, $options) = @_;
  # replace comma as reference separator with semicolon
  $refField =~ s/,\s*\[/; \[/g;
  return $refField;
}
sub formatField {
	my ($self, $refField, $options) = @_;
	return "[$refField]" if $self->useBraces($options);
	### useBraces is somehow quite limited and doesn't work
	### with inline! (it can ignore suppressAuthor and noParens)
	return $refField if $self->suppressAuthor($options);
	return $refField if $self->inlineField($options);
	return $refField if $self->noParens($options);
	return "($refField)";
}


sub formatInlineLabel {
	my ($self, $refID, $options) = @_;
	
	# first check if there is a Key defined
	my $label = $self->entry('Key');
	return $label if $label;
	
	# next, check for Authors or Editors
	my $names = $self->entry('Authors') || $self->entry('Editors');
	if( $names ) {
		my $itemStyle = $self->itemStyle();
		my @name_array = $itemStyle->split_names($names, 'xname');
		#	print Dumper $names, \@name_array;
		
		# how many authors do we have? use et al.?
		if( scalar(@name_array) >= $self->etalNumber() ) {
			# there are too many authors, use "first et al."
			$label = $itemStyle->last_name($name_array[0]) . " et al.";
		} elsif( $name_array[-1] eq "et al." ) {
			# if the last author is "et al.", only use the first
			$label = $itemStyle->last_name($name_array[0]) . " et al.";
		} else {
			$label = Biblio::Util::join_and_list(map($itemStyle->last_name($_), @name_array));
		}
		
		# pretty print "et al."
		if( $self->etalItalics() ) {
			$label =~ s/et al./ $self->outDoc()->italic('et al.') /eg;
		}
	}
	return $label if $label;
	
	# still no label -> try Organization etc.
	$label = $self->entry('Organization')
		|| $self->entry('Instritution')
		|| $self->entry('School')
		|| $self->entry('Project');
	return $label if $label;

	# default: use CiteKey (not nice) ...
	$self->warn("use CiteKey as label for $refID");
	return $refID;
}

sub formatLabelPostfix {
  my ($self, $refID, $options) = @_;
  my $label = $self->entry('Year');
  return $label;
}



1;

#
# $Log: Name.pm,v $
# Revision 1.8  2003/09/30 14:35:12  tandler
# useBraces option for Label styles, not really nicely implemented, i.e. should be changed ...
#
# Revision 1.7  2003/09/23 11:40:08  tandler
# new label-style option :noparens
# use Biblio::Util's xname mode in splitname
#
# Revision 1.6  2003/06/12 22:11:26  tandler
# improved handling of the "Key" field
#
# Revision 1.5  2002/11/05 18:31:20  peter
# suppressAthor option -- temporary fix in formatField
#
# Revision 1.4  2002/11/03 22:16:43  peter
# suppress author option
#
# Revision 1.3  2002/09/23 11:07:29  peter
# et al. set in italics
#
# Revision 1.2  2002/03/27 10:23:15  Diss
# small fixes ...
#
# Revision 1.1  2002/03/27 10:00:51  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#