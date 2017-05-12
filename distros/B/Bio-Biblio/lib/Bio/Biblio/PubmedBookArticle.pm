package Bio::Biblio::PubmedBookArticle;
BEGIN {
  $Bio::Biblio::PubmedBookArticle::AUTHORITY = 'cpan:BIOPERLML';
}
{
  $Bio::Biblio::PubmedBookArticle::VERSION = '1.70';
}
use utf8;
use strict;
use warnings;

use parent qw(Bio::Biblio::PubmedArticle Bio::Biblio::MedlineBookArticle);

# ABSTRACT: representation of a PUBMED book article
# AUTHOR:   Martin Senger <senger@ebi.ac.uk>
# OWNER:    2002 European Bioinformatics Institute
# LICENSE:  Perl_5


our @ISA;
#
# a closure with a list of allowed attribute names (these names
# correspond with the allowed 'get' and 'set' methods); each name also
# keep what type the attribute should be (use 'undef' if it is a
# simple scalar)
#
{
    my %_allowed =
        (
         );

    # return 1 if $attr is allowed to be set/get in this class
    sub _accessible {
        my ($self, $attr) = @_;
        return 1 if exists $_allowed{$attr};
        foreach my $parent (@ISA) {
            return 1 if $parent->_accessible ($attr);
        }
    }

    # return an expected type of given $attr
    sub _attr_type {
        my ($self, $attr) = @_;
        if (exists $_allowed{$attr}) {
            return $_allowed{$attr};
        } else {
            foreach my $parent (@ISA) {
                if ($parent->_accessible ($attr)) {
                    return $parent->_attr_type ($attr);
                }
            }
        }
        return 'unknown';
    }
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::Biblio::PubmedBookArticle - representation of a PUBMED book article

=head1 VERSION

version 1.70

=head1 SYNOPSIS

    $obj = Bio::Biblio::PubmedBookArticle->new
                  (-title => 'Still getting started'.
                   -book => Bio::Biblio::MedlineBook->new());
    # note that there is no specialised class PubmedBook

  #--- OR ---

    $obj = Bio::Biblio::PubmedBookArticle->new();
    $obj->title ('Still getting started');

=head1 DESCRIPTION

A storage object for a PUBMED book article.
See its place in the class hierarchy in
http://www.ebi.ac.uk/~senger/openbqs/images/bibobjects_perl.gif

=head2 Attributes

There are no specific attributes in this class
(however, you can set and get all attributes defined in the parent classes).

=head1 SEE ALSO

=over 4

=item *

OpenBQS home page

http://www.ebi.ac.uk/~senger/openbqs/

=item *

Comments to the Perl client

http://www.ebi.ac.uk/~senger/openbqs/Client_perl.html

=back

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

  https://redmine.open-bio.org/projects/bioperl/

=head1 LEGAL

=head2 Authors

Martin Senger <senger@ebi.ac.uk>

=head2 Copyright and License

This software is Copyright (c) by 2002 European Bioinformatics Institute and released under the license of the same terms as the perl 5 programming language system itself

=cut

