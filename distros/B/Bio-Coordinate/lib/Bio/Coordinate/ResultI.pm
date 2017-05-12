package Bio::Coordinate::ResultI;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Coordinate::ResultI::VERSION = '1.007001';
use utf8;
use strict;
use warnings;
use parent qw(Bio::LocationI);

# ABSTRACT: Interface to identify coordinate mapper results.
# AUTHOR:   Heikki Lehvaslaiho <heikki@bioperl.org>
# OWNER:    Heikki Lehvaslaiho
# LICENSE:  Perl_5


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Coordinate::ResultI - Interface to identify coordinate mapper results.

=head1 VERSION

version 1.007001

=head1 SYNOPSIS

  # not to be used directly

=head1 DESCRIPTION

ResultI identifies Bio::LocationIs returned by
Bio::Coordinate::MapperI implementing classes from other locations.

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
