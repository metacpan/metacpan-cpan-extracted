# --*-Perl-*--
# $Id: CiteKey.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::LabelStyle::CiteKey;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::LabelStyle;
our @ISA = qw(PBib::LabelStyle);

# used modules
#use ZZZZ;

# module variables
#use vars qw(mmmm);

#
# label & field options
#

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
  return $refID;
}


sub formatLabel {
#
# return the label (cite key) for this reference
#
  my ($self, $refID, $options) = @_;
  return $refID;
}

sub formatField {
  my ($self, $refField, $options) = @_;
  return "[$refField]";
}

1;

#
# $Log: CiteKey.pm,v $
# Revision 1.1  2002/10/11 10:16:17  peter
# use the CiteKey as label
#
#
# based somehow on Name.pm, v1.2
#