package Bio::Biblio::IO::pubmed2ref;
BEGIN {
  $Bio::Biblio::IO::pubmed2ref::AUTHORITY = 'cpan:BIOPERLML';
}
{
  $Bio::Biblio::IO::pubmed2ref::VERSION = '1.70';
}
use utf8;
use strict;
use warnings;

use parent qw(Bio::Biblio::IO::medline2ref);

# ABSTRACT: a converter of a raw hash to PUBMED citations
# AUTHOR:   Martin Senger <senger@ebi.ac.uk>
# OWNER:    2002 European Bioinformatics Institute
# LICENSE:  Perl_5


# ---------------------------------------------------------------------
#
#   Here is the core...
#
# ---------------------------------------------------------------------

sub _load_instance {
    my ($self, $source) = @_;

    my $result;
    my $article = $$source{'article'};
    if (defined $article) {
        if (defined $$article{'journal'}) {
            $result = $self->_new_instance ('Bio::Biblio::PubmedJournalArticle');
            $result->type ('JournalArticle');
        } elsif (defined $$article{'book'}) {
            $result = $self->_new_instance ('Bio::Biblio::PubmedBookArticle');
            $result->type ('BookArticle');
        } else {
            $result->type ('PubmedArticle');
        }
    }
    $result = $self->_new_instance ('Bio::Biblio::Ref') unless defined $result;
    return $result;
}


sub convert {
    my ($self, $source) = @_;
    my $result = $self->SUPER::convert ($source->{'Citation'});

    # here we do PUBMED's specific stuff
    my $pubmed_data = $$source{'PubmedData'};
    if (defined $pubmed_data) {

        # ... just take it (perhaps rename it)
        $result->pubmed_status ($$pubmed_data{'publicationStatus'}) if defined $$pubmed_data{'publicationStatus'};
        $result->pubmed_provider_id ($$pubmed_data{'providerId'}) if defined $$pubmed_data{'providerId'};
        $result->pubmed_article_id_list ($$pubmed_data{'pubmedArticleIds'}) if defined $$pubmed_data{'pubmedArticleIds'};
        $result->pubmed_url_list ($$pubmed_data{'pubmedURLs'}) if defined $$pubmed_data{'pubmedURLs'};

        # ... put all dates from all 'histories' into one array
        if (defined $$pubmed_data{'histories'}) {
            my @history_list;
            foreach my $history ( @{ $$pubmed_data{'histories'} } ) {
                my $ra_pub_dates = $$history{'pubDates'};
                foreach my $pub_date ( @{ $ra_pub_dates } ) {
                    my %history = ();
                    my $converted_date = &Bio::Biblio::IO::medline2ref::_convert_date ($pub_date);
                    $history{'date'} = $converted_date if defined $converted_date;
                    $history{'pub_status'} = $$pub_date{'pubStatus'} if defined $$pub_date{'pubStatus'};
                    push (@history_list, \%history);
                }
            }
            $result->pubmed_history_list (\@history_list);
        }
    }

    # Done!
    return $result;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::Biblio::IO::pubmed2ref - a converter of a raw hash to PUBMED citations

=head1 VERSION

version 1.70

=head1 SYNOPSIS

 # to be written

=head1 DESCRIPTION

 # to be written

=head1 METHODS

=head2 convert

=head1 INTERNAL METHODS

=head2 _load_instance

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

