# --*-Perl-*--
# $Id: BookmarkLink.pm 11 2004-11-22 23:56:20Z tandler $
#

package PBib::ReferenceStyle::BookmarkLink;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION); q$Revision: 11 $ =~ /: (\d+)/; my ($major, $minor) = (1, $1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::ReferenceStyle;
use base qw(PBib::ReferenceStyle);

# used modules
#use ZZZZ;

# module variables
#use vars qw(mmmm);

# format options
#   'style' => 'field' || 'plain'
#   'flags' => string
#	for 'field' style: flags for Word { REF ... } field, e.g. "rh" will become \r \h
#   'prefix' => string used as prefix for bookmark name, per default empty
#   'postfix' => string used as postfix for bookmark name, per default empty


#
#
# methods
#
#

sub formatReference {
#
# return the replacement text for one reference
# can be overwritten by subclasses
# to implement more sophisticated styles
#
  my ($self, $refID, $options) = @_;
  my $bookmark = $self->bookmarkID($refID);
#  print STDERR "\tID: $refID\n";
  my $label = $self->formatLabel($refID, $options);
#  print "format ref (bkmk link): $label, $bookmark --> ", $self->outDoc(), "\n";
  return $self->outDoc()->bookmarkLink("$label", $bookmark);
}

sub bookmarkID {
# strip all non-bookmark chars, and add a prefix "r"
  my ($self, $id) = @_;
  my $prefix = $self->option('prefix') || "";
  my $postfix = $self->option('postfix') || "";
  $id = "$prefix$id$postfix";
  return $self->outDoc()->quoteFieldId($id);
}


1;

#
# $Log: BookmarkLink.pm,v $
# Revision 1.2  2002/08/08 08:27:41  Diss
# - removed debug msg ...
#
# Revision 1.1  2002/03/27 10:00:52  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#