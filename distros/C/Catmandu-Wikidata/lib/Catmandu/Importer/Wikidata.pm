package Catmandu::Importer::Wikidata;
#ABSTRACT: Import from Wikidata
our $VERSION = '0.06'; #VERSION
use Catmandu::Sane;
use Moo;
use URI::Template;

extends 'Catmandu::Importer::getJSON';

has api => ( 
    is => 'ro', 
    default => sub { 'http://www.wikidata.org/w/api.php' } 
);

has '+url' => (
    is => 'ro',
    lazy => 1,
    builder => sub { 
        URI::Template->new(
            $_[0]->api 
            . '?action=wbgetentities&format=json{&ids}{&sites}{&titles}'
        );
    }
); 

has '+from' => ( 
    is => 'ro', 
    lazy => 1,
    builder => \&_build_from,
);

has ids => (
    is  => 'ro',
    coerce => sub { [ split /[,| ]/, $_[0] ] }
);

has site => (
    is => 'ro',
    default => sub { 'enwiki' },
    trigger => sub {
        my ($self,$site) = @_;
        die "invalid site $site" if $site !~ /^[a-z]+([_-][a-z])*$/;
        $site =~ s/-/_/g;
        return $site;
    }
);

has title => (
    is => 'ro',
);

sub _build_from {
    my ($self) = @_;

    my $vars;

    if ($self->ids) {
        my @ids = map {
            $_ =~ /^[QP][0-9]+$/i or die "invalid wikidata id $_\n";
            uc($_);
        } @{$self->ids};
        $vars = { ids => join('|', @ids) };
    } elsif(defined $self->title) {
        my ($site, $title);
        if ($self->title =~ /^([a-z]+([_-][a-z])*):(.+)$/) {
            ($site, $title) = ($1,$3);
        } else {
            ($site, $title) = ($self->site,$self->title);
        }
        die "invalid site $site" if $site !~ /^[a-z]+([_-][a-z])*$/;
        $site =~ s/-/_/g;
        $vars = { sites => $site, titles => $title };
    }

    return ($vars ? $self->url->process($vars) : undef);
}

sub request_hook {
    my ($self, $line) = @_;

    if ($line =~ /^[PQ][0-9]+$/i) {
        return { ids => uc($line) };
    } elsif ($line =~ /^([a-z]+([_-][a-z])*):(.+)$/) {
        my ($site, $title) = ($1,$3);
        $site =~ s/-/_/g;
        return { sites => $site, titles => $title };
    } else {
        return { sites => $self->site, titles => $line };
    }

    return;
}

sub response_hook {
    my ($self, $data) = @_;
    return unless ref $data and ref $data->{entities} eq 'HASH';
    return [ 
        map {
            $_->{missing} = 1 if exists $_->{missing};
            $_;
        } grep { ref $_ eq 'HASH'; }
        values %{$data->{entities}} 
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Importer::Wikidata - Import from Wikidata

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    catmandu convert Wikidata --ids Q1,P227
    catmandu convert Wikidata --site dewiki --title Wahnsinn

    echo Q1 | catmandu convert Wikidata
    echo Wahnsinn | catmandu convert Wikidata --site dewiki
    echo dewiki:Wahnsinn | catmandu convert Wikidata

    echo Q1 | catmandu convert Wikidata --fix 'retain_field("labels")'

=head1 DESCRIPTION

This L<Catmandu::Importer> queries Wikidata for entities, given by their
Wikidata identifier (C<Q...>, C<P...>) or by a title in some know Wikidata
site, such as the English Wikipedia (C<enwiki>). The entities are either
specified as options (C<ids>, C<site>, and/pr C<title>) or as line-separated
input values. By default, the raw JSON structure of each Wikidata entity is
returned one by one. Entities not found are returned with the C<missing>
property set to C<1> like this:

    { "id": "Q7", "missing": "1" }

To further process the JSON structure L<Catmandu::Wikidata> contains several
Catmandu fixes, e.g. to only retain a selected language.

=head1 CONFIGURATION

This importer extends L<Catmandu::Importer::getJSON>, so it can be configured
with options C<agent>, C<timeout>, C<headers>, C<proxy>, and C<dry>. Additional
options include:

=over

=item api

Wikidata API base URL. Default is C<http://www.wikidata.org/w/api.php>.

=item ids

A list of Wikidata entitiy/property ids, such as C<Q42> and C<P19>. Use
comma, vertical bar, or space as separator. Read from input stream if no
ids, nor titles are specified.

=item site

Wiki site key for referring to Wikidata entities by title. Default is
C<enwiki> for English Wikipedia. A list of supported site keys can be
queried as part of
L<https://www.wikidata.org/w/api.php?action=paraminfo&modules=wbgetentities>
(unless L<https://bugzilla.wikimedia.org/show_bug.cgi?id=58200> is fixed).

=item title

Title of a page for referring to Wikidata entities. A title is only unique
within a selected C<site>. One can also prepend the site key to a title
separated by colon, e.g. C<enwiki:anarchy> for the entity that is titled
"anarchy" in the English Wikipedia. Read from input stream if no titles, nor
ids are specified.

=back

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
