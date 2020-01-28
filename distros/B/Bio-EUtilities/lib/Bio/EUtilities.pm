package Bio::EUtilities;
$Bio::EUtilities::VERSION = '1.76';
use strict;
use warnings;

1;

# ABSTRACT: BioPerl low-level API for retrieving and storing data from NCBI eUtils
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    Chris Fields
# LICENSE:  Perl_5

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::EUtilities - BioPerl low-level API for retrieving and storing data from NCBI eUtils

=head1 VERSION

version 1.76

=head1 SYNOPSIS

See L<Bio::DB::EUtilities> for example usage with NCBI.

=head1 DESCRIPTION

This distribution encompasses a low-level API for interacting with (and storing)
information from) NCBI's eUtils interface.  See L<Bio::DB::EUtilities> for the
query API to retrieve data from NCBI, and L<Bio::Tools::EUtilities> for the general
class storage system. Note this may change to utilize the XML schema for each class at
some point, though we will attempt to retain current functionality for backward
compatibility unless this becomes problematic.

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org               - General discussion
  https://bioperl.org/Support.html    - About the mailing lists

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

  https://github.com/bioperl/bio-eutilities/issues

=head1 AUTHOR

Chris Fields <cjfields@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) by Chris Fields.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
