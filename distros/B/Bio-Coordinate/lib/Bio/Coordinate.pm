use strict;
use warnings;
package Bio::Coordinate;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Coordinate::VERSION = '1.007001';
# ABSTRACT: Modules for working with biological coordinates
# AUTHOR:   Heikki Lehvaslaiho <heikki@bioperl.org>
# OWNER:    Heikki Lehvaslaiho
# LICENSE:  Perl_5
# CONTRIBUTOR: Ewan Birney <birney@ebi.ac.uk>


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Coordinate - Modules for working with biological coordinates

=head1 VERSION

version 1.007001

=head1 SYNOPSIS

  # create Bio::Coordinate::Pairs or other Bio::Coordinate::MapperIs somehow
  $pair1; $pair2;

  # add them into a Collection
  $collection = Bio::Coordinate::Collection->new;
  $collection->add_mapper($pair1);
  $collection->add_mapper($pair2);

  # create a position and map it
  $pos = Bio::Location::Simple->new (-start => 5, -end => 9 );
  $res = $collection->map($pos);
  $res->match->start == 1;
  $res->match->end == 5;

  # if mapping is many to one (*>1) or many-to-many (*>*)
  # you have to give seq_id not get unrelevant entries
  $pos = Bio::Location::Simple->new
      (-start => 5, -end => 9 -seq_id=>'clone1');

=head1 DESCRIPTION

Bio::Coordinate classes are used for working with various biological
coordinate systems.  See L<Bio::Coordinate::Collection> and
L<Bio::Collection::Pair> for examples.

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/%%7Bdist%7D

=head1 AUTHOR

Heikki Lehvaslaiho <heikki@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) by Heikki Lehvaslaiho.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
