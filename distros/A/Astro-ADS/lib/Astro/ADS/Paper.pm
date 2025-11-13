package Astro::ADS::Paper;
$Astro::ADS::Paper::VERSION = '1.92';
use Moo;

use Carp;
use Data::Dumper::Concise;
use Mojo::Base -strict; # do we want -signatures
use PerlX::Maybe;
use Types::Standard qw( Int Str StrMatch ArrayRef HashRef Any ); # InstanceOf ConsumerOf

#declare "Bibcode",
#   was StrMatch[ qr{^\d{4} [\w.&]{5} [\d.]{4} [ELP-Z\d.] [\d.]{4} [A-Z]$}x ];
#   now StrMatch[ qr{^\d{4} [\w.&]{5} [\d.]{4} [AELP-Z\d.] [\d.]{3}[B\d] [A-Z]$}x ];
   # YYYY JJJJJ VVVV M PPPP A (year journal volume type page author)
   # 2006 nucl. ex.. . 1042 S
   # 2005 astro .ph. 1 0346 T

has [qw/id score/] => (
    is       => 'rw',
    isa      => Int->where( '$_ >= 0' ),
);
has bibcode => (
    is  => 'rw',
    isa => StrMatch[ qr{^\d{4}      # year
                (?: [\w.&]{5}       # ( journal
                    [\d.]{4}        #   volume )
                |   [a-z.]{9} )     # ( arxiv )
                [AELP-Z\d.]         # type
                [\d.]{3}[B\d]       # page
                [A-Z]               # author initial
                $}x
           ],
);
# astro-ph hep-ex|th|lat cond-mat gr-qc math-ph nlin physics quant-ph stat
# ph ex th lat mat qc ph 
has title => (
    is       => 'rw',
    isa      => ArrayRef[],
);
has [qw/journal origin object/] => (
    is       => 'rw',
    isa      => Str,
);
has url => (
    is       => 'rw',
    isa      => Str, # Mojo::URL ?
);
has published => (
    is       => 'rw',
    isa      => Str, # qr/Month-Year/
);
has [qw/author aff keyword links_data/] => (
    is      => 'rw',
    isa     => ArrayRef[],
);
has abstract => (
    is      => 'rw',
    isa      => Any, # no idea what this is now
);

sub summary {
    # should this be a one line join or 3 line heredoc?
    my $self = shift;

    return grep { defined }
        $self->bibcode,
        $self->score,
        $self->title,
        ($self->authors ? join('; ', @{$self->authors}) : undef),
        $self->published;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::Paper - A class for holding the document attributes for the results of a Search

=head1 VERSION

version 1.92

=head1 SYNOPSIS

    my $result = $search->query();
    say $_->title grep { $_->year > 2010 } for $result->get_papers();

=head1 DESCRIPTION

This class is used to contain the individual results from your searches.
Please note that it only contains the attributes fetched from the search,
not the whole ADS record for the paper.

=head2 Notes

In searches, the "=" sign turns off the synonym expansion feature
available with the author and title fields.

=head2 Bibcodes

This class has a regex for bibcodes!

Coding that regex has shown that bibcodes fields are overloaded in ways not
documented. I did not know that 'A' is an acceptable bibcode field for publication
type, which maybe short for Abstract.

arXiv papers don't have a Volume, so they overflow into that section

=head2 Follow up queries

Methods available in Astro::ADS v1 for fetching references and citations are
now accessed via the Links service (which will be on the development Roadmap).

=head2 Allowed fields

Allowed: abstract ┃ ack ┃ aff ┃ aff_id ┃ alternate_bibcode ┃ alternate_title ┃ arxiv_class ┃ author ┃ author_count ┃ author_norm ┃ bibcode ┃ bibgroup ┃ bibstem ┃ citation ┃ citation_count ┃ cite_read_boost ┃ classic_factor ┃ comment ┃ copyright ┃ data ┃ database ┃ date ┃ doctype ┃ doi ┃ eid ┃ entdate ┃ entry_date ┃ esources ┃ facility ┃ first_author ┃ first_author_norm ┃ grant ┃ grant_agencies ┃ grant_id ┃ id ┃ identifier ┃ indexstamp ┃ inst ┃ isbn ┃ issn ┃ issue ┃ keyword ┃ keyword_norm ┃ keyword_schema ┃ lang ┃ links_data ┃ nedid ┃ nedtype ┃ orcid_pub ┃ orcid_other ┃ orcid_user ┃ page ┃ page_count ┃ page_range ┃ property ┃ pub ┃ pub_raw ┃ pubdate ┃ pubnote ┃ read_count ┃ reference ┃ simbid ┃ title ┃ vizier ┃ volume ┃ year

Given this list is 81 fields, it doesn't make sense to create that many empty attributes.

The full list is at https://ui.adsabs.harvard.edu/help/search/comprehensive-solr-term-list

=head1 TODO

v1 had the following methods
* references
* citations
* alsoread
* tableofcontents

all of which grepped $self->links for either REFERENCES, CITATIONS, AR or TOC

These are returned in the links_data field, but we should be using the Links service to get this data

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
