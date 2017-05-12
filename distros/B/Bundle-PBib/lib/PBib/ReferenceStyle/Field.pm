# --*-Perl-*--
# $Id: Field.pm 10 2004-11-02 22:14:09Z tandler $
#
#
#
##### is this class obsolete??????
#

package PBib::ReferenceStyle::Field;
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
use PBib::ReferenceStyle::BookmarkLink;
use base qw(PBib::ReferenceStyle::BookmarkLink);

# format options
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
  my $flags = $self->option('flags') || "rh";
  $flags =~ s/([a-z])/\\\\$1 /gi;
#  print STDERR "\tID: $refID\n";
  my $label = $self->formatLabel($refID, $options);
  return $self->outDoc()->field("$label", " REF $bookmark $flags");
}


1;

#
# $Log: Field.pm,v $
# Revision 1.2  2002/03/27 10:00:52  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.1  2002/03/18 11:15:50  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#