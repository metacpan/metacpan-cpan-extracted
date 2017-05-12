package Bio::Coordinate::Result::Gap;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Coordinate::Result::Gap::VERSION = '1.007001';
use utf8;
use strict;
use warnings;
use parent qw(Bio::Location::Simple Bio::Coordinate::ResultI);

# ABSTRACT: Another name for L<Bio::Location::Simple>.
# AUTHOR:   Heikki Lehvaslaiho <heikki@bioperl.org>
# OWNER:    Heikki Lehvaslaiho
# LICENSE:  Perl_5


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Coordinate::Result::Gap - Another name for L<Bio::Location::Simple>.

=head1 VERSION

version 1.007001

=head1 SYNOPSIS

  $loc = Bio::Coordinate::Result::Gap->new(-start=>10,
                                          -end=>30,
                                          -strand=>1);

=head1 DESCRIPTION

This is a location object for coordinate mapping results.

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
