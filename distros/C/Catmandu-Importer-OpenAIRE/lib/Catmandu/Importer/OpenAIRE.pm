package Catmandu::Importer::OpenAIRE;

use LWP::Simple;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Any::URI::Escape;
use JSON;
use Moo;
use feature 'state';

our $VERSION = '0.02';

our @BASE_PARAM = qw(size sortBy hasECFunding hasWTFunding funder fundingStream FP7scientificArea keywords doi orcid fromDateAccepted toDateAccepted title author openaireProviderID openaireProjectID hasProject projectID FP7ProjectID OA country instancetype originalId sdg fos openairePublicationID openaireDatasetID openaireSoftwareID openaireOtherID grantID name acronym callID startYear endYear participantCountries participantAcronyms);

with 'Catmandu::Importer';

has url                 => (is => 'ro' , default => sub { 'http://api.openaire.eu/search/publications' });
has size                => (is => 'ro');
has sortBy              => (is => 'ro');
has hasECFunding        => (is => 'ro');
has hasWTFunding        => (is => 'ro');
has funder              => (is => 'ro');
has fundingStream       => (is => 'ro');
has FP7scientificArea   => (is => 'ro');
has keywords            => (is => 'ro');
has doi                 => (is => 'ro');
has orcid               => (is => 'ro');
has fromDateAccepted    => (is => 'ro');
has toDateAccepted      => (is => 'ro');
has title               => (is => 'ro');
has author              => (is => 'ro');
has openaireProviderID  => (is => 'ro');
has openaireProjectID   => (is => 'ro');
has hasProject          => (is => 'ro');
has projectID           => (is => 'ro');
has FP7ProjectID        => (is => 'ro');
has OA                  => (is => 'ro');
has country             => (is => 'ro');
has instancetype        => (is => 'ro');
has originalId          => (is => 'ro');
has sdg                 => (is => 'ro');
has fos                 => (is => 'ro');
has openairePublicationID => (is => 'ro');
has openaireDatasetID   => (is => 'ro'); 
has openaireSoftwareID  => (is => 'ro'); 
has openaireOtherID     => (is => 'ro'); 
has grantID             => (is => 'ro'); 
has name                => (is => 'ro'); 
has acronym             => (is => 'ro'); 
has callID              => (is => 'ro'); 
has startYear           => (is => 'ro'); 
has endYear             => (is => 'ro'); 
has participantCountries => (is => 'ro');
has participantAcronyms  => (is => 'ro');

with 'Catmandu::Importer';

sub generator {
    my ($self) = @_;
    sub {
        state $page = 1;
        state $records = undef;

        if ($records && @$records) {
            my $l = int(@$records);
           # warn "still $l records";
        }
        else {
            $records = $self->fetchRecords($page);
            $page++;
            return undef unless defined($records);
        } 

        return shift(@$records);
    };
}

sub fetchRecords {
    my ($self,$page) = @_;

    my @params = (
        "format=json",
        "page=$page"
    );

    for my $param (@BASE_PARAM) {
        if (defined $self->{$param}) {
            push @params , "$param=" . uri_escape($self->{$param});
        }
    }

    my $url  = sprintf "%s?%s", $self->url , join("&",@params);

    my $result;

    eval {
        my $json = get($url);
        my $data = decode_json($json);

        if ($data && 
                $data->{response} && 
                $data->{response}->{results} &&
                $data->{response}->{results}->{result}) {
            $result =  $data->{response}->{results}->{result}; 
        }
        else {
            $result = undef;
        }
    };
    if ($@) {
        warn "Oh no! [$@] for $url";
    }
    return $result;
}

1;

__END__

=head1 NAME

Catmandu::Importer::OpenAIRE - Package that queries the OpenAIRE Graph

=head1 SYNPOSIS

   # From the command line

   # Harvest some data
   catmandu convert OpenAIRE to YAML

   # Harvest some data from a different endpoint
   catmandu convert OpenAIRE --url http://api.openaire.eu/search/datasets to YAML

=head1 DESCRIPTION

See L<https://graph.openaire.eu/develop/api.html> for the OpenAIRE query parameters

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE

Copyright 2023- Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
