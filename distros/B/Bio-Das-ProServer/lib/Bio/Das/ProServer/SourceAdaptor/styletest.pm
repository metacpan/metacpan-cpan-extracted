#########
# Author:        jws
# Maintainer:    jws
# Created:       2005-04-20
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# $Id: styletest.pm 687 2010-11-02 11:37:11Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/styletest.pm $
#
# lots of magic numbers in this package:
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
#
package Bio::Das::ProServer::SourceAdaptor::styletest;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION  = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub capabilities {
  return {
	  features   => '1.0',
	  stylesheet => '1.0',
	 };
}

sub length { ## no critic
  return 1;
}

sub build_features {
  my ($self, $opts) = @_;
  my $seg     = $opts->{segment};
  my $start   = $opts->{start};
  my $end     = $opts->{end};
  my @features;

  if(CORE::length($seg) > 2) {
    #########
    # only do this for chromosomes
    #
    return;
  }

  my $stylesheet = $self->das_stylesheet();

  #########
  # This is a quick hack, so we aren't going to do a full XML parsing
  # of the stylesheet tree here.  Just grab out the id from the TYPE lines:
  # e.g. <TYPE id="segdup:direct_mid_vfar">
  #
  my @types;

  for my $ss (split /\n/mxs, $stylesheet) {
    if($ss !~ /<\s*TYPE/mxsi) {
      next;
    }

    my ($trap) = $ss =~ /id\s*=\s*["']{1}([^"']*)["']{1}/mxsi;
    if($trap) {
      push @types, $1;
    }
  }

  for my $type (@types) {
    #########
    # workaround for annoying Bio::Das method forcing type to method:type
    #
    my $method = $type;
    $method    =~ s/:.*//mxs; # throw away everything after :

    #########
    # create a number of features for each type, on each strand:
    #  - overlapping start (by 5% of range)
    #  - 1 bp
    #  - small (5% of range)
    #  - medium-ish (25% of range)
    #  - overlapping end (by 5% of range)
    #
    # All pretty arbitrary, obviously.
    # Adjust the spacing so the features all get a share of the space to
    # try and minimise bumping caused by label overlaps.
    #
    my $range = $end - $start;

    #########
    # generate features on both strands
    #
    for my $ori (qw(+ -)) {

      my $oldend = $start-100;

      #########
      # overlapping start feature - width is 5% of range
      #
      my $newend = $start + ($range * 0.05);

      push @features, {
		       id           => $type,
		       start        => $oldend,
		       end          => $newend,
		       ori          => $ori,
		       type         => $type,
		       typecategory => 'similarity',
		       method       => $method
		      };

      #########
      # add spacer
      #
      $oldend = $newend + ($range * 0.17);

      #########
      # 1 bp feature
      #
      $newend = $oldend + 1;

      push @features, {
		       id           => $type,
		       start        => $oldend,
		       end          => $newend,
		       ori          => $ori,
		       type         => $type,
		       typecategory => 'similarity',
		       method       => $method
		      };

      #########
      # add a bigger spacer
      #
      $oldend = $newend + ($range * 0.22);

      #########
      # small (5% range) feature
      #
      $newend = $oldend + ($range * 0.05);
      push @features, {
		       id           => $type,
		       start        => $oldend,
		       end          => $newend,
		       ori          => $ori,
		       type         => $type,
		       typecategory => 'similarity',
		       method       => $method
		      };

      $oldend = $newend + ($range * 0.16);

      #########
      # medium (25% range) feature
      #
      $newend = $oldend + ($range * 0.25);
      push @features, {
		       id           => $type,
		       start        => $oldend,
		       end          => $newend,
		       ori          => $ori,
		       type         => $type,
		       typecategory => 'similarity',
		       method       => $method
		      };

      $oldend = $newend + ($range * 0.05);

      #########
      # overlapping end
      #
      $newend = $end + 100;
      push @features, {
		       id           => $type,
		       start        => $oldend,
		       end          => $newend,
		       ori          => $ori,
		       type         => $type,
		       typecategory => 'similarity',
		       method       => $method
		      };
    }
  }

  return @features;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::styletest

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

 Test harness for stylesheets.  Retrieves stylesheet, parses out
 feature types, and creates fake features with the correct type for
 each style.

=head1 SUBROUTINES/METHODS

=head2 capabilities

=head2 length

=head2 build_features

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

 Bio::Das::ProServer::SourceAdaptor

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Jim Stalker$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
