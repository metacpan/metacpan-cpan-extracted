package Catmandu::VIAF::API;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::VIAF::API::ID;
use Catmandu::VIAF::API::Query;
use Catmandu::VIAF::API::Extract;

has term          => (is => 'ro', required => 1);
has lang          => (is => 'ro', default => 'nl-NL');
has fallback_lang => (is => 'ro', default => 'en-US');

sub search {
    my $self = shift;
    my $query = sprintf('local.mainHeadingEl = "%s" and local.personalNames = "%s"', $self->term, $self->term);
    my $api_q = Catmandu::VIAF::API::Query->new(query => $query, lang => $self->lang, fallback_lang => $self->fallback_lang);
    my $results = [];
    foreach my $result (@{$api_q->results}) {
        my $e = Catmandu::VIAF::API::Extract->new(
            api_response  => $result,
            lang          => $self->lang,
            fallback_lang => $self->fallback_lang
        );
        push @{$results}, $e->single();
    }
    return $results;
}

sub match {
    my $self = shift;
    my $query = sprintf('local.mainHeadingEl exact "%s" and local.personalNames = "%s"', $self->term, $self->term);
    my $api_q = Catmandu::VIAF::API::Query->new(query => $query, lang => $self->lang, fallback_lang => $self->fallback_lang);
    if (scalar @{$api_q->results} >= 1) {
        my $result = shift @{$api_q->results};
        my $e = Catmandu::VIAF::API::Extract->new(
                api_response  => $result,
                lang          => $self->lang,
                fallback_lang => $self->fallback_lang
        );
        return $e->single();
    } else {
        return {};
    }
}

sub id {
    my $self = shift;
    my $api_id = Catmandu::VIAF::API::ID->new(viafid => $self->term);
    my $e = Catmandu::VIAF::API::Extract->new(
        api_response  => $api_id->result,
        lang          => $self->lang,
        fallback_lang => $self->fallback_lang
    );
    return $e->single();
}

1;
__END__