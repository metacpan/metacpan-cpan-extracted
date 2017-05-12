package Catmandu::VIAF::API::Extract;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

has api_response  => (is => 'ro', required => 1);
has lang          => (is => 'ro', default => 'nl-NL');
has fallback_lang => (is => 'ro', default => 'en-US');

sub single {
    my $self = shift;
    my $descriptions = $self->api_response->{'rdf:Description'};
    my $person;
    foreach my $description (@{$descriptions}) {
        if ($self->is_person($description->{'rdf:type'}) == 1) {
            $person = $description;
            last;
        }
    }
    if (ref($person) ne "HASH") {
        return {};
    }
    return {
        'skos:prefLabel' => $self->name($person),
        'dcterms:identifier' => $person->{'dcterms:identifier'}->{'content'},
        'schema:description' => $person->{'schema:description'},
        'schema:birthDate' => $person->{'schema:birthDate'},
        'schema:deathDate' => $person->{'schema:deathDate'},
        'guid' => $person->{'rdf:about'}
    };
}

sub pref_label {
    my ($self, $description) = @_;
    my $prefLabel;
    my $prefLabel_fallback;
    my $prefLabel_nolang;
    if (ref($description->{'skos:prefLabel'}) ne 'ARRAY') {
        $description->{'skos:prefLabel'} = [$description->{'skos:prefLabel'}];
    }
    foreach my $label (@{$description->{'skos:prefLabel'}}) {
        if (exists($label->{'xml:lang'})) {
            if ($label->{'xml:lang'} eq $self->lang) {
                $prefLabel = $label->{'content'};
                last;
            }
            if ($label->{'xml:lang'} eq $self->fallback_lang) {
                $prefLabel_fallback = $label->{'content'};
            }
        } else {
            $prefLabel_nolang = $label->{'content'};
        }
    }

    if (defined($prefLabel)) {
        return $prefLabel;
    } elsif (defined($prefLabel_fallback)) {
        return $prefLabel_fallback;
    } else {
        # No guarantee that this isn't undefined
        return $prefLabel_nolang;
    }
}

sub schema_name {
    my ($self, $description) = @_;
    my $name;
    my $name_fallback;
    my $name_nolang;
    if (ref($description->{'schema:name'}) ne 'ARRAY') {
        $description->{'schema:name'} = [$description->{'schema:name'}];
    }
    foreach my $s_name (@{$description->{'schema:name'}}) {
        if (exists($s_name->{'xml:lang'})) {
            if ($s_name->{'xml:lang'} eq $self->lang) {
                $name = $s_name->{'content'};
                last;
            }
            if ($s_name->{'xml:lang'} eq $self->fallback_lang) {
                $name_fallback = $s_name->{'content'};
            }
        } else {
            $name_nolang = $s_name->{'content'};
        }
    }
    if (defined($name)) {
        return $name;
    } elsif (defined($name_fallback)) {
        return $name_fallback;
    } else {
        return $name_nolang;
    }
}

sub name {
    my ($self, $description) = @_;
    my $name = $self->pref_label($description);
    if (!defined($name)) {
        $name = $self->schema_name($description);
    }
    return $name;
}

sub is_person {
    my ($self, $rdf_types) = @_;
    if (ref($rdf_types) ne 'ARRAY') {
        $rdf_types = [$rdf_types];
    }
    foreach my $rdf_type (@{$rdf_types}) {
        if ($rdf_type->{'rdf:resource'} eq 'http://schema.org/Person') {
            return 1;
            last;
        }
    }
    return 0;
}

1;
__END__
